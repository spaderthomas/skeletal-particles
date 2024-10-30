///////////
// ENUMS //
///////////
enum class FillMode {
	Fill,
	Outline
};

enum class BlendMode : i32 {
	ZERO,
	ONE,
	SRC_COLOR,
	ONE_MINUS_SRC_COLOR,
	DST_COLOR,
	ONE_MINUS_DST_COLOR,
	SRC_ALPHA,
	ONE_MINUS_SRC_ALPHA,
	DST_ALPHA,
	ONE_MINUS_DST_ALPHA,
	CONSTANT_COLOR,
	ONE_MINUS_CONSTANT_COLOR,
	CONSTANT_ALPHA,
	ONE_MINUS_CONSTANT_ALPHA,
	SRC_ALPHA_SATURATE,
	SRC1_COLOR,
	ONE_MINUS_SRC1_COLOR,
	SRC1_ALPHA,
	ONE_MINUS_SRC1_ALPHA
};
i32 convert_blend_mode(BlendMode mode);

enum class DrawMode : u32 {
	Triangles,
};
u32 convert_draw_mode(DrawMode mode);

enum class VertexAttributeKind : u32 {
	Float,
};

struct GlTypeInfo {
	u32 size;
	u32 value;

	static GlTypeInfo from_attribute(VertexAttributeKind kind) {
		GlTypeInfo info;

		if (kind  == VertexAttributeKind::Float) {
			info.value = GL_FLOAT;
			info.size = sizeof(GLfloat);
		}

		return info;
	}
};

enum class Sdf : i32 {
	Circle = 0,
	Ring = 1,
};


// DRAW CALLS
struct Vertex {
	Vector3 position;
	Vector4 color;
	Vector2 uv;
};
 
struct GpuRenderTarget;
struct GlState {
	bool scissor = false;
	Rect scissor_region = {};
	Shader* shader = nullptr;
	int32 layer = 0;
	bool world_space = false;
	bool blend_enabled = true;
	i32 blend_source = GL_SRC_ALPHA;
	i32 blend_dest = GL_ONE_MINUS_SRC_ALPHA;
	GpuRenderTarget* render_target = nullptr;
	
	StackArray<Uniform, 32> uniforms;

	void setup();
	void restore();
	void clear_uniforms();
	bool has_uniform(const char* name);
	void add_uniform(Uniform& uniform);
	Uniform* find_uniform(const char* name);
};

struct GlStateDiff {
	HMM_Mat4 camera;
	HMM_Mat4 no_camera;
	GlState* current = nullptr;

	void apply(GlState* state);
	bool is_first_draw_call();
	bool need_apply_scissor(GlState* state);
};

struct DrawCall {
	DrawMode mode;
	i32 count;
	i32 offset;
	
	f32 average_y = 0;
		
	GlState state;

	void copy_from(DrawCall* other);
	static int compare(const void* a, const void* b);
};


/////////
// GPU //
/////////
struct GpuRenderTarget {
	u32 handle;
	u32 color_buffer;
	Vector2 size;
};

struct VertexAttribute {
	u32 count;
	VertexAttributeKind kind;
};

struct GpuCommandBufferDescriptor {
	VertexAttribute* vertex_attributes;
	u32 num_vertex_attributes = 0;
	u32 max_vertices = 256 * 1024;
	u32 max_draw_calls = 1024;
};

struct GpuCommandBuffer {
	Array<Vertex> vertex_buffer; // How to not hardcode this to Vertex
	Array<DrawCall> draw_calls;

	u32 vao;
	u32 vbo;
};


struct GpuRenderPassDescriptor {
	GpuRenderTarget* target = nullptr;
	GpuRenderTarget* ping_pong = nullptr;
	
	bool clear_render_target = true;
};

struct GpuRenderPass {
	GpuRenderTarget* render_target = nullptr;
	GpuRenderTarget* ping_pong = nullptr;

	bool clear_render_target = false;
	bool dirty = false;
};

/*
enum class GpuMemoryBarrier : u32 {
	ShaderStorage,
};

struct GpuBuffer {
	u32 handle;
	u32 kind;
};

GpuBuffer* gpu_create_buffer();
GpuBuffer* gpu_memory_barrier(GpuMemoryBarrier barrier);
void gpu_bind_buffer(GpuBuffer* buffer);
void gpu_bind_buffer_base(GpuBuffer* buffer, u32 base);
void gpu_sync_buffer(GpuBuffer* buffer, void* data, u32 size);
void gpu_zero_buffer(GpuBuffer* buffer, u32 size);
void gpu_dispatch_compute(GpuBuffer* buffer, u32 size);
*/

struct RenderEngine {
	HMM_Mat4 projection;
	Vector2 camera;

	u8* screenshot;

	static constexpr u32 max_command_buffers = 32;
	Array<GpuCommandBuffer> command_buffers;
	GpuCommandBuffer* command_buffer;

	static constexpr u32 max_render_passes = 32;
	Array<GpuRenderPass> render_passes;
	GpuRenderPass* render_pass;

	static constexpr u32 max_targets = 32;
	Array<GpuRenderTarget> targets;

	DrawCall* find_draw_call();
	DrawCall* add_draw_call();
	DrawCall* flush_draw_call();
};
RenderEngine render;


/////////
// GPU //
/////////
FM_LUA_EXPORT GpuRenderTarget* gpu_create_target(float x, float y);
FM_LUA_EXPORT GpuRenderTarget* gpu_acquire_swapchain();
FM_LUA_EXPORT void gpu_bind_target(GpuRenderTarget* target);
FM_LUA_EXPORT void gpu_clear_target(GpuRenderTarget* target);
FM_LUA_EXPORT void gpu_blit_target(GpuCommandBuffer* command_buffer, GpuRenderTarget* source, GpuRenderTarget* destination);
FM_LUA_EXPORT void gpu_swap_buffers();

