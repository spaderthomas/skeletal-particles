PostProcess = tdengine.subsystem.define('PostProcess')

tdengine.enum.define(
  'BloomMode',
  {
    Filter = 0,
    Blur = 1,
    Combine = 2,
  }
)

function PostProcess:init()
  
end

function PostProcess:on_render_scene()
  self:render_chromatic_aberration()
  self:render_bloom()
  self:render_scanlines()

   
  local unprocessed_target = tdengine.gpu.find_read_target('scene')
	local processed_target = tdengine.gpu.find_write_target('post_process')
	tdengine.ffi.gpu_blit_target(tdengine.gpu.find_command_buffer('post_process'), unprocessed_target, processed_target)

  local native_frame = tdengine.gpu.find_render_target('post_process')
	local output_frame = tdengine.gpu.find_write_target('output')
	tdengine.ffi.gpu_blit_target(tdengine.gpu.find_command_buffer('post_process'), native_frame, output_frame)

end


function PostProcess:render_chromatic_aberration()
  tdengine.gpu.bind_render_pass('scene')
  tdengine.ffi.set_active_shader('chromatic_aberration')
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)
  tdengine.ffi.set_uniform_texture('unprocessed_frame', tdengine.gpu.find_read_texture('scene'))
  tdengine.ffi.push_fullscreen_quad()
  tdengine.gpu.submit_render_pass('scene')

  tdengine.gpu.apply_ping_pong('scene')
end 

function PostProcess:render_scanlines()
  tdengine.gpu.bind_render_pass('scene')
  tdengine.ffi.set_active_shader('scanline')
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)
  tdengine.ffi.set_uniform_texture('unprocessed_frame', tdengine.gpu.find_read_texture('scene'))
  tdengine.ffi.push_fullscreen_quad()
  tdengine.gpu.submit_render_pass('scene')

  tdengine.gpu.apply_ping_pong('scene')
end

function PostProcess:render_bloom()
  tdengine.gpu.bind_render_pass('bloom_filter')
  tdengine.ffi.set_active_shader('bloom')
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)

  tdengine.ffi.set_uniform_enum('mode', tdengine.enums.BloomMode.Filter)
  tdengine.ffi.set_uniform_texture('unfiltered_frame', tdengine.gpu.find_read_texture('scene'))
  tdengine.ffi.push_fullscreen_quad()
  tdengine.gpu.submit_render_pass('bloom_filter')


  local blur_pass = tdengine.gpu.find_render_pass('bloom_blur')
  blur_pass.render_target = tdengine.gpu.find_render_target('bloom_b')
  blur_pass.ping_pong = tdengine.gpu.find_render_target('bloom_a')

  local num_bloom_passes = 4;
  for i = 1, num_bloom_passes do
    tdengine.gpu.bind_render_pass('bloom_blur')
    tdengine.ffi.set_active_shader('bloom')
    tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)

    tdengine.ffi.set_uniform_enum('mode', tdengine.enums.BloomMode.Blur)
    tdengine.ffi.set_uniform_texture('bloomed_frame', blur_pass.ping_pong.color_buffer)
    tdengine.ffi.push_fullscreen_quad()
    tdengine.gpu.submit_render_pass('bloom_blur')

    tdengine.gpu.apply_ping_pong('bloom_blur')
  end

  tdengine.gpu.bind_render_pass('scene')
  tdengine.ffi.set_active_shader('bloom')
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)
  tdengine.ffi.set_uniform_enum('mode', tdengine.enums.BloomMode.Combine)
  tdengine.ffi.set_uniform_texture('unfiltered_frame', tdengine.gpu.find_read_texture('scene'))
  tdengine.ffi.set_uniform_texture('bloomed_frame', tdengine.gpu.find_read_texture('bloom_blur'))
  tdengine.ffi.push_fullscreen_quad()
  tdengine.gpu.submit_render_pass('scene')

  tdengine.gpu.apply_ping_pong('scene')


  -- tdengine.gpu.bind_render_pass('bloom_combine')
  -- tdengine.ffi.set_active_shader('bloom')
  -- tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)

  -- tdengine.ffi.set_uniform_enum('mode', tdengine.enums.BloomMode.Combine)
  -- tdengine.ffi.set_uniform_texture('unfiltered_frame', tdengine.gpu.find_read_texture('scene'))
  -- tdengine.ffi.set_uniform_texture('bloomed_frame', tdengine.gpu.find_read_texture('bloom_blur'))
  -- tdengine.ffi.push_fullscreen_quad()
  -- tdengine.gpu.submit_render_pass('bloom_combine')
end

