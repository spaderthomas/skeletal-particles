#ifndef GRAPHICS_H
#define GRAPHICS_H

#define GPU_NEAR_PLANE -100.0
#define GPU_FAR_PLANE 100.0

typedef enum {
  GPU_COMMAND_OP_BIND_BUFFERS = 10,
  GPU_COMMAND_OP_BEGIN_RENDER_PASS = 20,
  GPU_COMMAND_OP_END_RENDER_PASS = 21,
  GPU_COMMAND_OP_BIND_PIPELINE = 30,
  GPU_COMMAND_OP_SET_CAMERA = 40,
  GPU_COMMAND_OP_SET_LAYER = 41,
  GPU_COMMAND_OP_SET_WORLD_SPACE = 42,
  GPU_COMMAND_OP_SET_SCISSOR = 43,
  GPU_COMMAND_OP_DRAW = 70,
} GpuCommandOp;

typedef enum {
  GPU_PRIMITIVE_TRIANGLES = 0
} GpuDrawPrimitive;

typedef enum {
  GPU_DRAW_MODE_ARRAYS = 0,
  GPU_DRAW_MODE_INSTANCE = 1,
} GpuDrawMode;

typedef enum {
	GPU_VERTEX_ATTRIBUTE_FLOAT = 0,
	GPU_VERTEX_ATTRIBUTE_U32 = 1,
} GpuVertexAttributeKind;


////////////////////////
// BINDABLE RESOURCES //
////////////////////////
typedef struct {
  GpuRenderTarget* color;
} GpuRenderPass;

typedef struct {
  struct {
    GpuBuffer** buffers;
    u32 count;
  } vertex;
  // Uniform
  // SSBO
} GpuBufferBinding;


//////////////////
// GPU PIPELINE //
//////////////////
typedef struct {
  GpuShader* shader;
  GpuDrawPrimitive primitive;
} GpuRasterState;

typedef struct {
  Vector2 position;
  Vector2 size;
  bool enabled;
} GpuScissorState;

typedef struct {
  u32 layer;
  bool world_space;
  Vector2 camera;
  Matrix4 projection;
} GpuRendererState;

typedef struct {
	GpuVertexAttributeKind kind;
	u32 count;
	u32 divisor;
} GpuVertexAttribute;

typedef struct {
	GpuVertexAttribute* vertex_attributes;
	u32 num_vertex_attributes;
} GpuBufferLayout;

typedef struct {
  GpuRasterState raster;
	GpuBufferLayout* buffer_layouts;
	u32 num_buffer_layouts;
} GpuPipeline;


////////////////////////
// GPU COMMAND BUFFER //
////////////////////////
typedef struct {
  GpuDrawMode mode;
  u32 vertex_offset;
  u32 num_vertices;
  u32 num_instances;
} GpuDrawCall;

typedef struct {
  GpuCommandOp kind;
  union {
    GpuPipeline       pipeline;
    GpuBufferBinding  buffers;
    GpuRenderPass     render_pass;
    GpuRendererState  render;
    GpuScissorState   scissor;
    GpuDrawCall       draw;
  };
} GpuCommand;

typedef struct {
  u32 max_commands;
} GpuCommandBufferDescriptor;

typedef struct {
  GpuPipeline pipeline;
  GpuBufferBinding buffers;
  GpuRenderPass render_pass;
  GpuRendererState render;
  GpuScissorState scissor;

  Array<GpuCommand> commands;
  u32 vao;
} GpuCommandBuffer;


