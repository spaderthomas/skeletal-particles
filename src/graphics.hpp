typedef enum {
  GPU_COMMAND_SET_SCISSOR_STATE = 0,
  GPU_COMMAND_SET_RASTER_STATE = 1,
  GPU_COMMAND_SET_RENDER_STATE = 2,
  GPU_COMMAND_SET_RENDER_ATTACHMENT = 3,
  GPU_COMMAND_SET_BUFFER_BINDINGS = 4,
  GPU_COMMAND_DRAW = 5,
} GpuCommandKind;

typedef enum {
  GPU_PRIMITIVE_TRIANGLES = 0
} GpuDrawPrimitive;

typedef enum {
  GPU_MODE_ARRAYS = 0,
  GPU_MODE_INSTANCE = 1,
} GpuDrawMode;

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
} GpuRendererState;

typedef struct {
  GpuDrawMode mode;
  u32 vertex_offset;
  u32 num_vertices;
  u32 num_instances;
} GpuDrawCall;


typedef struct {
  GpuVertexLayout* vertex;
} GpuBufferBinding;

typedef struct {
  GpuRenderTarget* color;
} GpuRenderAttachment;


typedef struct {
  GpuRasterState       raster;
  GpuScissorState      scissor;
  GpuRendererState     render;
  GpuRenderAttachment  attachment;
  GpuBufferBinding     buffers;
} GpuState;

typedef struct {
  GpuCommandKind kind;
  union {
    GpuRasterState       raster;
    GpuScissorState      scissor;
    GpuRendererState     render;
    GpuRenderAttachment  attachment;
    GpuBufferBinding     buffers;
  };
} GpuCommand;

typedef struct {
  u32 max_commands;
} _GpuCommandBufferDescriptor;

typedef struct {
  GpuState state;
  Array<GpuCommand> commands;
} GpuCommandBuffer;

typedef struct {
  Array<GpuCommandBuffer, 32> command_buffers;
} CommandRenderer;
CommandRenderer command_renderer;

void init_command_renderer() {
  arr_init(&command_renderer.command_buffers);
}



GpuCommandBuffer* _gpu_command_buffer_create(_GpuCommandBufferDescriptor descriptor);
void _gpu_command_buffer_process_command(GpuCommandBuffer* command_buffer, GpuCommand command);
void _gpu_command_buffer_submit(GpuCommandBuffer* command_buffer);

GpuCommandBuffer* _gpu_command_buffer_create(_GpuCommandBufferDescriptor descriptor) {
  auto command_buffer = arr_push(&command_renderer.command_buffers);
  arr_init(&command_buffer->commands, descriptor.max_commands);
  
  return command_buffer;
}

void _gpu_command_buffer_submit(GpuCommandBuffer* command_buffer) {
  _gpu_command_buffer_process_command(command_buffer, {
    .kind = GPU_COMMAND_SET_RASTER_STATE,
    .raster = {
      .shader = NULL,
      .primitive = GPU_PRIMITIVE_TRIANGLES
    }
  });
  _gpu_command_buffer_process_command(command_buffer, {
    .kind = GPU_COMMAND_SET_SCISSOR_STATE,
    .scissor = {
      .enabled = false
    }
  });
  _gpu_command_buffer_process_command(command_buffer, {
    .kind = GPU_COMMAND_SET_RENDER_STATE,
    .render = {
      .layer = 0,
      .world_space = true,
      .camera = Vector2(),
    }
  });
  _gpu_command_buffer_process_command(command_buffer, {
    .kind = GPU_COMMAND_SET_RENDER_ATTACHMENT,
    .attachment = {
      .color = NULL
    }
  });
  _gpu_command_buffer_process_command(command_buffer, {
    .kind = GPU_COMMAND_SET_BUFFER_BINDINGS,
    .buffers = {
      .vertex = NULL,
    }
  });

  arr_for(command_buffer->commands, command) {
    _gpu_command_buffer_process_command(command_buffer, *command);
  }
}

