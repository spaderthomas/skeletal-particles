////////////////////////
// DRAWING PRIMITIVES //
////////////////////////
void draw_quad_ex(float px, float py, float sx, float sy, Vector4 color) {
	set_active_shader("solid");
	set_draw_mode(DrawMode::Triangles);
		
	Vector2 vxs [6] = fm_quad(py, py - sy, px, px + sx);
	for (int32 i = 0; i < 6; i++) {
		push_vertex(vxs[i].x, vxs[i].y, color);
	}
}

void draw_quad(Vector2 position, Vector2 size, Vector4 color) {
	draw_quad_ex(position.x, position.y, size.x, size.y, color);
}

void draw_circle(float32 px, float32 py, float32 radius, Vector4 color) {
	set_active_shader("solid");
	set_draw_mode(DrawMode::Triangles);
	// GL_TRIANGLE_FAN means we can't batch draw calls; GL_TRIANGLE_STRIP would force me to figure out another algorithm
	// for tesselating the circle, and I'm lazy, but it lets you batch with degenerate triangles.
	
	float32 x = 0;
	float32 y = 0;
	uint32 segments = 5 * sqrt(radius);
	float32 theta = 2 * 3.14159 / segments;
	float32 c = cos(theta);
	float32 s = sin(theta);
	
	y = radius;
	for (uint32 i = 0; i < segments; i++) {
		push_vertex(px, py, color);
		push_vertex(px + x, py + y, color);

		auto tx = x;
		auto ty = y;
		x = c * tx - s * ty;
		y = c * ty + s * tx;
		push_vertex(px + x, py + y, color);
	}
}

void draw_circle_sdf(float32 px, float32 py, float32 radius, Vector4 color, float edge_thickness) {
	render.flush_draw_call();

	set_active_shader("sdf");
	set_draw_mode(DrawMode::Triangles);
	
	set_uniform_vec2("point", { px, py });
	set_uniform_f32("edge_thickness", edge_thickness);
	set_uniform_i32("shape", static_cast<i32>(Sdf::Circle));
	set_uniform_f32("radius", radius);
	
	push_quad(px - radius, py + radius, 2 * radius, 2 * radius, nullptr, color);
}

void draw_ring_sdf(float32 px, float32 py, float inner_radius, float radius, Vector4 color, float edge_thickness) {
	render.flush_draw_call();

	set_active_shader("sdf");
	set_draw_mode(DrawMode::Triangles);
	
	set_uniform_vec2("point", { px, py });
	set_uniform_f32("edge_thickness", edge_thickness);
	set_uniform_i32("shape", static_cast<i32>(Sdf::Ring));
	set_uniform_f32("radius", radius);
	set_uniform_f32("inner_radius", inner_radius);
	
	push_quad(px - radius, py + radius, 2 * radius, 2 * radius, nullptr, color);
}

	
void draw_image(const char* name, float px, float py) {
	auto sprite = find_sprite(name);
	auto texture = find_texture(sprite->texture);
	draw_image_pro(texture->handle, px, py, sprite->size.x, sprite->size.y, sprite->uv, 1.f);
}

void draw_image_size(const char* name, float px, float py, float dx, float dy) {
	auto sprite = find_sprite(name);
	auto texture = find_texture(sprite->texture);
	draw_image_pro(texture->handle, px, py, dx, dy, sprite->uv, 1.f);
}

void draw_image_ex(const char* name, float px, float py, float dx, float dy, float opacity) {
	auto sprite = find_sprite(name);
	auto texture = find_texture(sprite->texture);
	draw_image_pro(texture->handle, px, py, dx, dy, sprite->uv, opacity);
}


void draw_image(Sprite* sprite, float px, float py) {
	if (!sprite) return;
	auto texture = find_texture(sprite->texture);
	draw_image_pro(texture->handle, px, py, sprite->size.x, sprite->size.y, sprite->uv, 1.f);
}

void draw_image(Sprite* sprite, float px, float py, float dx, float dy) {
	if (!sprite) return;
	auto texture = find_texture(sprite->texture);
	draw_image_pro(texture->handle, px, py, dx, dy, sprite->uv, 1.f);
}