FM_LUA_EXPORT GpuCommandBuffer* _gpu_command_buffer_create(GpuCommandBufferDescriptor descriptor);
FM_LUA_EXPORT void              _gpu_command_buffer_draw(GpuCommandBuffer* command_buffer, GpuDrawCall draw_call);
FM_LUA_EXPORT void              _gpu_command_buffer_submit(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void              _gpu_bind_pipeline(GpuCommandBuffer* command_buffer, GpuPipeline pipeline);
FM_LUA_EXPORT void              _gpu_begin_render_pass(GpuCommandBuffer* command_buffer, GpuRenderPass render_pass);
FM_LUA_EXPORT void              _gpu_end_render_pass(GpuCommandBuffer* command_buffer);
FM_LUA_EXPORT void              _gpu_bind_buffers(GpuCommandBuffer* command_buffer, GpuBufferBinding buffers);
FM_LUA_EXPORT void              _gpu_bind_render_state(GpuCommandBuffer* command_buffer, GpuRendererState render);
FM_LUA_EXPORT void              _gpu_set_layer(GpuCommandBuffer* command_buffer, u32 layer);
FM_LUA_EXPORT void              _gpu_set_world_space(GpuCommandBuffer* command_buffer, bool world_space);
FM_LUA_EXPORT void              _gpu_set_camera(GpuCommandBuffer* command_buffer, Vector2 camera);

void _gpu_command_buffer_process_command(GpuCommandBuffer* command_buffer, GpuCommand command);
void _gpu_command_buffer_clear_cached_state(GpuCommandBuffer* command_buffer);
u32 _gpu_vertex_layout_calculate_stride(GpuBufferLayout* layout);
u32 gpu_draw_primitive_to_gl_draw_primitive(GpuDrawPrimitive primitive);
GlTypeInfo gl_type_info_from_vertex_attribute_kind(GpuVertexAttributeKind kind);
void* gl_u32_to_void_pointer(u32 value);

//////////////
// INTERNAL //
//////////////
typedef struct {
  Array<GpuCommandBuffer, 32> command_buffers;
} CommandRenderer;
CommandRenderer command_renderer;

void init_command_renderer();
void test_command_renderer();
#endif // GRAPHICS_H



////////////////////
// IMPLEMENTATION //
////////////////////
#ifdef GRAPHICS_IMPLEMENTATION


////////////////////
// COMMAND BUFFER //
////////////////////
GpuCommandBuffer* _gpu_command_buffer_create(GpuCommandBufferDescriptor descriptor) {
  auto command_buffer = arr_push(&command_renderer.command_buffers);
  arr_init(&command_buffer->commands, descriptor.max_commands);
  glGenVertexArrays(1, &command_buffer->vao);
  glBindVertexArray(command_buffer->vao);

  return command_buffer;
}

void _gpu_command_buffer_clear_cached_state(GpuCommandBuffer* command_buffer) {
  zero_memory(&command_buffer->pipeline, sizeof(GpuPipeline));
  zero_memory(&command_buffer->buffers, sizeof(GpuBufferBinding));
  zero_memory(&command_buffer->render_pass, sizeof(GpuRenderPass));
  zero_memory(&command_buffer->render, sizeof(GpuRendererState));
  zero_memory(&command_buffer->scissor, sizeof(GpuScissorState));
}

void _gpu_command_buffer_submit(GpuCommandBuffer* command_buffer) {
    _gpu_command_buffer_clear_cached_state(command_buffer);

  arr_for(command_buffer->commands, it) {
    auto& command = *it;
    auto& pipeline = command_buffer->pipeline;

    switch (command.kind) {
      case GPU_COMMAND_OP_BEGIN_RENDER_PASS: {
        gpu_render_target_bind(command.render_pass.color);
        command_buffer->render_pass = command.render_pass;
      } break;

      case GPU_COMMAND_OP_END_RENDER_PASS: {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glDisable(GL_SCISSOR_TEST);
      } break;

      case GPU_COMMAND_OP_BIND_PIPELINE: {
        glUseProgram(command.pipeline.raster.shader->program);

        auto target = command_buffer->render_pass.color;
        set_uniform_immediate_f32("master_time", engine.elapsed_time);
        set_uniform_immediate_mat4("projection", HMM_Orthographic_RH_NO(0, target->size.x, 0, target->size.y, GPU_NEAR_PLANE, GPU_FAR_PLANE));
        set_uniform_immediate_vec2("output_resolution", target->size);
        set_uniform_immediate_vec2("native_resolution", window.native_resolution);
        command_buffer->pipeline = command.pipeline;
      } break;

      case GPU_COMMAND_OP_BIND_BUFFERS: {
        auto& vertex_buffers = command.buffers.vertex;
        auto& pipeline = command_buffer->pipeline;

        assert(vertex_buffers.count <= pipeline.num_buffer_layouts);

        u32 attribute_index = 0;
        for (u32 buffer_index = 0; buffer_index < vertex_buffers.count; buffer_index++) {
          auto buffer_layout = pipeline.buffer_layouts[buffer_index];
          auto buffer = vertex_buffers.buffers[buffer_index];

          gpu_buffer_bind(buffer);

          u32 stride = _gpu_vertex_layout_calculate_stride(&buffer_layout);

          u64 offset = 0;
          for (u32 i = 0; i < buffer_layout.num_vertex_attributes; i++) {
            glEnableVertexAttribArray(attribute_index);

            auto attribute = buffer_layout.vertex_attributes[i];
            
            switch(attribute.kind) {
              case GPU_VERTEX_ATTRIBUTE_FLOAT: glVertexAttribPointer( attribute_index, attribute.count, GL_FLOAT,        GL_FALSE, stride, gl_u32_to_void_pointer(offset)); break;
              case GPU_VERTEX_ATTRIBUTE_U32:   glVertexAttribIPointer(attribute_index, attribute.count, GL_UNSIGNED_INT,           stride, gl_u32_to_void_pointer(offset)); break;
              default: {
                assert(false);
              } break;
            }

            glVertexAttribDivisor(attribute_index, attribute.divisor);

            auto type_info = gl_type_info_from_vertex_attribute_kind(attribute.kind);
            offset += attribute.count * type_info.size;
            attribute_index++;
          }
        }

        command_buffer->buffers = command.buffers;
      } break;

      case GPU_COMMAND_OP_SET_SCISSOR: {
        if (command.scissor.enabled != command_buffer->scissor.enabled) {
          if (command.scissor.enabled) {
            glEnable(GL_SCISSOR_TEST);
            glScissor(
              command.scissor.position.x, command.scissor.position.y, 
              command.scissor.size.x, command.scissor.size.y);
          }
          else {
            glDisable(GL_SCISSOR_TEST);
          }
        }

        command_buffer->scissor = command.scissor;
      } break;

      case GPU_COMMAND_OP_SET_WORLD_SPACE: {
        command_buffer->render.world_space = command.render.world_space;
      } break;
      case GPU_COMMAND_OP_SET_CAMERA: {
        command_buffer->render.camera = command.render.camera;
      } break;
      case GPU_COMMAND_OP_SET_LAYER: {
        command_buffer->render.layer = command.render.layer;
      } break;

      case GPU_COMMAND_OP_DRAW: {      
        auto view_transform = command_buffer->render.world_space ? 
          HMM_Translate(HMM_V3(-command_buffer->render.camera.x, -command_buffer->render.camera.y, 0.f)) :
          HMM_M4D(1.0);
        set_uniform_immediate_mat4("view", view_transform);

        auto primitive = gpu_draw_primitive_to_gl_draw_primitive(pipeline.raster.primitive);
        switch (command.draw.mode) {
          case GPU_DRAW_MODE_ARRAYS: glDrawArrays(primitive, command.draw.vertex_offset, command.draw.num_vertices); break;
          case GPU_DRAW_MODE_INSTANCE: glDrawArraysInstanced(primitive, command.draw.vertex_offset, command.draw.num_vertices, command.draw.num_instances); break;
        }
      } break;
    }
  }

  _gpu_command_buffer_clear_cached_state(command_buffer);
  arr_clear(&command_buffer->commands);
}

void _gpu_command_buffer_process_command(GpuCommandBuffer* command_buffer, GpuCommand command) {
}


void _gpu_command_buffer_draw(GpuCommandBuffer* command_buffer, GpuDrawCall draw_call) {
  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_DRAW,
    .draw = draw_call
  });
}