void _gpu_command_buffer_process_command(GpuCommandBuffer* command_buffer, GpuCommand command) {
  auto& state = command_buffer->state;

  switch (command.kind) {
    case GPU_COMMAND_SET_RASTER_STATE: {
      if (command.raster.shader != state.raster.shader) {
        set_shader_immediate_ex(command.raster.shader);
      }

      state.raster = command.raster;
    } break;


    case GPU_COMMAND_SET_SCISSOR_STATE: {
      if (command.scissor.enabled != state.scissor.enabled) {
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

      state.scissor = command.scissor;
    } break;


    case GPU_COMMAND_SET_RENDER_ATTACHMENT: {
      if (command.attachment.color != state.attachment.color) {
        gpu_render_target_bind(command.attachment.color);
      }

      state.attachment = command.attachment;
    } break;


    case GPU_COMMAND_SET_RENDER_STATE: {
      if (command.render.world_space) {
        auto view_transform = HMM_Translate(HMM_V3(-command.render.camera.x, -command.render.camera.y, 0.f));
        set_uniform_immediate_mat4("view", view_transform);
      }
      else {
        auto view_transform = HMM_M4D(1.0);
        set_uniform_immediate_mat4("view", view_transform);
      }

      state.render = command.render;
    } break;


    case GPU_COMMAND_SET_BUFFER_BINDINGS: {
      if (command.buffers.vertex != state.buffers.vertex) {
        glBindVertexArray(command.buffers.vertex->vao);
      }

      state.buffers = command.buffers;
    } break;
  }

}

///////////////////////
// RENDER ATTACHMENT //
///////////////////////
void _gpu_bind_render_attachment(GpuCommandBuffer* command_buffer, GpuRenderAttachment attachment) {
  if (is_memory_equal(&command_buffer->state.attachment, &attachment, sizeof(GpuRenderAttachment))) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_SET_RENDER_ATTACHMENT,
    .attachment = attachment
  });

}

void _gpu_bind_color_attachment(GpuCommandBuffer* command_buffer, GpuRenderTarget* render_target) {
  auto attachment = command_buffer->state.attachment;
  attachment.color = render_target;
  _gpu_bind_render_attachment(command_buffer, attachment);
}

/////////////////
// RASTER STATE //
/////////////////
void _gpu_bind_raster_state(GpuCommandBuffer* command_buffer, GpuRasterState raster) {
  if (is_memory_equal(&command_buffer->state.raster, &raster, sizeof(GpuRasterState))) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_SET_RASTER_STATE,
    .raster = raster
  });
}

void _gpu_bind_shader(GpuCommandBuffer* command_buffer, GpuShader* shader) {
  auto raster = command_buffer->state.raster;
  raster.shader = shader;
  _gpu_bind_raster_state(command_buffer, raster);
}

void _gpu_set_primitive(GpuCommandBuffer* command_buffer, GpuDrawPrimitive primitive) {
  auto raster = command_buffer->state.raster;
  raster.primitive = primitive;
  _gpu_bind_raster_state(command_buffer, raster);
}

//////////////////
// RENDER STATE //
//////////////////
void _gpu_bind_render_state(GpuCommandBuffer* command_buffer, GpuRendererState render) {
  if (is_memory_equal(&command_buffer->state.render, &render, sizeof(GpuRendererState))) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_SET_RENDER_STATE,
    .render = render
  });
}

void _gpu_set_layer(GpuCommandBuffer* command_buffer, u32 layer) {
  auto render = command_buffer->state.render;
  render.layer = layer;
  _gpu_bind_render_state(command_buffer, render);
}

void _gpu_set_world_space(GpuCommandBuffer* command_buffer, bool world_space) {
  auto render = command_buffer->state.render;
  render.world_space = world_space;
  _gpu_bind_render_state(command_buffer, render);
}

void _gpu_set_camera(GpuCommandBuffer* command_buffer, Vector2 camera) {
  auto render = command_buffer->state.render;
  render.camera = camera;
  _gpu_bind_render_state(command_buffer, render);
}

/////////////
// BUFFERS //
/////////////
void _gpu_bind_buffers(GpuCommandBuffer* command_buffer, GpuBufferBinding buffers) {
  if (is_memory_equal(&command_buffer->state.buffers, &buffers, sizeof(GpuBufferBinding))) return;

  arr_push(&command_buffer->commands, {
    .kind = GPU_COMMAND_SET_BUFFER_BINDINGS,
    .buffers = buffers
  });
}

void _gpu_set_vertex_layout(GpuCommandBuffer* command_buffer, GpuVertexLayout* layout) {
  auto render = command_buffer->state.render;
  render.camera = camera;
  _gpu_bind_render_state(command_buffer, render);
}


void test_command_renderer() {
  auto command_buffer = _gpu_command_buffer_create({
    .max_commands = 1024
  });

  auto render_target = gpu_acquire_swapchain();
  auto shader = gpu_shader_find("solid");
 
  _gpu_bind_color_attachment(command_buffer, render_target);
  _gpu_bind_shader(command_buffer, shader);
  _gpu_set_primitive(command_buffer, GPU_PRIMITIVE_TRIANGLES);
  _gpu_set_layer(command_buffer, 69);
  _gpu_set_world_space(command_buffer, true);
  _gpu_set_camera(command_buffer, { .x = 69, .y = 420 });
}