void draw_image(Sprite* sprite, float px, float py, float dx, float dy, float opacity) {
	if (!sprite) return;
	auto texture = find_texture(sprite->texture);
	draw_image_pro(texture->handle, px, py, dx, dy, sprite->uv, opacity);
}

void draw_image_pro(u32 texture, float px, float py, float dx, float dy, Vector2* uv, float opacity) {
	set_active_shader("sprite");
	set_draw_mode(DrawMode::Triangles);
	set_uniform_texture("sampler", texture);

	push_quad(px, py, dx, dy, uv, opacity);
}


void draw_text_ex(const char* text, float px, float py, Vector4 color, const char* font, float wrap, bool precise) {
	auto prepared_text = prepare_text_ex(text, px, py, font, wrap, color, precise);
	draw_prepared_text(prepared_text);
}

void draw_text(const char* text, float px, float py, const char* font) {
	auto prepared_text = prepare_text_ex(text, px, py, font, 0, colors::white, true);
	draw_prepared_text(prepared_text);
}

void draw_prepared_text(PreparedText* prepared_text) {
	if (!prepared_text) return;
	if (prepared_text->is_empty()) return;
	
	set_active_shader("text");
	set_uniform_texture("sampler", prepared_text->font->texture);
	set_draw_mode(DrawMode::Triangles);

	float baseline_offset = prepared_text->baseline_offset;
	if (!prepared_text->precise) baseline_offset = prepared_text->baseline_offset_imprecise;

	i32 line = 0;
	Vector2 point = {
		prepared_text->position.x,
		prepared_text->position.y - baseline_offset,
	};
		
	auto is_finished = [&]() {
		return line == prepared_text->count_breaks() - 1;
	};

	while (!is_finished()) {
		auto line_text = prepared_text->get_line(line);
		arr_for(line_text, pc) {
			char c = *pc;
			if (!c) break;

			// Render this character
			auto glyph = prepared_text->font->glyphs[c];

			// We've already got the vertices from the glyph. Add the base position.
			//
			// 2023/12/27: For some reason, non-integral positions don't play nice. I guess this makes sense,
			// because a glyph's texture is pixel perfect, and depending on which way the rounding goes it could
			// omit that last row or column of pixels. I can't quite math it out exactly, but it seems totally
			// reasonable that that's the case. To get around this, I just round to the nearest integer.
			for (i32 i = 0; i < 6; i++) {
				auto vertex = push_vertex(
					floorf(point.x + glyph->verts[i].x), floorf(point.y + glyph->verts[i].y), 
					glyph->uv[i], 
					prepared_text->color
				);
			}

			// Advance one character
			point.x += glyph->advance.x;
		}

		// Advance one line
		point.x = prepared_text->position.x;
		point.y -= prepared_text->font->max_advance.y;
		line++;
	}
}

void draw_line(Vector2 start, Vector2 end, float thickness, Vector4 color) {
	set_active_shader("solid");
	set_draw_mode(DrawMode::Triangles);

	auto line = v2_subtract(end, start);
	auto length = v2_length(line);
	auto normal = Vector2(-1 * line.y, line.x);

	auto scale = thickness / (length * 2);
	auto radius = Vector2(normal.x * scale, normal.y  * scale);

	push_vertex(start.x - radius.x, start.y - radius.y, color);
	push_vertex(start.x + radius.x, start.y + radius.y, color);
	push_vertex(end.x   - radius.x, end.y   - radius.y, color);
	
	push_vertex(start.x + radius.x, start.y + radius.y, color);
	push_vertex(end.x   + radius.x, end.y   + radius.y, color);
	push_vertex(end.x   - radius.x, end.y   - radius.y, color);
}


//////////////////////////
// OPENGL CONFIGURATION //
//////////////////////////
void set_draw_mode(DrawMode mode) {
	auto draw_call = render.find_draw_call();
	if (draw_call->mode == mode) return;
	
	draw_call = render.flush_draw_call();
	draw_call->mode = mode;
}

void set_blend_enabled(bool enabled) {
	auto draw_call = render.find_draw_call();
	if (draw_call->state.blend_enabled != enabled) return;
	
	draw_call = render.flush_draw_call();
	draw_call->state.blend_enabled = enabled;
}