/////////////
// BINDING //
/////////////
void _gpu_bind_pipeline(GpuCommandBuffer* command_buffer, GpuPipeline pipeline) {
  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_BIND_PIPELINE,
    .pipeline = pipeline
  });
}

void _gpu_begin_render_pass(GpuCommandBuffer* command_buffer, GpuRenderPass render_pass) {
  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_BEGIN_RENDER_PASS,
    .render_pass = render_pass
  });
}

void _gpu_end_render_pass(GpuCommandBuffer* command_buffer) {
  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_END_RENDER_PASS,
  });
}

void _gpu_bind_buffers(GpuCommandBuffer* command_buffer, GpuBufferBinding buffers) {
  if (is_memory_equal(&command_buffer->buffers, &buffers, sizeof(GpuBufferBinding))) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_BIND_BUFFERS,
    .buffers = buffers
  });
}

//////////////////
// RENDER STATE //
//////////////////
void _gpu_set_layer(GpuCommandBuffer* command_buffer, u32 layer) {
  if (command_buffer->render.layer == layer) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_SET_LAYER,
    .render = {
      .layer = layer
    }
  });
}

void _gpu_set_world_space(GpuCommandBuffer* command_buffer, bool world_space) {
  if (command_buffer->render.world_space == world_space) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_SET_WORLD_SPACE,
    .render = {
      .world_space = world_space
    }
  });
}

