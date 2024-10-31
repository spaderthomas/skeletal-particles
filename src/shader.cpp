tstring build_shader_source(const char* file_path) {
	auto shader_file = copy_string(file_path, &bump_allocator);
	auto shader_directory = resolve_named_path("shaders");
	auto error = bump_allocator.alloc<char>(256);
	
	auto preprocessed_source = stb_include_file(shader_file, nullptr, shader_directory, error);
	if (!preprocessed_source) {
		tdns_log.write("shader preprocessor error; shader = %s, err = %s", shader_file, error);
		return copy_string("YOUR_SHADER_FAILED_TO_COMPILE", &bump_allocator);
	}
	
	auto source = copy_string(preprocessed_source, &bump_allocator);
	
	free(preprocessed_source);
	
	return source;
}

void check_shader_compilation(u32 shader, const char* file_path) {
	i32 success;
	
	glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
	if (!success) {
		static constexpr u32 error_size = 512;
		auto compilation_status = bump_allocator.alloc<char>(error_size);
		
		glGetShaderInfoLog(shader, error_size, NULL, compilation_status);

		tdns_log.write("shader compile error; shader = %s, err = %s", file_path, compilation_status);
	}
}

void check_shader_linkage(u32 shader, const char* file_path) {
	i32 success;
	
	glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
	if (!success) {
		static constexpr u32 error_size = 512;
		auto compilation_status = bump_allocator.alloc<char>(error_size);
		
		glGetShaderInfoLog(shader, error_size, NULL, compilation_status);

		tdns_log.write("shader link error; shader = %s, err = %s", file_path, compilation_status);
	}
}

void Shader::init_graphics(const char* name) {
	kind = Shader::Kind::Graphics;
	strncpy(this->name, name, MAX_PATH_LEN);

	auto vertex_path = resolve_format_path_ex("vertex_shader", name, &standard_allocator);
	auto fragment_path = resolve_format_path_ex("fragment_shader", name, &standard_allocator);

	const char* paths[] = {
		vertex_path,
		fragment_path
	};

	unsigned int shader_program = glCreateProgram();
	
	fox_for(index, 2) {
		auto file_path = paths[index];
		auto source = build_shader_source(file_path);
		if (!source) return;
		
		// Compile the shader
		unsigned int shader_kind = (index == 0) ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER;
		unsigned int shader = glCreateShader(shader_kind);
		if (shader_kind == GL_VERTEX_SHADER) {
			vertex = shader;
		}
		else if (shader_kind == GL_FRAGMENT_SHADER) {
			fragment = shader;
		}

		u32 num_shaders = 1;
		glShaderSource(shader, num_shaders, &source, NULL);
		glCompileShader(shader);
		check_shader_compilation(shader, file_path);

		glAttachShader(shader_program, shader);
	}
		
	// Link into a shader program
	glLinkProgram(shader_program);
	check_shader_compilation(shader_program, vertex_path);

	// Push the data into the shader. If anything fails, the shader won't get
	// the new GL handles
	program = shader_program;
	glGetProgramiv(shader_program, GL_ACTIVE_UNIFORMS, (int*)&num_uniforms);
}

void Shader::init_compute(const char* name) {
	this->kind = Shader::Kind::Compute;
	strncpy(this->name, name, MAX_PATH_LEN);

	this->compute = glCreateShader(GL_COMPUTE_SHADER);

	this->compute_path = resolve_format_path_ex("compute_shader", name, &standard_allocator);
	auto source = build_shader_source(this->compute_path);
	
	u32 num_shaders = 1;
	glShaderSource(this->compute, num_shaders, &source, NULL);
	glCompileShader(this->compute);
	check_shader_compilation(this->compute, this->compute_path);

	this->program = glCreateProgram();
	glAttachShader(this->program, this->compute);
	glLinkProgram(this->program);
	check_shader_compilation(this->program, this->compute_path);
}

