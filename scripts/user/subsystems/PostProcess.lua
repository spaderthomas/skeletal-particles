PostProcess = tdengine.subsystem.define('PostProcess')

tdengine.enum.define(
  'BloomMode',
  {
    Filter = 0,
    Blur = 1,
    Combine = 2,
    Map = 3,
    MapBlur = 4,
  }
)

function PostProcess:on_start_game()
  self.blit = SimplePostProcess:new()
  self.blit:set_render_pass('post_process')
  self.blit:set_shader('blit')
  self.blit:add_uniform('source', 'scene', tdengine.enums.UniformKind.RenderPassTexture)

  self.chromatic_aberration = SimplePostProcess:new()
  self.chromatic_aberration:set_render_pass('post_process')
  self.chromatic_aberration:set_shader('chromatic_aberration')
  self.chromatic_aberration:add_uniform('unprocessed_frame', 'post_process', tdengine.enums.UniformKind.RenderPassTexture)
  self.chromatic_aberration:add_uniform('blur_map', 'bloom_blur', tdengine.enums.UniformKind.RenderPassTexture)

  self.scanlines = SimplePostProcess:new()
  self.scanlines:set_render_pass('post_process')
  self.scanlines:set_shader('scanline')
  self.scanlines:add_uniform('unprocessed_frame', 'post_process', tdengine.enums.UniformKind.RenderPassTexture)
  self.scanlines:add_uniform('bloom_map', 'bloom_blur', tdengine.enums.UniformKind.RenderPassTexture)

  self.bloom_filter = SimplePostProcess:new()
  self.bloom_filter:set_render_pass('bloom_blur')
  self.bloom_filter:set_shader('bloom')
  self.bloom_filter:add_uniform('unfiltered_frame', 'post_process', tdengine.enums.UniformKind.RenderPassTexture)
  self.bloom_filter:add_uniform('mode', tdengine.enums.BloomMode.Filter, tdengine.enums.UniformKind.Enum)

  self.bloom_blur = SimplePostProcess:new()
  self.bloom_blur:set_render_pass('bloom_blur')
  self.bloom_blur:set_shader('bloom')
  self.bloom_blur:add_uniform('bloomed_frame', 'bloom_blur', tdengine.enums.UniformKind.RenderPassTexture)
  self.bloom_blur:add_uniform('mode', tdengine.enums.BloomMode.Blur, tdengine.enums.UniformKind.Enum)

  self.bloom_combine = SimplePostProcess:new()
  self.bloom_combine:set_render_pass('post_process')
  self.bloom_combine:set_shader('bloom')
  self.bloom_combine:add_uniform('unfiltered_frame', 'post_process', tdengine.enums.UniformKind.RenderPassTexture)
  self.bloom_combine:add_uniform('bloomed_frame', 'bloom_blur', tdengine.enums.UniformKind.RenderPassTexture)
  self.bloom_combine:add_uniform('mode', tdengine.enums.BloomMode.Combine, tdengine.enums.UniformKind.Enum)

  self.copy_output = SimplePostProcess:new()
  self.copy_output:set_render_pass('output')
  self.copy_output:set_shader('blit')
  self.copy_output:add_uniform('source', 'post_process', tdengine.enums.UniformKind.RenderPassTexture)

  self.visualize_bloom_map = SimplePostProcess:new()
  self.visualize_bloom_map:set_render_pass('post_process')
  self.visualize_bloom_map:set_shader('blit')
  self.visualize_bloom_map:add_uniform('source', 'bloom_blur', tdengine.enums.UniformKind.RenderPassTexture)

end

function PostProcess:post_process()
  self.chromatic_aberration:render()

  tdengine.ffi.gpu_clear_target(tdengine.gpu.find_read_target('bloom_blur'))
  self.bloom_filter:render()
  for bloom_index = 1, 4 do
    self.bloom_blur:render()
  end
  self.bloom_combine:render()


  self.scanlines:render()
end

function PostProcess:on_scene_rendered()
  self.blit:render()

  self:post_process()


  self.copy_output:render()
end





tdengine.enum.define(
  'UniformKind',
  {
    Texture = 0,
    Enum = 1,
    RenderPassTexture = 2,
  }
)

Uniform = tdengine.class.define('Uniform')
function Uniform:init(name, value, kind)
  self.name = name
  self.value = value
  self.kind = kind
end

function Uniform:bind()
  if self.kind == tdengine.enums.UniformKind.Texture then
    tdengine.ffi.set_uniform_texture(self.name, self.value)
  elseif self.kind == tdengine.enums.UniformKind.RenderPassTexture then
    tdengine.ffi.set_uniform_texture(self.name, tdengine.gpu.find_read_texture(self.value))
  elseif self.kind == tdengine.enums.UniformKind.Enum then
    tdengine.ffi.set_uniform_enum(self.name, self.value)
  end
end

SimplePostProcess = tdengine.class.define('SimplePostProcess')
function SimplePostProcess:init()
  self.render_pass = ''
  self.shader = ''
  self.uniforms = tdengine.data_types.Array:new()
end

function SimplePostProcess:add_uniform(name, value, kind)
  self.uniforms:add(Uniform:new(name, value, kind))
end

function SimplePostProcess:set_render_pass(render_pass)
  self.render_pass = render_pass
end

function SimplePostProcess:set_shader(shader)
  self.shader = shader
end

function SimplePostProcess:render()
  tdengine.gpu.bind_render_pass(self.render_pass)
  tdengine.ffi.set_active_shader(self.shader)
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)

  for uniform in self.uniforms:iterate_values() do
    uniform:bind()
  end

  ffi.C.push_quad(
    0, tdengine.app.output_resolution.y, 
    tdengine.app.output_resolution.x, tdengine.app.output_resolution.y, 
    nil, 
    1.0)

  tdengine.gpu.submit_render_pass(self.render_pass)

  tdengine.gpu.apply_ping_pong(self.render_pass)
end