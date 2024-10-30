#define MAX_UNIFORMS 32
#define MAX_UNIFORM_LEN 32

enum class UniformKind {
	None = 0,
	Matrix4,
	Matrix3,
	Vector4,
	Vector3,
	Vector2,
	I32,
	F32,
	Texture
};

struct Uniform {
	UniformKind kind = UniformKind::None;

	static constexpr int32 max_name_len = 64;
	char name [max_name_len];
	
	union {
		HMM_Mat4 mat4;
		HMM_Mat3 mat3;
		HMM_Vec4 vec4;
		HMM_Vec3 vec3;
		Vector2 vec2;
		int32 i32;
		float32 f32;
		int32 texture;
	};

	Uniform();
	Uniform(const char* name);
	Uniform(const char* name, const HMM_Mat4& m);
	Uniform(const char* name, const HMM_Mat3& m);
	Uniform(const char* name, const HMM_Vec4& v);
	Uniform(const char* name, const HMM_Vec3& v);
	Uniform(const char* name, const Vector2& v);
	Uniform(const char* name, int32 i);
	Uniform(const char* name, float32 f);
};
bool are_uniforms_equal(Uniform& a, Uniform& b);

struct Shader {
	enum class Kind : i32 {
		Graphics,
		Compute
	};

	Kind kind;
	char name    [MAX_PATH_LEN] = {0};
	
	u32 program = 0;
	
	string vertex_path;
	string fragment_path;
	u32 vertex = 0;
	u32 fragment = 0;

	string compute_path;
	u32 compute = 0;

	u32 num_uniforms = 0;
	
	static int active;

	void init_graphics(const char* name);
	void init_compute(const char* name);
	void reload();
	
	unsigned int get_uniform_loc(const char* name);

	void set(const Uniform& uniform);

	void begin();
	void end();

};
int Shader::active = -1;

Array<Shader> shaders;

void init_shaders();
Shader* find_shader(const char* name);
void add_shader(const char* name);
void on_shader_change(FileMonitor* monitor, FileChange* event, void* userdata);

struct ShaderManager {
	FileMonitor* file_monitor;
	FileMonitor* compute_monitor;
};
ShaderManager shader_manager;
