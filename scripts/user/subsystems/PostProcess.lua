PostProcess = tdengine.subsystem.define('PostProcess')

function PostProcess:init()
  
end

function PostProcess:on_scene_rendered()
  tdengine.gpu.bind_render_pass('post_process')

  tdengine.ffi.set_active_shader('scanline')
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)

	
  tdengine.ffi.set_uniform_texture('new_frame', tdengine.gpu.find_render_pass('scene').render_target.color_buffer)
	
  tdengine.ffi.push_quad(0, tdengine.app.native_resolution.y, tdengine.app.native_resolution.x, tdengine.app.native_resolution.y, nil, 1);
  
  tdengine.gpu.submit_render_pass('post_process')

end
