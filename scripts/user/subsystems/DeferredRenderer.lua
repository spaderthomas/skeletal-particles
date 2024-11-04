DeferredRenderer = tdengine.subsystem.define('DeferredRenderer')

function DeferredRenderer:init()
  self.max_lights = 16;
  self.light_ssbo = nil
  self.lights = ffi.new('Light [16]')


end

function DeferredRenderer:on_start_game()
  self.light_ssbo = tdengine.ffi.gpu_create_buffer();
  tdengine.ffi.gpu_zero_buffer(self.light_ssbo, self.max_lights * ffi.sizeof('Light'))
end

function DeferredRenderer:on_scene_rendered()
  local num_lights = 0
  for light in tdengine.entity.iterate('PointLight') do
    if num_lights >= self.max_lights then
      log.warn('Maximum number of lights reached')
      break
    end

    self.lights[num_lights] = light:to_ctype()
    num_lights = num_lights + 1
  end

  tdengine.ffi.gpu_sync_buffer(self.light_ssbo, self.lights, ffi.sizeof(self.lights))

  tdengine.gpu.bind_render_pass('light_map')
  tdengine.ffi.gpu_bind_buffer_base (self.light_ssbo, 0)
  tdengine.ffi.set_active_shader('light_map')
  tdengine.ffi.set_uniform_i32('num_lights', num_lights)
  tdengine.ffi.push_fullscreen_quad()
  tdengine.gpu.submit_render_pass('light_map')
  
  self.apply_lighting = SimplePostProcess:new()
  self.apply_lighting:set_render_pass('light_scene')
  self.apply_lighting:set_shader('apply_lighting')
  self.apply_lighting:add_uniform('light_map', 'light_map', tdengine.enums.UniformKind.Texture)
  self.apply_lighting:add_uniform('color_buffer', 'color', tdengine.enums.UniformKind.Texture)
  self.apply_lighting:add_uniform('normal_buffer', 'normals', tdengine.enums.UniformKind.Texture)
  self.apply_lighting:add_uniform('editor', 'scene', tdengine.enums.UniformKind.RenderPassTexture)
  self.apply_lighting:add_uniform('num_lights', num_lights, tdengine.enums.UniformKind.I32)
  self.apply_lighting:add_ssbo(0, self.light_ssbo)

  self.apply_lighting:render()

  tdengine.subsystem.find('PostProcess'):upscale()
end