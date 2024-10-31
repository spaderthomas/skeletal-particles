local App = tdengine.define_app()

function App:init()
	self.upscaled_view = 'Game (2x)'
	self.native_resolution = tdengine.vec2(426, 240)

	self.window_flags = tdengine.enum.bitwise_or(
		tdengine.enums.WindowFlags.Windowed,
		tdengine.enums.WindowFlags.Border
	)
end

function App:on_init_game()
	tdengine.ffi.create_window('Skeletal Particles', self.native_resolution.x, self.native_resolution.y, self.window_flags)

	local icon_path = tdengine.ffi.resolve_format_path('image', 'logo/icon.png'):to_interned()
	tdengine.ffi.set_window_icon(icon_path)

	tdengine.ffi.set_target_fps(144)

	local render_targets = {
		scene = tdengine.gpu.add_render_target('scene', self.native_resolution.x, self.native_resolution.y),
		ping_pong = tdengine.gpu.add_render_target('ping_pong', self.native_resolution.x, self.native_resolution.y),
		post_process = tdengine.gpu.add_render_target('post_process', self.native_resolution.x, self.native_resolution.y),
		bloom_a = tdengine.gpu.add_render_target('bloom_a', self.native_resolution.x, self.native_resolution.y),
		bloom_b = tdengine.gpu.add_render_target('bloom_b', self.native_resolution.x, self.native_resolution.y),
	}

	-- Command buffers
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

	-- Render passes
	tdengine.gpu.add_render_pass('scene', command_buffers.scene, render_targets.scene, render_targets.ping_pong, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('fluid', command_buffers.scene, render_targets.scene, render_targets.ping_pong, tdengine.enums.GpuLoadOp.None)
	tdengine.gpu.add_render_pass('post_process', command_buffers.post_process, render_targets.post_process, nil, tdengine.enums.GpuLoadOp.None)
	tdengine.gpu.add_render_pass('bloom_filter', command_buffers.post_process, render_targets.bloom_a, nil, tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('bloom_blur', command_buffers.post_process, render_targets.bloom_b, render_targets.bloom_a, tdengine.enums.GpuLoadOp.None)
	tdengine.gpu.add_render_pass('bloom_combine', command_buffers.post_process, render_targets.post_process, nil, tdengine.enums.GpuLoadOp.None)

end

function App:on_start_game()
	tdengine.find_entity_editor('EditorUtility').style.grid.size = 12

	tdengine.editor.find('DialogueEditor').hidden = true

  local upscaled_view = GameView:new(self.upscaled_view, tdengine.enums.GameViewSize.ExactSize, tdengine.app.native_resolution:scale(3), tdengine.enums.GameViewPriority.Main)
  tdengine.editor.find('GameViewManager'):add_view(upscaled_view)

	tdengine.ffi.use_editor_layout('skeletal-240')
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