FM_LUA_EXPORT GpuCommandBuffer* gpu_create_command_buffer(GpuCommandBufferDescriptor descriptor);
void gpu_bind_commands(GpuCommandBuffer* command_buffer);
void gpu_preprocess_commands(GpuCommandBuffer* command_buffer);
void gpu_draw_commands(GpuCommandBuffer* command_buffer);

FM_LUA_EXPORT GpuRenderPass* gpu_create_pass(GpuRenderPassDescriptor descriptor);
FM_LUA_EXPORT void gpu_begin_pass(GpuRenderPass* render_pass, GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void gpu_end_pass();
FM_LUA_EXPORT void gpu_submit_commands(GpuCommandBuffer* command_buffer);


////////////////////////
// DRAWING PRIMITIVES //
////////////////////////
FM_LUA_EXPORT void draw_circle(float px, float py, float radius, Vector4 color);
FM_LUA_EXPORT void draw_circle_sdf(float px, float py, float radius, Vector4 color, float edge_thickness);
FM_LUA_EXPORT void draw_ring_sdf(float px, float py, float inner_radius, float radius, Vector4 color, float edge_thickness);
FM_LUA_EXPORT void draw_image(const char* name, float px, float py);
FM_LUA_EXPORT void draw_image_size(const char* name, float px, float py, float dx, float dy);
FM_LUA_EXPORT void draw_image_ex(const char* name, float px, float py, float dx, float dy, float opacity);
FM_LUA_EXPORT void draw_image_pro(uint32 texture, float px, float py, float dx, float dy, Vector2* uv, float opacity);
FM_LUA_EXPORT void draw_text(const char* text, float px, float py, const char* font);
FM_LUA_EXPORT void draw_text_ex(const char* text, float px, float py, Vector4 color, const char* font, float wrap, bool precise);
FM_LUA_EXPORT void draw_prepared_text(PreparedText* prepared_text);
FM_LUA_EXPORT void draw_line(Vector2 start, Vector2 end, float thickness, Vector4 color);
FM_LUA_EXPORT void draw_quad_ex(float px, float py, float sx, float sy, Vector4 color);
FM_LUA_EXPORT void draw_quad(Vector2 position, Vector2 size, Vector4 color);


//////////////////////////
// OPENGL CONFIGURATION //
//////////////////////////
FM_LUA_EXPORT void set_active_shader(const char* name);
FM_LUA_EXPORT void set_draw_mode(DrawMode mode);
FM_LUA_EXPORT void set_orthographic_projection(float left, float right, float bottom, float top, float _near, float _far);
FM_LUA_EXPORT void set_uniform_texture(const char* name, i32 value);
FM_LUA_EXPORT void set_uniform_i32(const char* name, i32 value);
FM_LUA_EXPORT void set_uniform_f32(const char* name, float value);
FM_LUA_EXPORT void set_uniform_vec2(const char* name, Vector2 value);
FM_LUA_EXPORT void set_uniform_vec3(const char* name, HMM_Vec3 value);
FM_LUA_EXPORT void set_uniform_vec4(const char* name, HMM_Vec4 value);
FM_LUA_EXPORT void set_uniform_mat3(const char* name, HMM_Mat3 value);
FM_LUA_EXPORT void set_uniform_mat4(const char* name, HMM_Mat4 value);

FM_LUA_EXPORT i32 find_uniform_index(const char* name);
void set_shader_immediate(Shader* shader);
FM_LUA_EXPORT void set_shader_immediate(const char* name);
FM_LUA_EXPORT void set_uniform_immediate_mat4(const char* name, HMM_Mat4 value);
FM_LUA_EXPORT void set_uniform_immediate_mat3(const char* name, HMM_Mat3 value);
FM_LUA_EXPORT void set_uniform_immediate_vec4(const char* name, HMM_Vec4 value);
FM_LUA_EXPORT void set_uniform_immediate_vec3(const char* name, HMM_Vec3 value);
FM_LUA_EXPORT void set_uniform_immediate_vec2(const char* name, Vector2 value);
FM_LUA_EXPORT void set_uniform_immediate_i32(const char* name, i32 value);
FM_LUA_EXPORT void set_uniform_immediate_f32(const char* name, float value);
FM_LUA_EXPORT void set_uniform_immediate_texture(const char* name, i32 value);

FM_LUA_EXPORT void set_blend_enabled(bool enabled);
FM_LUA_EXPORT void set_blend_mode(i32 source, i32 destination);
FM_LUA_EXPORT void begin_scissor(float px, float py, float dx, float dy);
FM_LUA_EXPORT void end_scissor();
FM_LUA_EXPORT void set_world_space(bool world_space);
FM_LUA_EXPORT void set_layer(int32 layer);
FM_LUA_EXPORT void set_camera(float px, float py);
FM_LUA_EXPORT void set_zoom(float zoom);


////////////////////////
// RENDERER INTERNALS //
////////////////////////
void init_render();
void update_render();
Vertex* push_vertex(float px, float py);
Vertex* push_vertex(float px, float py, Vector4 color);
Vertex* push_vertex(float px, float py, Vector2 uv, Vector4 color);
Vertex* push_vertex();
Vertex* push_vertex(i32 count);
FM_LUA_EXPORT void push_quad(float px, float py, float dx, float dy, Vector2* uv, float opacity);
void push_quad(float px, float py, float dx, float dy, Vector2* uv, Vector4 color);

tstring read_gl_error();
void log_gl_error();
