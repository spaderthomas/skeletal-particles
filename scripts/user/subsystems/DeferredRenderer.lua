DeferredRenderer = tdengine.subsystem.define('DeferredRenderer')

function DeferredRenderer:init()
  self.max_lights = 16;
  self.light_ssbo = nil
  self.lights = ffi.new('Light [16]')
end

function DeferredRenderer:on_start_game()
  self.lights = tdengine.ffi.gpu_create_buffer();
  tdengine.ffi.gpu_zero_buffer(self.lights, self.max_lights * ffi.sizeof('Light'))
end

function DeferredRenderer:on_scene_rendered()
  for light in tdengine.entity.iterate('PointLight') do
    
  end
end