void _gpu_set_camera(GpuCommandBuffer* command_buffer, Vector2 camera) {
  if (is_memory_equal(&command_buffer->render.camera,  &camera, sizeof(Vector2))) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_OP_SET_CAMERA,
    .render = {
      .camera = camera
    }
  });
}

void _gpu_bind_render_state(GpuCommandBuffer* command_buffer, GpuRendererState render) {
  _gpu_set_layer(command_buffer, render.layer);
  _gpu_set_camera(command_buffer, render.camera);
  _gpu_set_world_space(command_buffer, render.world_space);
}


/////////////////////
// ENUM CONVERSION //
/////////////////////
u32 gpu_draw_primitive_to_gl_draw_primitive(GpuDrawPrimitive primitive) {
  switch (primitive) {
    case GPU_PRIMITIVE_TRIANGLES: return GL_TRIANGLES;
  }

  assert(false);
  return 0;
}

GlTypeInfo gl_type_info_from_vertex_attribute_kind(GpuVertexAttributeKind kind) {
  GlTypeInfo info;

  if (kind  == GPU_VERTEX_ATTRIBUTE_FLOAT) {
    info.value = GL_FLOAT;
    info.size = sizeof(GLfloat);
    info.floating_point = true;
    info.integral = false;
  }
  else if (kind == GPU_VERTEX_ATTRIBUTE_U32) {
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

void* gl_u32_to_void_pointer(u32 value) {
  return (void*)(uintptr_t)value;
}

u32 _gpu_vertex_layout_calculate_stride(GpuBufferLayout* layout) {
  assert(layout);

  u32 stride = 0;

  for (u32 i = 0; i < layout->num_vertex_attributes; i++) {
    auto attribute = layout->vertex_attributes[i];
    auto type_info = gl_type_info_from_vertex_attribute_kind(attribute.kind);
    stride += attribute.count * type_info.size;
  }

  return stride;
}


/////////////
// TESTING //
/////////////
void init_command_renderer() {
  arr_init(&command_renderer.command_buffers);

}

void test_command_renderer() {
}
#endif // GRAPHICS_IMPL