void set_blend_mode(i32 source, i32 dest) {
	auto blend_source = convert_blend_mode(static_cast<BlendMode>(source));
	auto blend_dest = convert_blend_mode(static_cast<BlendMode>(dest));
	auto draw_call = render.find_draw_call();
	if ((draw_call->state.blend_source == blend_source) && (draw_call->state.blend_dest == blend_dest)) return;
	
	draw_call = render.flush_draw_call();
	draw_call->state.blend_source = blend_source;
	draw_call->state.blend_dest = blend_dest;
}


void set_active_shader(const char* name) {
	auto shader = find_shader(name);
	if (!shader) return;
	
	auto draw_call = render.find_draw_call();
	if (draw_call->state.shader == shader) return;
		
	draw_call = render.flush_draw_call();
	draw_call->state.shader = shader;

}
	
void set_orthographic_projection(float left, float right, float bottom, float top, float _near, float _far) {
	render.projection = HMM_Orthographic_RH_NO(left, right, bottom, top, _near, _far);
}

void begin_scissor(float px, float py, float dx, float dy) {
	auto draw_call = render.flush_draw_call();
	draw_call->state.scissor = true;
	draw_call->state.scissor_region.position = Vector2(px, py);
	draw_call->state.scissor_region.dimension = Vector2(dx, dy);
}

void end_scissor() {
	auto draw_call = render.flush_draw_call();
	draw_call->state.scissor = false;
}

void set_layer(i32 layer) {
	auto draw_call = render.flush_draw_call();
	draw_call->state.layer = layer;
}

void set_camera(float px, float py) {
	render.camera = Vector2(px, py);
}

void set_uniform(Uniform& uniform) {
	auto draw_call = render.find_draw_call();
	bool had_uniform = draw_call->state.has_uniform(uniform.name);
	auto previous_uniform = draw_call->state.find_uniform(uniform.name);
	bool uniform_changed = (previous_uniform) && !are_uniforms_equal(uniform, *previous_uniform);

	// CASE 1: The uniform was already set to a different value, so we need a new draw call
	if (had_uniform && uniform_changed) {
		draw_call = render.flush_draw_call();
		draw_call->state.add_uniform(uniform);
		return;
	}
	// CASE 2: The uniform was never set, so we don't need a new draw call, but we DO need to add the uniform
	else if (!had_uniform) {
		draw_call = render.find_draw_call();
		draw_call->state.add_uniform(uniform);
		return;
	}
	// CASE 3: The uniform was already set, but to the same thing, so do nothing.
}

