return [[
typedef struct {
  Vector4 color;
  Vector2 position;
  f32 radial_falloff;
  f32 angular_falloff;
  f32 intensity;
  f32 padding [3];
} Light;

/////////
// SDF //
/////////
typedef struct {
  GpuBufferBinding bindings;
  GpuBackedBuffer vertices;
  GpuBackedBuffer instances;
  GpuBackedBuffer combinations;
  GpuBackedBuffer shape_data;
  GpuPipeline* pipeline;
} SdfRenderer;

SdfRenderer sdf_renderer_create(u32 buffer_size);
void        sdf_renderer_draw(SdfRenderer* renderer, GpuCommandBuffer* command_buffer);
void        sdf_circle_ex(SdfRenderer* renderer, float px, float py, float r, float g, float b, float rotation, float edge_thickness, float radius);
void        sdf_grid(SdfRenderer* renderer, u32 grid_width, u32 grid_size);

]]