void Shader::reload() {
	//tdns_log.write("Reloading shader %s (%s)", name, kind == Shader::Kind::Graphics ? "Graphics" : "Compute");

	glDeleteProgram(program);

	if (kind == Shader::Kind::Graphics) {
		glDeleteShader(vertex);
		glDeleteShader(fragment);
		
		init_graphics(name);
	}
	else if (kind == Shader::Kind::Compute) {
		glDeleteShader(compute);
		
		init_compute(name);
	}
}

Shader* find_shader(const char* name) {
	arr_for(shaders, shader) {
		if (!strncmp(shader->name, name, MAX_PATH_LEN)) return shader;
	}

	return nullptr;
}

ShaderManager& get_shader_manager() {
	static ShaderManager manager;
	return manager;
}


Uniform::Uniform() : kind(UniformKind::I32), i32(0) {}
Uniform::Uniform(const char* name) : kind(UniformKind::I32), i32(0) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, const HMM_Mat4& m) : kind(UniformKind::Matrix4), mat4(m) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, const HMM_Mat3& m) : kind(UniformKind::Matrix3), mat3(m) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, const HMM_Vec4& v) : kind(UniformKind::Vector4), vec4(v) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, const HMM_Vec3& v) : kind(UniformKind::Vector3), vec3(v) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, const Vector2& v) : kind(UniformKind::Vector2), vec2(v) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, int32 i) : kind(UniformKind::I32), i32(i) {
	strncpy(this->name, name, max_name_len);
}
Uniform::Uniform(const char* name, float32 f) : kind(UniformKind::F32), f32(f) {
	strncpy(this->name, name, max_name_len);
}

bool are_uniforms_equal(Uniform& a, Uniform& b) {
    if (a.kind != b.kind) return false;
    if (std::strncmp(a.name, b.name, Uniform::max_name_len) != 0) return false;

    // Then, compare the union members based on `kind`
    switch (a.kind) {
        case UniformKind::Matrix4:
			return !std::memcmp(&a.mat4, &b.mat4, sizeof(HMM_Mat4));
		case UniformKind::Matrix3:
			return std::memcmp(&a.mat3, &b.mat3, sizeof(HMM_Mat3));
        case UniformKind::Vector4:
            return a.vec4 == b.vec4;
        case UniformKind::Vector3:
            return a.vec3 == b.vec3;
        case UniformKind::Vector2:
            return v2_equal(a.vec2, b.vec2);
        case UniformKind::I32:
            return a.i32 == b.i32;
        case UniformKind::F32:
            return a.f32 == b.f32;
        case UniformKind::Texture:
            return a.texture == b.texture;
        default:
            return true;
    }
}


void on_shader_change(FileMonitor* monitor, FileChange* event, void* userdata) {
	tdns_log.write("SHADER_RELOAD");
	arr_for(shaders, shader) {
		shader->reload();
	}
}

void init_shaders() {
	shader_manager.file_monitor = arr_push(&file_monitors);
	shader_manager.file_monitor->init(on_shader_change, FileChangeEvent::Modified, nullptr);
	
	auto shader_dir = resolve_named_path("shaders");
	shader_manager.file_monitor->add_directory(shader_dir);
	
	arr_init(&shaders, 32);
	
	auto add_compute_shader = [](const char* name) {
		auto shader = arr_push(&shaders);
		shader->init_compute(name);
	};

	add_compute_shader("fluid_init");
	add_compute_shader("fluid_update");
	add_compute_shader("fluid_eulerian_init");
	add_compute_shader("fluid_eulerian_update");

	auto add_graphics_shader = [](const char* name) {
		auto shader = arr_push(&shaders);
		shader->init_graphics(name);
	};

	add_graphics_shader("sdf");
	add_graphics_shader("solid");
	add_graphics_shader("sprite");
	add_graphics_shader("text");
	add_graphics_shader("post_process");
	add_graphics_shader("blit");
	add_graphics_shader("particle");
	add_graphics_shader("fluid");
	add_graphics_shader("fluid_eulerian");
	add_graphics_shader("scanline");
}
