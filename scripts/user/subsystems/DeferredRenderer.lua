

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

  self.light_scene = PreconfiguredPostProcess:new(
    tdengine.gpus.find(GraphicsPipeline.LightScene),
    tdengine.gpus.find(DrawConfiguration.LightScene)
  )
  self.visualize_light_map = PreconfiguredPostProcess:new(
    tdengine.gpus.find(GraphicsPipeline.VisualizeLightMap),
    tdengine.gpus.find(DrawConfiguration.VisualizeLightMap)
  )

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

  local vertex_layout_descriptor = {
    buffer_layouts = {
      {
        buffer = vertex_buffer,
        vertex_attributes = {
          {
            count = 2,
            kind = tdengine.enums.VertexAttributeKind.Float
          },
          {
            count = 2,
            kind = tdengine.enums.VertexAttributeKind.Float
          }
        }
      },
      {
        buffer = instance_buffer,
        vertex_attributes = {
          {
            count = 2,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 3,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 1,
            kind = tdengine.enums.VertexAttributeKind.Float,
            divisor = 1
          },
          {
            count = 1,
            kind = tdengine.enums.VertexAttributeKind.U32,
            divisor = 1
          }
        }
      }
    }
  }

  self.vertex_layout = tdengine.ffi.gpu_vertex_layout_create(GpuVertexLayoutDescriptor:new(vertex_layout_descriptor))

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

  -- local vao = alloc_vao()

  -- local vertex_buffer = alloc_array_buffer();
  -- fill_buffer(vertex_buffer, quad_verts)
  -- setup_vertex_attributes(vertex_buffer, attributes)

  -- local instance_buffer = alloc_array_buffer()
  -- fill_buffer(instance_buffer, some_bullshit_data)
  -- setup_vertex_attributes(instan)


  -- local command_buffers = {}

  -- local buffer_descriptor = ffi.new('GpuCommandBufferBatchedDescriptor')
	-- buffer_descriptor.num_vertex_attributes = 5
	-- buffer_descriptor.max_vertices = 64 * 1024
	-- buffer_descriptor.max_draw_calls = 256
	-- buffer_descriptor.vertex_attributes = ffi.new('VertexAttribute[5]')
	-- buffer_descriptor.vertex_attributes[0].count = 2 -- Position
	-- buffer_descriptor.vertex_attributes[0].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	-- buffer_descriptor.vertex_attributes[1].count = 2 -- UV
	-- buffer_descriptor.vertex_attributes[1].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	-- buffer_descriptor.vertex_attributes[2].count = 3 -- Color
	-- buffer_descriptor.vertex_attributes[2].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
  -- buffer_descriptor.vertex_attributes[3].count = 1 -- Rotation
	-- buffer_descriptor.vertex_attributes[3].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	-- buffer_descriptor.vertex_attributes[4].count = 1 -- Rotation
	-- buffer_descriptor.vertex_attributes[4].kind = tdengine.enums.VertexAttributeKind.U32:to_number()
  -- command_buffers.shapes = tdengine.gpu.add_command_buffer('shapes', buffer_descriptor)

	-- tdengine.gpu.add_render_pass('shapes', command_buffers.shapes, tdengine.gpu.find_render_target('color'), nil, tdengine.enums.GpuLoadOp.Clear)

  -- self.shapes = SimplePostProcess:new()
  -- self.shapes:set_render_pass('shapes')
  -- self.shapes:set_shader('shape')

end

function DeferredRenderer:on_begin_frame()
  -- for shape_buffer in tdengine.iterator.values(self.shape_buffers) do
  --   shape_buffer.cpu_buffer:fast_clear()
  -- end

  self.lights.cpu_buffer:fast_clear()
end

function DeferredRenderer:on_scene_rendered()
  if not self.render_enabled then return end

  for light in tdengine.entity.iterate('PointLight') do
    self.lights.cpu_buffer:push(light:to_ctype())
  end
  self.lights:sync()

  local pipeline = tdengine.gpus.find(GraphicsPipeline.Shape)
  tdengine.ffi.gpu_graphics_pipeline_bind(pipeline)

  tdengine.ffi.set_active_shader_ex(tdengine.gpus.find(Shader.Shape))
  tdengine.ffi.gpu_render_sdf(pipeline.command_buffer, self.vertex_layout, 1)


  -- update dynamic uniforms
  -- bind
  -- draw a fullscreen quad
  -- submit
  -- self.visualize_light_map:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)
  self.visualize_light_map:render()

  -- self.light_scene:render()
  -- self.apply_lighting:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)

  -- self.shapes:render()

  tdengine.subsystem.find('PostProcess'):upscale()
end

function DeferredRenderer:draw_circle(sdf_circle)
  -- self.shape_buffers.circle.cpu_buffer:push(sdf_circle)
end