void set_uniform_mat4(const char* name, HMM_Mat4 value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_mat3(const char* name, HMM_Mat3 value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_vec4(const char* name, HMM_Vec4 value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_vec3(const char* name, HMM_Vec3 value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_vec2(const char* name, Vector2 value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_i32(const char* name, i32 value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_f32(const char* name, float value) {
	auto uniform = Uniform(name, value);
	set_uniform(uniform);
}

void set_uniform_texture(const char* name, i32 value) {
	auto uniform = Uniform(name);
	uniform.kind = UniformKind::Texture;
	uniform.texture = value;
	set_uniform(uniform);
}


///////////////////////
// IMMEDIATE DRAWING //
///////////////////////
i32 find_uniform_index(const char* name) {
	i32 program = 0;
	glGetIntegerv(GL_CURRENT_PROGRAM, &program);
	return glGetUniformLocation(program, name);
}

void set_shader_immediate(Shader* shader) {
	if (!shader) return;
	
	glUseProgram(shader->program);
	set_uniform_immediate_f32("master_time", engine.elapsed_time);
	set_uniform_immediate_vec2("camera", render.camera);
}

void set_shader_immediate(const char* name) {
	auto shader = find_shader(name);
	set_shader_immediate(shader);
}

void set_uniform_immediate(const Uniform& uniform) {
	if (uniform.kind == UniformKind::Matrix4) {
		set_uniform_immediate_mat4(uniform.name, uniform.mat4);
	}
	else if (uniform.kind == UniformKind::Matrix3) {
		set_uniform_immediate_mat3(uniform.name, uniform.mat3);
	}
	else if (uniform.kind == UniformKind::Vector4) {
		set_uniform_immediate_vec4(uniform.name, uniform.vec4);
	}
	else if (uniform.kind == UniformKind::Vector3) {
		set_uniform_immediate_vec3(uniform.name, uniform.vec3);
	}
	else if (uniform.kind == UniformKind::Vector2) {
		set_uniform_immediate_vec2(uniform.name, uniform.vec2);
	}
	else if (uniform.kind == UniformKind::I32) { 
		set_uniform_immediate_i32(uniform.name, uniform.i32);
	}
	else if (uniform.kind == UniformKind::F32) {
		set_uniform_immediate_f32(uniform.name, uniform.f32);
	}
	else if (uniform.kind == UniformKind::Texture) {
		set_uniform_immediate_i32(uniform.name, uniform.texture);
	}
}

void set_uniform_immediate_vec4(const char* name, HMM_Vec4 vec) {
	i32 index = find_uniform_index(name);
	glUniform4f(index, vec.X, vec.Y, vec.Z, vec.W);
}

void set_uniform_immediate_vec3(const char* name, HMM_Vec3 vec) {
	i32 index = find_uniform_index(name);
	glUniform3f(index, vec.X, vec.Y, vec.Z);
}

void set_uniform_immediate_vec2(const char* name, Vector2 vec) {
	i32 index = find_uniform_index(name);
	glUniform2f(index, vec.x, vec.y);
}

void set_uniform_immediate_mat3(const char* name, HMM_Mat3 matrix) {
	i32 index = find_uniform_index(name);
	glUniformMatrix3fv(index, 1, GL_FALSE, (const float*)&matrix);
}

void set_uniform_immediate_mat4(const char* name, HMM_Mat4 matrix) {
	i32 index = find_uniform_index(name);
	glUniformMatrix4fv(index, 1, GL_FALSE, (const float*)&matrix);
}

void set_uniform_immediate_i32(const char* name, i32 val) {
	i32 index = find_uniform_index(name);
	glUniform1i(index, val);
}

void set_uniform_immediate_f32(const char* name, float val) {
	i32 index = find_uniform_index(name);
	glUniform1f(index, val);
}

void set_uniform_immediate_texture(const char* name, i32 val) {
	set_uniform_immediate_i32(name, val);
}

void set_world_space(bool world_space) {
	auto draw_call = render.find_draw_call();
	if (draw_call->state.world_space == world_space) return;
	
	draw_call = render.flush_draw_call();
	draw_call->state.world_space = world_space;
}

void set_gl_name(u32 kind, u32 handle, u32 name_len, const char* name) {
	glObjectLabel(convert_gl_id(static_cast<GlId>(kind)), handle, name_len, name);
}

///////////////////
// OPENGL ERRORS //
///////////////////
void clear_gl_error() {
	while (glGetError() != GL_NO_ERROR) {}
	
	// while (true) {
	// 	auto error = read_gl_error();
	// 	if (!error) break;
	// 	if (!strcmp(error, "GL_NO_ERROR")) break;
	// }
}

tstring read_gl_error() {
	auto error = glGetError();
	if (error == GL_INVALID_ENUM) {
		return copy_string("GL_INVALID_ENUM", &bump_allocator);
	}
	else if (error == GL_INVALID_OPERATION) {
		return copy_string("GL_INVALID_OPERATION", &bump_allocator);
	}
	else if (error == GL_OUT_OF_MEMORY) {
		return copy_string("GL_OUT_OF_MEMORY", &bump_allocator);
	}
	else if (error == GL_NO_ERROR) {
		return copy_string("GL_NO_ERROR", &bump_allocator);
	}

	return nullptr;
}

void log_gl_error() {
	tdns_log.write(read_gl_error());
}



///////////////////
// RENDER TARGET //
///////////////////
GpuRenderTarget* gpu_create_target(float x, float y) {
	auto target = arr_push(&render.targets);
	target->size = Vector2(x, y);
	
	glGenFramebuffers(1, &target->handle);
	glBindFramebuffer(GL_FRAMEBUFFER, target->handle);

	// Generate the color buffer, allocate GPU memory for it, and attach it to the framebuffer
	glGenTextures(1, &target->color_buffer);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, target->color_buffer);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, x, y, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, target->color_buffer, 0);

	// Clean up
	glBindRenderbuffer(GL_RENDERBUFFER, 0);
	glBindTexture(GL_TEXTURE_2D, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	return target;
}

void gpu_destroy_target(GpuRenderTarget* target) {
	glDeleteTextures(1, &target->color_buffer);
	glDeleteFramebuffers(1, &target->handle);
}

void gpu_bind_target(GpuRenderTarget* target) {
	if (!target) return;
	
	glBindFramebuffer(GL_FRAMEBUFFER, target->handle);
	glViewport(0, 0, target->size.x, target->size.y);
	set_orthographic_projection(0, target->size.x, 0, target->size.y, -100.f, 100.f);
}

GpuRenderTarget* gpu_acquire_swapchain() {
	return render.targets[0];
}

void gpu_clear_target(GpuRenderTarget* target) {
	if (!target) return;
	
	gpu_bind_target(target);
	glClearColor(0.f, 0.f, 0.f, 1.f);
	glClear(GL_COLOR_BUFFER_BIT);
}

void gpu_blit_target(GpuCommandBuffer* command_buffer, GpuRenderTarget* source, GpuRenderTarget* destination) {
	glBindFramebuffer(GL_READ_FRAMEBUFFER, source->handle);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER, destination->handle);
	glBlitFramebuffer(0, 0, source->size.x, source->size.y, 0, 0, destination->size.x, destination->size.y,  GL_COLOR_BUFFER_BIT, GL_NEAREST);
	glMemoryBarrier(GL_FRAMEBUFFER_BARRIER_BIT);
}

void gpu_swap_buffers() {
	glfwSwapBuffers(window.handle);
}


////////////////////
// COMMAND BUFFER //
////////////////////
GpuCommandBuffer* gpu_create_command_buffer(GpuCommandBufferDescriptor descriptor) {
	auto buffer = arr_push(&render.command_buffers);
	
	arr_init(&buffer->vertex_buffer, descriptor.max_vertices);
	arr_init(&buffer->draw_calls, descriptor.max_draw_calls);
	//render.command_buffer = buffer;
	//render.add_draw_call();
	//arr_push(&buffer->draw_calls);
	
	glGenVertexArrays(1, &buffer->vao);
	glGenBuffers(1, &buffer->vbo);

	glBindVertexArray(buffer->vao);
	glBindBuffer(GL_ARRAY_BUFFER, buffer->vbo);

	u32 stride = sizeof(Vertex);
	u64 offset = 0;
	for (u32 i = 0; i < descriptor.num_vertex_attributes; i++) {
		auto attribute = descriptor.vertex_attributes[i];
		auto type_info = GlTypeInfo::from_attribute(attribute.kind);
		
		glVertexAttribPointer(i, attribute.count, type_info.value, GL_FALSE, stride, (void*)offset);
		glEnableVertexAttribArray(i);
		offset += attribute.count * type_info.size;
	}

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	return buffer;
}

void gpu_bind_commands(GpuCommandBuffer* command_buffer) {
	glBindVertexArray(command_buffer->vao);
	glBindBuffer(GL_ARRAY_BUFFER, command_buffer->vbo);
	glBufferData(GL_ARRAY_BUFFER, arr_bytes_used(&command_buffer->vertex_buffer), command_buffer->vertex_buffer.data, GL_STREAM_DRAW);
}

void gpu_preprocess_commands(GpuCommandBuffer* command_buffer) {
	arr_for(command_buffer->draw_calls, draw_call) {
		if (!draw_call->count) continue;
		
		for (int i = 0; i < draw_call->count; i++) {
			auto vertex =  command_buffer->vertex_buffer[draw_call->offset + i];
			draw_call->average_y += vertex->position.y;
		}

		draw_call->average_y /= draw_call->count;
	}

	qsort(command_buffer->draw_calls.data, command_buffer->draw_calls.size, sizeof(DrawCall), &DrawCall::compare);
}

void gpu_draw_commands(GpuCommandBuffer* command_buffer) {
	GlStateDiff state_diff;
	arr_for(command_buffer->draw_calls, draw_call) {
		if (!draw_call->count) continue;
			
		state_diff.apply(&draw_call->state);
		auto mode = convert_draw_mode(draw_call->mode);
		glDrawArrays(mode, draw_call->offset, draw_call->count);
	}
		
	arr_clear(&command_buffer->draw_calls);
	arr_clear(&command_buffer->vertex_buffer);
}


/////////////////
// RENDER PASS //
/////////////////
GpuRenderPass* gpu_create_pass(GpuRenderPassDescriptor descriptor) {
	auto render_pass = arr_push(&render.render_passes);
	render_pass->render_target = descriptor.target;
	render_pass->ping_pong = descriptor.ping_pong;
	render_pass->clear_render_target = descriptor.clear_render_target;

	return render_pass;
}

void gpu_begin_pass(GpuRenderPass* render_pass, GpuCommandBuffer* command_buffer) {
	render.render_pass = render_pass;
	render.command_buffer = command_buffer;

	if (!render_pass->dirty) {
		if (render_pass->clear_render_target) {
			gpu_clear_target(render_pass->render_target);
		}
	}
	render_pass->dirty = true;
}

void gpu_end_pass() {
	render.render_pass = nullptr;
	render.command_buffer = nullptr;
}

void gpu_submit_commands(GpuCommandBuffer* command_buffer) {
	gpu_bind_commands(command_buffer);
	gpu_preprocess_commands(command_buffer);
	gpu_draw_commands(command_buffer);	
}


// BUFFERS
GpuBuffer* gpu_create_buffer() {
	auto buffer = arr_push(&render.gpu_buffers);
	glGenBuffers(1, &buffer->handle);

	return buffer;
}

void gpu_memory_barrier(GpuMemoryBarrier barrier) {
	glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
}

void gpu_bind_buffer(GpuBuffer* buffer) {
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer->handle);
}

void gpu_bind_buffer_base(GpuBuffer* buffer, u32 base) {
	glBindBufferBase(GL_SHADER_STORAGE_BUFFER, base, buffer->handle);
}

void gpu_sync_buffer(GpuBuffer* buffer, void* data, u32 size) {
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer->handle);
	glBufferData(GL_SHADER_STORAGE_BUFFER, size, data, GL_STATIC_DRAW);
	glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
}

void gpu_zero_buffer(GpuBuffer* buffer, u32 size) {
	auto data = bump_allocator.alloc<u8>(size);
	gpu_sync_buffer(buffer, data, size);
}

void gpu_dispatch_compute(GpuBuffer* buffer, u32 size) {

}


////////////////////////
// RENDERER INTERNALS //
////////////////////////
void init_render() {
	render.screenshot = standard_allocator.alloc<u8>(window.native_resolution.x * window.native_resolution.y * 4);

	arr_init(&render.command_buffers, RenderEngine::max_command_buffers);
	arr_init(&render.render_passes, RenderEngine::max_render_passes);
	arr_init(&render.targets, RenderEngine::max_targets);
	arr_init(&render.gpu_buffers, RenderEngine::max_gpu_buffers);

	auto swapchain = arr_push(&render.targets);
	swapchain->handle = 0;
	swapchain->color_buffer = 0;
	swapchain->size = window.content_area;
}

// RENDERER
DrawCall* RenderEngine::add_draw_call() {
	if (!command_buffer) return nullptr;
	if (!render_pass) return nullptr;
	
	DrawCall draw_call;
	memset(&draw_call, 0, sizeof(DrawCall));
	draw_call.offset = command_buffer->vertex_buffer.size;
	draw_call.count = 0;

	if (command_buffer->draw_calls.size) {
		auto previous = find_draw_call();
		draw_call.copy_from(previous);
	}
	else {
		draw_call.state = GlState();
	}
	
	draw_call.state.render_target = render_pass->render_target;

	return arr_push(&command_buffer->draw_calls, draw_call);
}
	
DrawCall* RenderEngine::flush_draw_call() {
	auto draw_call = find_draw_call();
	if (!draw_call->count) return draw_call;
	if (!draw_call->state.shader) return draw_call;
	
	return add_draw_call();
}

DrawCall* RenderEngine::find_draw_call() {
	if (!command_buffer) return nullptr;

	if (!command_buffer->draw_calls.size) add_draw_call();
	return arr_back(&command_buffer->draw_calls);
}

void DrawCall::copy_from(DrawCall* other) {
	this->mode = other->mode;
	this->state = other->state;
	this->state.uniforms.clear();
}

int DrawCall::compare(const void* a, const void* b) {
	auto da = (DrawCall*)a;
	auto db = (DrawCall*)b;

	// If A is in a lower layer than B, A is drawn first, and we return a positive integer, & vice v.
	if (da->state.layer > db->state.layer) return 1;
	if (da->state.layer < db->state.layer) return -1;

	if (da->average_y > db->average_y) return -1;
	if (da->average_y < db->average_y) return 1;

	// Otherwise, use the offset as a proxy for the order submitted to keep the sort stable.
	return da->offset > db->offset ? -1 : 1;
}

void GlStateDiff::apply(GlState* state) {
	if (is_first_draw_call()) {
		this->camera = HMM_Translate(HMM_V3(-render.camera.x, -render.camera.y, 0.f));
		this->no_camera = HMM_M4D(1.0);
	}

	if (need_apply_scissor(state)) {
		if (state->scissor) {
			glEnable(GL_SCISSOR_TEST);

			auto& p = state->scissor_region.position;
			auto& d = state->scissor_region.dimension;
			glScissor(p.x, p.y, d.x, d.y);
		}
		else {
			glDisable(GL_SCISSOR_TEST);
		}
	}

	// Shader
	set_shader_immediate(state->shader);

	if (state->world_space) {
		set_uniform_immediate_mat4("view", this->camera);
	}
	else {
		set_uniform_immediate_mat4("view", this->no_camera);
	}

	int num_textures = 0;
	for (auto& uniform : state->uniforms) {
		if (uniform.kind == UniformKind::Texture) {
			glActiveTexture(GL_TEXTURE0 + num_textures);
			glBindTexture(GL_TEXTURE_2D, uniform.texture);
			uniform.texture = num_textures;
			num_textures++;
		}

		set_uniform_immediate(uniform);
	}

	if (state->blend_enabled) {
		glEnable(GL_BLEND);
		glBlendFunc(state->blend_source, state->blend_dest);
	}
	else {
		glDisable(GL_BLEND);
	}

	if (!current || current->render_target != state->render_target) {
		gpu_bind_target(state->render_target);
	}
	set_uniform_immediate_mat4("projection", render.projection);
	set_uniform_immediate_vec2("output_resolution", state->render_target->size);
	set_uniform_immediate_vec2("native_resolution", window.native_resolution);


	this->current = state;

}

bool GlStateDiff::is_first_draw_call() {
	return current == nullptr;
}

bool GlStateDiff::need_apply_scissor(GlState* state) {
	if (is_first_draw_call()) return true;
	if (current->scissor != state->scissor) return true;
	if (!v2_equal(current->scissor_region.position,  state->scissor_region.position)) return true;
	if (!v2_equal(current->scissor_region.dimension, state->scissor_region.dimension)) return true;

	return false;
}


//////////////////////////////
// VERTEX BUFFER PRIMITIVES //
//////////////////////////////
Vertex* push_vertex(float px, float py) {
	return push_vertex(px, py, Vector2(), colors::white);
}

Vertex* push_vertex(float px, float py, Vector4 color) {
	return push_vertex(px, py, Vector2(), color);
}

Vertex* push_vertex(float px, float py, Vector2 uv, Vector4 color) {
	auto vertex = push_vertex();
	vertex->position.x = px;
	vertex->position.y = py;
	vertex->uv = uv;
	vertex->color = color;

	return vertex;
}

Vertex* push_vertex() {
	return push_vertex(1);
}

Vertex* push_vertex(i32 count) {
	auto command_buffer = render.command_buffer;
	
	auto draw_call = render.find_draw_call();
	draw_call->count += count;

	return arr_reserve(&command_buffer->vertex_buffer, count);
}

void push_quad(float px, float py, float dx, float dy, Vector2* uv, float opacity) {
	auto color = colors::white;
	color.a = opacity;

	push_quad(px, py, dx, dy, uv, color);
}

void push_quad(float px, float py, float dx, float dy, Vector2* uv, Vector4 color) {
	static Vector2 default_uvs [6] = fm_quad(1, 0, 0, 1);
	if (!uv) uv = default_uvs;

	Vector2 vx [6] = fm_quad(py, py - dy, px, px + dx);
	for (i32 i = 0; i < 6; i++) {
		auto vertex = push_vertex();
		vertex->position.x = vx[i].x;
		vertex->position.y = vx[i].y;
		vertex->color = color;
		vertex->uv = uv[i];
	}
}


//////////////
// GL STATE //
//////////////
void GlState::setup() {
	if (this->scissor) {
		glEnable(GL_SCISSOR_TEST);

		auto& p = scissor_region.position;
		auto& d = scissor_region.dimension;
		glScissor(p.x, p.y, d.x, d.y);
	}
	else {
		glDisable(GL_SCISSOR_TEST);
	}
}

void GlState::restore() {
	if (this->scissor) {
		glDisable(GL_SCISSOR_TEST);
	}
}

Uniform* GlState::find_uniform(const char* name) {
	for (auto& uniform : uniforms) {
		if (!strncmp(uniform.name, name, Uniform::max_name_len)) return &uniform;
	}

	return nullptr;
}

bool GlState::has_uniform(const char* name) {
	return find_uniform(name) != nullptr;
}

void GlState::add_uniform(Uniform& uniform) {
	uniforms.push(uniform);
}

i32 convert_blend_mode(BlendMode blend_mode) {
	if (blend_mode == BlendMode::ZERO) {
		return GL_ZERO;
	}
	else if (blend_mode == BlendMode::ONE) {
		return GL_ONE;
	}
	else if (blend_mode == BlendMode::SRC_COLOR) {
		return GL_SRC_COLOR;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_SRC_COLOR) {
		return GL_ONE_MINUS_SRC_COLOR;
	}
	else if (blend_mode == BlendMode::DST_COLOR) {
		return GL_DST_COLOR;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_DST_COLOR) {
		return GL_ONE_MINUS_DST_COLOR;
	}
	else if (blend_mode == BlendMode::SRC_ALPHA) {
		return GL_SRC_ALPHA;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_SRC_ALPHA) {
		return GL_ONE_MINUS_SRC_ALPHA;
	}
	else if (blend_mode == BlendMode::DST_ALPHA) {
		return GL_DST_ALPHA;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_DST_ALPHA) {
		return GL_ONE_MINUS_DST_ALPHA;
	}
	else if (blend_mode == BlendMode::CONSTANT_COLOR) {
		return GL_CONSTANT_COLOR;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_CONSTANT_COLOR) {
		return GL_ONE_MINUS_CONSTANT_COLOR;
	}
	else if (blend_mode == BlendMode::CONSTANT_ALPHA) {
		return GL_CONSTANT_ALPHA;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_CONSTANT_ALPHA) {
		return GL_ONE_MINUS_CONSTANT_ALPHA;
	}
	else if (blend_mode == BlendMode::SRC_ALPHA_SATURATE) {
		return GL_SRC_ALPHA_SATURATE;
	}
	else if (blend_mode == BlendMode::SRC1_COLOR) {
		return GL_SRC1_COLOR;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_SRC1_COLOR) {
		return GL_ONE_MINUS_SRC1_COLOR;
	}
	else if (blend_mode == BlendMode::SRC1_ALPHA) {
		return GL_SRC1_ALPHA;
	}
	else if (blend_mode == BlendMode::ONE_MINUS_SRC1_ALPHA) {
		return GL_ONE_MINUS_SRC1_ALPHA;
	}

	assert(false);
	return GL_SRC_ALPHA;
};

u32 convert_draw_mode(DrawMode mode) {
	if (mode == DrawMode::Triangles) {
		return GL_TRIANGLES;
	}

	return GL_TRIANGLES;
}

u32 convert_gl_id(GlId id) {
	if (id == GlId::Framebuffer) {
		return GL_FRAMEBUFFER;
	}
	else if (id == GlId::Shader) {
		return GL_SHADER;
	}
	else if (id == GlId::Program) {
		return GL_PROGRAM;
	}


	return GL_BUFFER;
}
