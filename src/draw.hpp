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


enum class DrawMode : u32 {
	Triangles,
};


enum class GlId : u32 {
	Framebuffer = 0,
	GpuShader = 1,
	Program = 2,
};


enum class GpuLoadOp : u32 {
	None = 0,
	Clear = 1
};

enum class GpuMemoryBarrier : u32 {
	ShaderStorage = 0,
	BufferUpdate = 1,
};

enum class GpuBufferKind : u32 {
	Storage = 0,
	Array = 1,
};

enum class GpuBufferUsage : u32 {
	Static = 0,
	Dynamic = 1,
	Stream = 2,
};

i32 convert_blend_mode(BlendMode mode);
u32 convert_draw_mode(DrawMode mode);
u32 convert_gl_id(GlId id);
u32 convert_memory_barrier(GpuMemoryBarrier barrier);
u32 convert_buffer_kind(GpuBufferKind kind);
u32 convert_buffer_usage(GpuBufferUsage usage);
u32 buffer_kind_to_barrier(GpuBufferKind kind);


enum class VertexAttributeKind : u32 {
	Float,
	U32,
};

struct GlTypeInfo {
	u32 size;
	u32 value;
	bool floating_point;
	bool integral;

	static GlTypeInfo from_attribute(VertexAttributeKind kind) {
		GlTypeInfo info;

		if (kind  == VertexAttributeKind::Float) {
			info.value = GL_FLOAT;
			info.size = sizeof(GLfloat);
			info.floating_point = true;
			info.integral = false;
		}
		else if (kind == VertexAttributeKind::U32) {
			info.value = GL_UNSIGNED_INT;
			info.size = sizeof(GLuint);
			info.floating_point = false;
			info.integral = true;		
		}
		else {
			assert(false);
		}


		return info;
	}
};

enum class Sdf : i32 {
	Circle = 0,
	Ring = 1,
};


///////////////////////////
// DRAW CALLS & BATCHING //
///////////////////////////
struct GpuRenderTarget;
struct GlState {
	bool scissor = false;
	Rect scissor_region = {};
	GpuShader* shader = nullptr;
	i32 layer = 0;
	bool world_space = true;
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

enum class DrawCallKind {
	Array,
	Instanced
};

struct DrawCall {
	DrawMode mode;
	i32 count;
	i32 offset;
	GlState state;

	void copy_from(DrawCall* other);
};


//////////////////////
// DEFAULT RENDERER //
//////////////////////
struct Vertex {
	Vector3 position;
	Vector4 color;
	Vector2 uv;
};
 
Vertex* push_vertex(float px, float py, Vector4 color);
Vertex* push_vertex(float px, float py, Vector2 uv, Vector4 color);
Vertex* alloc_vertices(u32 count);
FM_LUA_EXPORT void push_quad(float px, float py, float dx, float dy, Vector2* uv, float opacity);
void push_quad(float px, float py, float dx, float dy, Vector2* uv, Vector4 color);

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


///////////////////
// VERTEX BUFFER //
///////////////////
struct VertexBuffer {
	u8* data;
	u32 size;
	u32 capacity;

	u32 vertex_size;
};

void vertex_buffer_init(VertexBuffer* vertex_buffer, u32 max_vertices, u32 vertex_size);
u8*  vertex_buffer_push(VertexBuffer* vertex_buffer, void* data, u32 count);
u8*  vertex_buffer_reserve(VertexBuffer* vertex_buffer, u32 count);
void vertex_buffer_clear(VertexBuffer* vertex_buffer);
u32  vertex_buffer_byte_size(VertexBuffer* vertex_buffer);
u8*  vertex_buffer_at(VertexBuffer* vertex_buffer, u32 index);


/////////
// GPU //
/////////
struct GpuGraphicsPipeline;
struct GpuBuffer;

struct GpuUniformBinding {
	UniformKind kind;
	string name;
	union {
		HMM_Mat4 mat4;
		HMM_Mat3 mat3;
		HMM_Vec4 vec4;
		HMM_Vec3 vec3;
		Vector2 vec2;
		int32 i32;
		float f32;
		GpuGraphicsPipeline* pipeline;
		GpuRenderTarget* render_target;
	};
};

struct GpuSsboBinding {
	GpuBuffer* buffer;
	u32 index;
};

struct VertexAttribute {
	u32 count;
	VertexAttributeKind kind;
	u32 divisor;
};

struct GpuColorAttachment {
	GpuRenderTarget* read;
	GpuRenderTarget* write;
	GpuLoadOp load_op;
};


struct GpuRenderTargetDescriptor {
	Vector2 size;
};
struct GpuRenderTarget {
	u32 handle;
	u32 color_buffer;
	Vector2 size;
};


struct GpuCommandBufferBatchedDescriptor {
	VertexAttribute* vertex_attributes;
	u32 num_vertex_attributes = 0;
	u32 max_vertices = 256 * 1024;
	u32 max_draw_calls = 1024;
};
struct GpuCommandBufferBatched {
	VertexBuffer vertex_buffer;
	Array<DrawCall> draw_calls;

