

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
    ffi.new('SdfVertex', { {-0.5, 0.5}, {-0.5, 0.5} }),
    ffi.new('SdfVertex', { {-0.5, -0.5}, {-0.5, -0.5} }),
    ffi.new('SdfVertex', { {0.5, -0.5}, {0.5, -0.5} }),
    ffi.new('SdfVertex', { {-0.5, 0.5}, {-0.5, 0.5} }),
    ffi.new('SdfVertex', { {0.5, -0.5}, {0.5, -0.5} }),
    ffi.new('SdfVertex', { {0.5, 0.5}, {0.5, 0.5} }),
  }
  for sdf_vertex in tdengine.iterator.values(sdf_quad) do
    self.sdf_vertices.cpu_buffer:push(sdf_vertex)
  end
  self.sdf_vertices:sync()

  self.sdf_instances.cpu_buffer:push(SdfInstance:new({
    position = Vector2:new(tdengine.math.random_float(0, 100), 10),
    color = tdengine.colors.red:to_vec3(),
    rotation = 0.0,
    sdf_params = {
      0.0, 0.5, 1.0
    }
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
      },
      {
        vertex_attributes = {
          {
            count = 3,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 2,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 1,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 3,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 3,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          }
        }
      }
   }
  })

  self.uniforms = {
    shape = tdengine.gpu.uniform_create(GpuUniformDescriptor:new({
      name = 'shape',
      kind = GpuUniformKind.Enum
    }))
  }

end

function DeferredRenderer:on_begin_frame()
  -- for shape_buffer in tdengine.iterator.values(self.shape_buffers) do
  --   shape_buffer.cpu_buffer:fast_clear()
  -- end

  self.lights.cpu_buffer:fast_clear()
end

function DeferredRenderer:draw_circle(px, py, radius, rotation, color)
  self.sdf_instances.cpu_buffer:push(SdfInstance:new({
    position = Vector2:new(px, py),
    color = color:to_vec3(),
    rotation = rotation,
    shape = Sdf.Circle,
    shape_data = {
      radius = 10
    }
  }))
end

function DeferredRenderer:on_scene_rendered()
  -- if not self.render_enabled then return end

  -- for light in tdengine.entity.iterate('PointLight') do
  --   self.lights.cpu_buffer:push(light:to_ctype())
  -- end
  -- self.lights:sync()

  self.timer = self.timer or Timer:new(1)
  if self.timer:update() then
    self.sdf_instances.cpu_buffer:fast_clear()

    -- for i = 1, 10 do
      -- self:draw_circle(tdengine.math.random_float(0, 100), 10, 20, tdengine.colors.indian_red)
    -- end
    self:draw_circle(0, 10, 20, 1.0, tdengine.colors.indian_red)
    self.sdf_instances:sync()

    
    self.timer:reset()
  end


  self.sdf_instances.cpu_buffer:fast_clear()

  -- for i = 1, 10 do
    -- self:draw_circle(tdengine.math.random_float(0, 100), 10, 20, tdengine.colors.indian_red)
  -- end
  self:draw_circle(0, 10, 20, tdengine.math.timed_sin(1, 0, 2 * tdengine.math.pi), tdengine.colors.indian_red)
  self.sdf_instances:sync()


  self.bindings = GpuBufferBinding:new({
    vertex = {
      self.sdf_vertices.gpu_buffer:to_ctype(),
      self.sdf_instances.gpu_buffer:to_ctype(),
    },
    uniforms = {
      {
        uniform = self.uniforms.shape,
        value = Sdf.Circle
      }
    }
  })

  -- begin a render pass
  tdengine.gpu.begin_render_pass(self.command_buffer, self.render_pass)
  tdengine.gpu.bind_pipeline(self.command_buffer, self.pipeline)
  tdengine.gpu.apply_bindings(self.command_buffer, self.bindings)
  tdengine.gpu.set_world_space(self.command_buffer, true)
  tdengine.gpu.set_camera(self.command_buffer, tdengine.editor.find('EditorCamera').offset:to_ctype())
  tdengine.gpu.command_buffer_draw(self.command_buffer, GpuDrawCall:new({
    mode = GpuDrawMode.Instance,
    vertex_offset = 0,
    num_vertices = 6,
    num_instances = self.sdf_instances:size(),
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
