local App = tdengine.define_app()

function App:init()
	self.upscaled_view = 'Game (2x)'
	self.native_resolution = tdengine.vec2(320, 180)
	self.output_resolution = tdengine.vec2(1280, 720)
	self.gbuffer_resolution = tdengine.vec2(1024, 576)

	self.window_flags = tdengine.enum.bitwise_or(
		tdengine.enums.WindowFlags.Windowed,
		tdengine.enums.WindowFlags.Border
	)
end

function App:on_init_game()
	tdengine.ffi.create_window('Skeletal Particles', self.native_resolution.x, self.native_resolution.y, self.window_flags)
	tdengine.ffi.set_window_icon(tdengine.ffi.resolve_format_path('image', 'logo/icon.png'):to_interned())
	tdengine.ffi.set_target_fps(144)

	self:build_renderer()
	self:build_deferred_renderer()
end


function App:build_renderer()
	local render_targets = {
		scene          = tdengine.gpu.add_render_target('scene',          self.native_resolution.x, self.native_resolution.y),
		ping_pong      = tdengine.gpu.add_render_target('ping_pong',      self.native_resolution.x, self.native_resolution.y),
		post_process_a = tdengine.gpu.add_render_target('post_process_a', self.output_resolution.x, self.output_resolution.y),
		post_process_b = tdengine.gpu.add_render_target('post_process_b', self.output_resolution.x, self.output_resolution.y),
		bloom_a        = tdengine.gpu.add_render_target('bloom_a',        self.output_resolution.x, self.output_resolution.y),
		bloom_b        = tdengine.gpu.add_render_target('bloom_b',        self.output_resolution.x, self.output_resolution.y),
		output         = tdengine.gpu.add_render_target('output',         self.gbuffer_resolution.x, self.gbuffer_resolution.y),
	}

	local command_buffers = {}

	local buffer_descriptor = ffi.new('GpuCommandBufferDescriptor')
	buffer_descriptor.num_vertex_attributes = 3
	buffer_descriptor.max_vertices = 64 * 1024
	buffer_descriptor.max_draw_calls = 256
	buffer_descriptor.vertex_attributes = ffi.new('VertexAttribute[3]')
	buffer_descriptor.vertex_attributes[0].count = 3
	buffer_descriptor.vertex_attributes[0].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	buffer_descriptor.vertex_attributes[1].count = 4
	buffer_descriptor.vertex_attributes[1].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	buffer_descriptor.vertex_attributes[2].count = 2
	buffer_descriptor.vertex_attributes[2].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	command_buffers.scene = tdengine.gpu.add_command_buffer('scene', buffer_descriptor)

	buffer_descriptor.max_vertices = 600
	buffer_descriptor.max_draw_calls = 10
	command_buffers.post_process = tdengine.gpu.add_command_buffer('post_process', buffer_descriptor)
	command_buffers.fluid = tdengine.gpu.add_command_buffer('fluid', buffer_descriptor)

	tdengine.gpu.add_render_pass('scene',         command_buffers.scene,        render_targets.scene,          render_targets.ping_pong, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('output',        command_buffers.post_process, render_targets.output,         nil,                      tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('fluid',         command_buffers.scene,        render_targets.scene,          render_targets.ping_pong)
	tdengine.gpu.add_render_pass('post_process',  command_buffers.post_process, render_targets.post_process_a, render_targets.post_process_b)
	tdengine.gpu.add_render_pass('bloom_filter',  command_buffers.post_process, render_targets.bloom_a,        nil,                      tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('bloom_blur',    command_buffers.post_process, render_targets.bloom_b,        render_targets.bloom_a)
end

function App:build_deferred_renderer()
	local render_targets = {
		color   = tdengine.gpu.add_render_target('color',       self.native_resolution.x, self.native_resolution.y),
		normals = tdengine.gpu.add_render_target('normals',     self.native_resolution.x, self.native_resolution.y),
		light_map = tdengine.gpu.add_render_target('light_map', self.native_resolution.x, self.native_resolution.y),
		lit_scene = tdengine.gpu.add_render_target('lit_scene', self.native_resolution.x, self.native_resolution.y),
		upscaled = {
			color   = tdengine.gpu.add_render_target('upscaled_color',   self.gbuffer_resolution.x, self.gbuffer_resolution.y),
			normals = tdengine.gpu.add_render_target('upscaled_normals', self.gbuffer_resolution.x, self.gbuffer_resolution.y),
			lit_scene = tdengine.gpu.add_render_target('upscaled_lit_scene', self.gbuffer_resolution.x, self.gbuffer_resolution.y),
		}
}

	local command_buffers = {
		color = nil,
		normals = nil,
		upscale = nil,
	}

	local buffer_descriptor = ffi.new('GpuCommandBufferDescriptor')
	buffer_descriptor.num_vertex_attributes = 3
	buffer_descriptor.max_vertices = 64 * 1024
	buffer_descriptor.max_draw_calls = 256
	buffer_descriptor.vertex_attributes = ffi.new('VertexAttribute[3]')
	buffer_descriptor.vertex_attributes[0].count = 3
	buffer_descriptor.vertex_attributes[0].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	buffer_descriptor.vertex_attributes[1].count = 4
	buffer_descriptor.vertex_attributes[1].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	buffer_descriptor.vertex_attributes[2].count = 2
	buffer_descriptor.vertex_attributes[2].kind = tdengine.enums.VertexAttributeKind.Float:to_number()
	command_buffers.color   = tdengine.gpu.add_command_buffer('color', buffer_descriptor)
	command_buffers.normals = tdengine.gpu.add_command_buffer('normals', buffer_descriptor)

	buffer_descriptor.max_vertices = 6
	buffer_descriptor.max_draw_calls = 1
	command_buffers.upscale = tdengine.gpu.add_command_buffer('upscale', buffer_descriptor)
	command_buffers.light_map = tdengine.gpu.add_command_buffer('light_map', buffer_descriptor)

	tdengine.gpu.add_render_pass('color',           command_buffers.color,   render_targets.color,            nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('normals',         command_buffers.normals, render_targets.normals,          nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('light_map',       command_buffers.light_map, render_targets.light_map,      nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('light_scene',     command_buffers.light_map, render_targets.lit_scene,      nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('upscale_color',   command_buffers.upscale, render_targets.upscaled.color,   nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('upscale_normals', command_buffers.upscale, render_targets.upscaled.normals, nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('upscale_lit_scene', command_buffers.upscale, render_targets.upscaled.lit_scene, nil, tdengine.enums.GpuLoadOp.Clear)
end

function App:on_start_game()
  tdengine.editor.find('SceneEditor'):load('render_test')

	tdengine.ffi.use_editor_layout('gbuffer')

	tdengine.editor.find('EditorUtility').style.grid.size = 12
	tdengine.editor.find('EditorUtility').enabled.grid = true

	tdengine.editor.find('DialogueEditor').hidden = true

	local game_views = tdengine.editor.find('GameViewManager')
  game_views:add_view(GameView:new(
		'Game',
		tdengine.gpu.find_render_target('scene'),
		tdengine.enums.GameViewSize.ExactSize, self.native_resolution,
		tdengine.enums.GameViewPriority.Standard))

  game_views:add_view(GameView:new(
		'Scene',
		tdengine.gpu.find_render_target('upscaled_lit_scene'),
		tdengine.enums.GameViewSize.ExactSize, self.gbuffer_resolution,
		tdengine.enums.GameViewPriority.Main))

	game_views:add_view(GameView:new(
		'Color Buffer',
		tdengine.gpu.find_render_target('upscaled_color'),
		tdengine.enums.GameViewSize.ExactSize, self.gbuffer_resolution,
		tdengine.enums.GameViewPriority.Standard))

	game_views:add_view(GameView:new(
		'Normal Buffer',
		tdengine.gpu.find_render_target('upscaled_normals'),
		tdengine.enums.GameViewSize.ExactSize, self.gbuffer_resolution,
		tdengine.enums.GameViewPriority.Standard))

	game_views:add_view(GameView:new(
		'Light Map',
		tdengine.gpu.find_render_target('light_map'),
		tdengine.enums.GameViewSize.ExactSize, self.gbuffer_resolution,
		tdengine.enums.GameViewPriority.Standard))
end


function App:on_end_frame()
	local skeleton_viewer = tdengine.entity.find('SkeletonViewer') 
	if skeleton_viewer then
		for system in tdengine.iterator.values(skeleton_viewer.animation.particle_systems) do
			tdengine.gpu.bind_render_pass('fluid')
			tdengine.ffi.lf_draw(system.handle)
			tdengine.gpu.submit_render_pass('fluid')
		end
	end
end
  
function App:on_render_scene()  
	tdengine.gpu.bind_render_pass('scene')
	tdengine.gpu.submit_render_pass('scene')
  tdengine.gpu.apply_ping_pong('scene')

	-- local unprocessed_target = tdengine.gpu.find_read_target('scene')
	-- local processed_target = tdengine.gpu.find_write_target('post_process')
	-- tdengine.ffi.gpu_blit_target(tdengine.gpu.find_command_buffer('post_process'), unprocessed_target, processed_target)
end 
 
function App:on_swapchain_ready()
	if tdengine.is_packaged_build then 
		--local swapchain = tdengine.ffi.gpu_acquire_swapchain()
		--tdengine.ffi.blit_render_target(self.renderer.command_buffers.post_processing, self.renderer.targets.scene, swapchain)
	end

	tdengine.ffi.render_imgui()
end