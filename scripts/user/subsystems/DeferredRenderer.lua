CpuBuffer = tdengine.class.define('CpuBuffer')

function CpuBuffer:init(ctype, capacity)
  self.size = 0
  self.capacity = capacity
  self.ctype = ctype
  self.data = ffi.new(string.format('%s [%d]', ctype, capacity))
end

function CpuBuffer:push(element)
  if self.size == self.capacity then
    dbg()
  end

  self.data[self.size] = element
  self.size = self.size + 1
end

function CpuBuffer:fast_clear()
  self.size = 0
end




BackedGpuBuffer = tdengine.class.define('BackedGpuBuffer')
function BackedGpuBuffer:init(ctype, capacity)
  self.ctype = ctype
  self.cpu_buffer = CpuBuffer:new(ctype, capacity)
  self.gpu_buffer = GpuBuffer:new(ctype, capacity)
end

function BackedGpuBuffer:sync()
  tdengine.ffi.gpu_sync_buffer_subdata(
  self.gpu_buffer.ssbo, self.cpu_buffer.data,
  ffi.sizeof(self.ctype) * self.cpu_buffer.size,
  0)
end



GpuBuffer = tdengine.class.define('GpuBuffer')

function GpuBuffer:init(ctype, capacity)
  self.ctype = ctype
  self.capacity = capacity
  self.ssbo = tdengine.ffi.gpu_create_buffer()
end

function GpuBuffer:zero()
  tdengine.ffi.gpu_zero_buffer(self.ssbo, self.capacity * ffi.sizeof(self.ctype))
end

function GpuBuffer:bind_base(base)
  tdengine.ffi.gpu_bind_buffer_base(self.ssbo, base)
end


GpuCommandBufferDescriptor = tdengine.class.metatype('GpuCommandBufferDescriptor')

GpuCommandBufferDescriptor.editor_fields = {
  'num_vertex_attributes',
  'max_vertices',
  'num_vertex_attributes',

}

function GpuCommandBufferDescriptor:init(params)
  self.num_vertex_attributes = params.num_vertex_attributes
end


DeferredRenderer = tdengine.subsystem.define('DeferredRenderer')

function DeferredRenderer:init()
  self.render_enabled = true
  self.max_lights = 16;
  self.lights = nil
  self.sdf_buffer_length = 1024
  self.shape_buffers = {}
  self.apply_lighting = SimplePostProcess:new()
  self.visualize_light_map = SimplePostProcess:new()
end

function DeferredRenderer:on_start_game()
  self.shape_buffers = {
    circle = BackedGpuBuffer:new('SdfCircle', self.sdf_buffer_length)
  }

  self.lights = BackedGpuBuffer:new('Light', self.max_lights)
  self.lights.gpu_buffer:zero()

  self.apply_lighting:set_render_pass('light_scene')
  self.apply_lighting:set_shader('apply_lighting')
  self.apply_lighting:add_uniform('light_map', 'light_map', tdengine.enums.UniformKind.Texture)
  self.apply_lighting:add_uniform('color_buffer', 'color', tdengine.enums.UniformKind.Texture)
  self.apply_lighting:add_uniform('normal_buffer', 'normals', tdengine.enums.UniformKind.Texture)
  self.apply_lighting:add_uniform('editor', 'scene', tdengine.enums.UniformKind.RenderPassTexture)
  self.apply_lighting:add_uniform('num_lights', 0, tdengine.enums.UniformKind.I32)
  self.apply_lighting:add_ssbo(0, self.lights.gpu_buffer.ssbo)

  self.visualize_light_map = SimplePostProcess:new()
  self.visualize_light_map:set_render_pass('light_map')
  self.visualize_light_map:set_shader('light_map')
  self.visualize_light_map:add_uniform('num_lights', 0, tdengine.enums.UniformKind.I32)
  self.visualize_light_map:add_ssbo(0, self.lights.gpu_buffer.ssbo)

  self.command_buffers = {}
  local buffer_descriptor = ffi.new('GpuCommandBufferDescriptor')

  self.render_passes = {

  }

    -- self.shapes = SimplePostProcess:new()
  -- self.visualize_light_map:set_render_pass('light_map')
  -- self.visualize_light_map:set_shader('light_map')
  -- self.visualize_light_map:add_uniform('num_lights', 0, tdengine.enums.UniformKind.I32)
  -- self.visualize_light_map:add_ssbo(0, self.lights.gpu_buffer.ssbo)

end

function DeferredRenderer:on_begin_frame()
  for shape_buffer in tdengine.iterator.values(self.shape_buffers) do
    shape_buffer.cpu_buffer:fast_clear()
  end

  self.lights.cpu_buffer:fast_clear()
end

function DeferredRenderer:on_scene_rendered()
  if not self.render_enabled then return end

  for light in tdengine.entity.iterate('PointLight') do
    self.lights.cpu_buffer:push(light:to_ctype())
  end

  self.lights:sync()
 

  self.visualize_light_map:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)
  self.visualize_light_map:render()

  self.apply_lighting:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)
  self.apply_lighting:render()

  tdengine.subsystem.find('PostProcess'):upscale()
end

function DeferredRenderer:draw_circle(sdf_circle)
  self.shape_buffers.circle.cpu_buffer:push(sdf_circle)
end

