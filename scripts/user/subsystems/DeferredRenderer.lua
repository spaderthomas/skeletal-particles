

DeferredRenderer = tdengine.subsystem.define('DeferredRenderer')

function DeferredRenderer:init()
  self.render_enabled = true
  self.max_lights = 16;
  self.lights = nil
  self.sdf_buffer_length = 1024
  self.shape_buffers = {}
end

function DeferredRenderer:on_start_game()
  self.shape_buffers = {
    circle = BackedGpuBuffer:new('SdfCircle', self.sdf_buffer_length)
  }

  self.lights = BackedGpuBuffer:new('Light', self.max_lights, tdengine.gpus.find(Buffer.Lights))
  self.lights.gpu_buffer:zero()


  local vertex_buffer = tdengine.ffi.gpu_buffer_create(GpuBufferDescriptor:new({
    kind = GpuBufferKind.Array,
    usage = GpuBufferUsage.Static,
    size = ffi.sizeof('SdfVertex') * 1024
  }))
  local instance_buffer = tdengine.ffi.gpu_buffer_create(GpuBufferDescriptor:new({
    kind = GpuBufferKind.Array,
    usage = GpuBufferUsage.Static,
    size = ffi.sizeof('SdfInstance') * 1024
  }))

  -- local vertex_layout_descriptor = {
  --   buffer_layouts = {
  --     {
  --       buffer = vertex_buffer,
  --       vertex_attributes = {
  --         {
  --           count = 2,
  --           kind = tdengine.enums.VertexAttributeKind.Float
  --         },
  --         {
  --           count = 2,
  --           kind = tdengine.enums.VertexAttributeKind.Float
  --         }
  --       }
  --     },
  --     {
  --       buffer = instance_buffer,
  --       vertex_attributes = {
  --         {
  --           count = 2,
  --           kind = tdengine.enums.VertexAttributeKind.Float,
  --           divisor = 1
  --         },
  --         {
  --           count = 3,
  --           kind = tdengine.enums.VertexAttributeKind.Float,
  --           divisor = 1
  --         },
  --         {
  --           count = 1,
  --           kind = tdengine.enums.VertexAttributeKind.Float,
  --           divisor = 1
  --         },
  --         {
  --           count = 1,
  --           kind = tdengine.enums.VertexAttributeKind.U32,
  --           divisor = 1
  --         }
  --       }
  --     }
  --   }
  -- }

  -- self.vertex_layout = tdengine.ffi.gpu_vertex_layout_create(GpuVertexLayoutDescriptor:new(vertex_layout_descriptor))

  self.sdf_vertices = BackedGpuBuffer:new('SdfVertex', 1024, vertex_buffer)
  self.sdf_instances = BackedGpuBuffer:new('SdfInstance', 1024, instance_buffer)

  local sdf_quad = {
    ffi.new('SdfVertex', { {0, 1}, {0, 1} }),
    ffi.new('SdfVertex', { {0, 0}, {0, 0} }),
    ffi.new('SdfVertex', { {1, 0}, {1, 0} }),
    ffi.new('SdfVertex', { {0, 1}, {0, 1} }),
    ffi.new('SdfVertex', { {1, 0}, {1, 0} }),
    ffi.new('SdfVertex', { {1, 1}, {1, 1} }),
  }
  for sdf_vertex in tdengine.iterator.values(sdf_quad) do
    self.sdf_vertices.cpu_buffer:push(sdf_vertex)
  end
  self.sdf_vertices:sync()

  self.sdf_instances.cpu_buffer:push(ffi.new('SdfInstance', {
    {10, 10},
    tdengine.colors.blue:to_vec3(),
    0.0,
    0
  }))
  self.sdf_instances:sync()


  self.command_buffer = tdengine.gpu.command_buffer_create(GpuCommandBufferDescriptor:new({
    max_commands = 1024
  }))

  self.render_pass = GpuRenderPass:new({
    color = RenderTarget.Color
  })

  self.pipeline = GpuPipeline:new({
    raster = {
      shader = Shader.Shape,
      primitive = GpuDrawPrimitive.Triangles
    },
    buffer_layouts = {
      {
        vertex_attributes = {
          {
            count = 2,
            kind = tdengine.enums.GpuVertexAttributeKind.Float
          },
          {
            count = 2,
            kind = tdengine.enums.GpuVertexAttributeKind.Float
          }
        }
      }
   }
  })

  self.buffers = GpuBufferBinding:new({
    vertex = {
      vertex_buffer
    }
  })
end

function DeferredRenderer:on_begin_frame()
  -- for shape_buffer in tdengine.iterator.values(self.shape_buffers) do
  --   shape_buffer.cpu_buffer:fast_clear()
  -- end

  self.lights.cpu_buffer:fast_clear()
end

function DeferredRenderer:on_scene_rendered()
  -- if not self.render_enabled then return end

  -- for light in tdengine.entity.iterate('PointLight') do
  --   self.lights.cpu_buffer:push(light:to_ctype())
  -- end
  -- self.lights:sync()



  -- begin a render pass
  tdengine.gpu.begin_render_pass(self.command_buffer, self.render_pass)
  tdengine.gpu.bind_pipeline(self.command_buffer, self.pipeline)
  tdengine.gpu.bind_buffers(self.command_buffer, self.buffers)
  tdengine.gpu.set_world_space(self.command_buffer, true)
  tdengine.gpu.set_camera(self.command_buffer, tdengine.editor.find('EditorCamera').offset:to_ctype())
  tdengine.gpu.command_buffer_draw(self.command_buffer, GpuDrawCall:new({
    mode = GpuDrawMode.Arrays,
    vertex_offset = 0,
    num_vertices = 6
  }))
  tdengine.gpu.end_render_pass(self.command_buffer)
  tdengine.gpu.command_buffer_submit(self.command_buffer)

  -- bind the buffers
  -- draw a triangle
  -- end the render pass
  -- submit the commands

  -- update dynamic uniforms
  -- bind
  -- draw a fullscreen quad
  -- submit
  -- self.visualize_light_map:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)
  -- self.visualize_light_map:render()

  -- self.light_scene:render()
  -- self.apply_lighting:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)

  -- self.shapes:render()

  -- tdengine.subsystem.find('PostProcess'):upscale()
end

function DeferredRenderer:draw_circle(sdf_circle)
  -- self.shape_buffers.circle.cpu_buffer:push(sdf_circle)
end