	u32 vao;
	u32 vbo;
};


struct GpuGraphicsPipelineDescriptor {
	GpuColorAttachment color_attachment;
	GpuCommandBufferBatched* command_buffer;
};
struct GpuGraphicsPipeline {
	GpuColorAttachment color_attachment;
	GpuCommandBufferBatched* command_buffer;
};


struct GpuBufferDescriptor {
	GpuBufferKind kind;
  GpuBufferUsage usage;
	u32 size;
};
struct GpuBuffer {
	GpuBufferKind kind;
  GpuBufferUsage usage;
	u32 size;
	u32 handle;
};


struct GpuBufferLayout {
	VertexAttribute* vertex_attributes;
	u32 num_vertex_attributes;
	GpuBuffer* buffer;
};
struct GpuVertexLayoutDescriptor {
	GpuBufferLayout* buffer_layouts;
	u32 num_buffer_layouts;
};
struct GpuVertexLayout {
	u32 vao;
};


struct GpuCommandBufferDescriptor {
	GpuVertexLayout* vertex_layout;
	GpuBuffer* vertex_buffer;
	u32 max_vertices;
	u32 max_draw_calls;
};
struct GpuCommandBuffer {
	Array<DrawCall> draw_calls;
	GpuVertexLayout* vertex_layout;
	GpuBuffer* vertex_buffer;
	GpuBuffer* instance_buffer;
};


struct DefaultRenderer {
	GpuGraphicsPipeline* pipeline;
	GpuCommandBuffer* command_buffer;
	GpuRenderTarget* render_target;
	VertexBuffer vertex_buffer;

	static constexpr u32 max_vertices = 64 * 1024;
	static constexpr u32 max_draw_calls = 1024;
};
DefaultRenderer default_renderer;

struct RenderEngine {
	Array<GpuCommandBufferBatched, 32>  command_buffers;
	Array<GpuCommandBuffer,        32>  commands;
	Array<GpuRenderTarget,         32>  targets;
	Array<GpuGraphicsPipeline,     32>  graphics_pipelines;
	Array<GpuBuffer,               32>  gpu_buffers;
	Array<GpuShader,               128> shaders;
	Array<GpuVertexLayout,         32>  vertex_layouts;

	GpuGraphicsPipeline* pipeline;


	Matrix4 projection;
	Vector2 camera;

	u8* screenshot;

