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
  GpuBackedBuffer vertices;
  GpuBackedBuffer instances;
  GpuBackedBuffer combinations;
  GpuBackedBuffer shape_data;

  GpuPipeline* pipeline;
  GpuBufferBinding bindings;
} SdfRenderer;

SdfRenderer sdf_renderer_create(u32 buffer_size);
void sdf_renderer_draw(SdfRenderer* renderer, GpuCommandBuffer* command_buffer);
void sdf_circle(SdfRenderer* renderer, float radius);

]]