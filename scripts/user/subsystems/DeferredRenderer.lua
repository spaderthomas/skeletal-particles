

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

  self.lights = BackedGpuBuffer:new('Light', self.max_lights, tdengine.gpus.find_resource(GpuResourceKind.StorageBuffer, StorageBuffer.Lights))
  self.lights.gpu_buffer:zero()

  self.light_scene = ConfiguredPostProcess:new(
    tdengine.gpus.find_resource(GpuResourceKind.GraphicsPipeline,  RenderPass.LightScene),
    tdengine.gpus.find_resource(GpuResourceKind.DrawConfiguration, DrawConfiguration.LightScene)
  )
  self.visualize_light_map = ConfiguredPostProcess:new(
    tdengine.gpus.find_resource(GpuResourceKind.GraphicsPipeline,  RenderPass.VisualizeLightMap),
    tdengine.gpus.find_resource(GpuResourceKind.DrawConfiguration, DrawConfiguration.VisualizeLightMap)
  )

  -- local command_buffers = {}

  -- local buffer_descriptor = ffi.new('GpuCommandBufferDescriptor')
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