	FileMonitor* shader_monitor;
};
RenderEngine render;

FM_LUA_EXPORT GpuCommandBuffer* gpu_commands_create(GpuCommandBufferDescriptor descriptor);
FM_LUA_EXPORT DrawCall*         gpu_commands_alloc_draw_call(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT DrawCall*         gpu_commands_find_draw_call(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT DrawCall*         gpu_commands_flush_draw_call(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void              gpu_commands_bind(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void              gpu_commands_preprocess(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void              gpu_commands_render(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void              gpu_commands_submit(GpuCommandBuffer* command_buffer);

/////////
// GPU //
/////////
FM_LUA_EXPORT GpuShader*               gpu_shader_create(GpuShaderDescriptor descriptor);
FM_LUA_EXPORT GpuShader*               gpu_shader_find(const char* name);
FM_LUA_EXPORT GpuRenderTarget*         gpu_render_target_create(GpuRenderTargetDescriptor descriptor);
FM_LUA_EXPORT GpuRenderTarget*         gpu_acquire_swapchain();
FM_LUA_EXPORT void                     gpu_render_target_bind(GpuRenderTarget* target);
FM_LUA_EXPORT void                     gpu_render_target_clear(GpuRenderTarget* target);
FM_LUA_EXPORT void                     gpu_render_target_blit(GpuRenderTarget* source, GpuRenderTarget* destination);
FM_LUA_EXPORT GpuCommandBufferBatched* gpu_create_command_buffer(GpuCommandBufferBatchedDescriptor descriptor);
FM_LUA_EXPORT DrawCall*                gpu_command_buffer_alloc_draw_call(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT DrawCall*                gpu_command_buffer_find_draw_call(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT DrawCall*                gpu_command_buffer_flush_draw_call(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT u8*                      gpu_command_buffer_alloc_vertex_data(GpuCommandBufferBatched* command_buffer, u32 count);
FM_LUA_EXPORT u8*                      gpu_command_buffer_push_vertex_data(GpuCommandBufferBatched* command_buffer, void* data, u32 count);
FM_LUA_EXPORT void                     gpu_command_buffer_bind(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT void                     gpu_command_buffer_preprocess(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT void                     gpu_command_buffer_render(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT void                     gpu_command_buffer_submit(GpuCommandBufferBatched* command_buffer);
FM_LUA_EXPORT GpuGraphicsPipeline*     gpu_graphics_pipeline_create(GpuGraphicsPipelineDescriptor descriptor);
FM_LUA_EXPORT DrawCall*                gpu_graphics_pipeline_alloc_draw_call(GpuGraphicsPipeline* pipeline);
FM_LUA_EXPORT void                     gpu_graphics_pipeline_begin_frame(GpuGraphicsPipeline* pipeline);
FM_LUA_EXPORT void                     gpu_graphics_pipeline_bind(GpuGraphicsPipeline* pipeline);
FM_LUA_EXPORT void                     gpu_graphics_pipeline_submit(GpuGraphicsPipeline* pipeline);
FM_LUA_EXPORT GpuBuffer*               gpu_buffer_create(GpuBufferDescriptor descriptor);
FM_LUA_EXPORT void                     gpu_buffer_bind(GpuBuffer* buffer);
FM_LUA_EXPORT void                     gpu_buffer_bind_base(GpuBuffer* buffer, u32 base);
FM_LUA_EXPORT void                     gpu_buffer_sync(GpuBuffer* buffer, void* data, u32 size);
FM_LUA_EXPORT void                     gpu_buffer_sync_subdata(GpuBuffer* buffer, void* data, u32 byte_size, u32 byte_offset);
FM_LUA_EXPORT void                     gpu_buffer_zero(GpuBuffer* buffer, u32 size);
FM_LUA_EXPORT GpuVertexLayout*         gpu_vertex_layout_create(GpuVertexLayoutDescriptor descriptor);
FM_LUA_EXPORT void                     gpu_vertex_layout_bind(GpuVertexLayout* layout);

FM_LUA_EXPORT void                     gpu_memory_barrier(GpuMemoryBarrier barrier);
FM_LUA_EXPORT void                     gpu_dispatch_compute(GpuBuffer* buffer, u32 size);
FM_LUA_EXPORT void                     gpu_swap_buffers();

//////////////////////////////////
// BATCHED OPENGL CONFIGURATION //
//////////////////////////////////
FM_LUA_EXPORT void    set_active_shader(const char* name);
FM_LUA_EXPORT void    set_active_shader_ex(GpuShader* shader);
FM_LUA_EXPORT void    set_draw_mode(DrawMode mode);
FM_LUA_EXPORT void    set_orthographic_projection(float left, float right, float bottom, float top, float _near, float _far);
FM_LUA_EXPORT void    set_uniform_texture(const char* name, i32 value);
FM_LUA_EXPORT void    set_uniform_i32(const char* name, i32 value);
FM_LUA_EXPORT void    set_uniform_f32(const char* name, float value);
FM_LUA_EXPORT void    set_uniform_vec2(const char* name, Vector2 value);
FM_LUA_EXPORT void    set_uniform_vec3(const char* name, HMM_Vec3 value);
FM_LUA_EXPORT void    set_uniform_vec4(const char* name, HMM_Vec4 value);
FM_LUA_EXPORT void    set_uniform_mat3(const char* name, HMM_Mat3 value);
FM_LUA_EXPORT void    set_uniform_mat4(const char* name, HMM_Mat4 value);
FM_LUA_EXPORT void    set_blend_enabled(bool enabled);
FM_LUA_EXPORT void    set_blend_mode(i32 source, i32 destination);
FM_LUA_EXPORT void    begin_scissor(float px, float py, float dx, float dy);
FM_LUA_EXPORT void    end_scissor();
FM_LUA_EXPORT void    set_world_space(bool world_space);
FM_LUA_EXPORT void    set_layer(int32 layer);
FM_LUA_EXPORT void    set_camera(float px, float py);
FM_LUA_EXPORT void    set_zoom(float zoom);
FM_LUA_EXPORT void    set_gl_name(u32 kind, u32 handle, u32 name_len, const char* name);
FM_LUA_EXPORT tstring read_gl_error();
FM_LUA_EXPORT void    log_gl_error();
FM_LUA_EXPORT void    log_gl_errors();

////////////////////////////////////
// IMMEDIATE OPENGL CONFIGURATION //
////////////////////////////////////
FM_LUA_EXPORT i32  find_uniform_index(const char* name);
FM_LUA_EXPORT void set_shader_immediate_ex(GpuShader* shader);
FM_LUA_EXPORT void set_shader_immediate(const char* name);
FM_LUA_EXPORT void set_uniform_immediate_mat4(const char* name, HMM_Mat4 value);
FM_LUA_EXPORT void set_uniform_immediate_mat3(const char* name, HMM_Mat3 value);
FM_LUA_EXPORT void set_uniform_immediate_vec4(const char* name, HMM_Vec4 value);
FM_LUA_EXPORT void set_uniform_immediate_vec3(const char* name, HMM_Vec3 value);
FM_LUA_EXPORT void set_uniform_immediate_vec2(const char* name, Vector2 value);
FM_LUA_EXPORT void set_uniform_immediate_i32(const char* name, i32 value);
FM_LUA_EXPORT void set_uniform_immediate_f32(const char* name, float value);
FM_LUA_EXPORT void set_uniform_immediate_texture(const char* name, i32 value);


////////////////////////
// RENDERER INTERNALS //
////////////////////////
void init_render();
void APIENTRY on_opengl_message(GLenum source, GLenum type, GLuint id,GLenum severity, GLsizei length,const GLchar *msg, const void *data);
