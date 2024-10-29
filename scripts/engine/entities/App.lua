local App = tdengine.define_app()

function App:init()
	self.renderer = {
		targets = {
			scene = 0,
			freeze = 0,
			ping_pong = 0,
			post_processing = 0,
		},
		command_buffers = {
			scene = 0,
			post_processing = 0
		},
		passes = {
			scene = 0,
			post_processing = 0
		}
	}

	self.native_resolution = tdengine.vec2(1920, 1080)

	self.window_flags = tdengine.enum.bitwise_or(
		tdengine.enums.WindowFlags.Windowed,
		tdengine.enums.WindowFlags.Border
	)

	self.editor = {
		post_processing = imgui.extensions.TableEditor({})
	}
end

function App:on_init_game()
	tdengine.ffi.create_window('tdengine', self.native_resolution.x, self.native_resolution.y, self.window_flags)

	local icon_path = tdengine.ffi.resolve_format_path('image', 'logo/icon.png'):to_interned()
	tdengine.ffi.set_window_icon(icon_path)


	local render_targets = {
		scene = tdengine.gpu.add_render_target('scene', self.native_resolution.x, self.native_resolution.y),
		freeze = tdengine.gpu.add_render_target('freeze', self.native_resolution.x, self.native_resolution.y),
		ping_pong = tdengine.gpu.add_render_target('ping_pong', self.native_resolution.x, self.native_resolution.y),
		post_process = tdengine.gpu.add_render_target('post_process', self.native_resolution.x, self.native_resolution.y),
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
	tdengine.gpu.add_render_pass('scene', command_buffers.scene, render_targets.scene, render_targets.ping_pong,
		tdengine.enums.GpuLoadOp.Clear)
	tdengine.gpu.add_render_pass('fluid', command_buffers.scene, render_targets.scene, render_targets.ping_pong,
		tdengine.enums.GpuLoadOp.None)
	tdengine.gpu.add_render_pass('post_process', command_buffers.post_process, render_targets.post_process, nil,
		tdengine.enums.GpuLoadOp.None)
end

function App:on_swapchain_ready()
	if tdengine.is_packaged_build then
		--local swapchain = tdengine.ffi.gpu_acquire_swapchain()
		--tdengine.ffi.blit_render_target(self.renderer.command_buffers.post_processing, self.renderer.targets.scene, swapchain)
	end

	tdengine.ffi.render_imgui()
end

function App:on_editor_play()
	-- tdengine.find_entity('GameState'):enter_state(tdengine.enums.GameMode.Game)

	-- Warp the player to a specially-tagged PlayerStart marker, else random door, else (0, 0)
	-- local player = tdengine.find_entity('Player')

	-- local marker = tdengine.find_entity_by_tag('PlayerStart')
	-- local door = tdengine.find_entity('Door')

	-- if marker then
	--   marker:warp_entity(player)
	-- elseif door then
	--   player:find_component('Collider'):set_position(door:get_target())
	-- else
	--   player:find_component('Collider'):set_position(tdengine.vec2(0, 0))
	-- end
end

function App:on_editor_stop()
	-- tdengine.find_entity('GameState'):enter_state(tdengine.enums.GameMode.MainMenu)

	-- -- Why do we enable the game channel when we're stopping the game? Because, probably confusingly,
	-- -- the "game" input channel just refers to any input in the game view. That could be when you're
	-- -- actually playing the game, but also when you're dragging stuff around in the editor.
	-- --
	-- -- If, while playing the game, we were using a different channel (e.g. GUI), and we did not
	-- -- reset this, we could enter the editor with the game channel disabled. That'd mean all editor
	-- -- controls would not work, which would be bad.
	-- tdengine.input.solo_channel(tdengine.input.channels.game)
end

function App:on_main_menu()
	-- self:Skeleton() -- @refactor
	-- self:SkeletalAnimation()
end

function App:on_end_frame()
end

-- function MainMenu:Skeleton()
--   if imgui.BeginMenu('Skeleton') then
-- 	local skeleton_editor = tdengine.find_entity('SkeletonEditor')
-- 	if skeleton_editor then
-- 	  if imgui.BeginMenu('Open') then
-- 		local skeleton_dir = tdengine.ffi.resolve_named_path('skeletons'):to_interned()
-- 		local skeletons = tdengine.scandir(skeleton_dir)
-- 		for index, name in pairs(skeletons) do
-- 		  skeletons[index] = string.gsub(name, '.lua', '')
-- 		end
-- 		table.sort(skeletons)

-- 		for index, skeleton in pairs(skeletons) do
-- 		  if imgui.MenuItem(skeleton) then
-- 			skeleton_editor:load_skeleton(skeleton)
-- 		  end
-- 		end

-- 		imgui.EndMenu()
-- 	  end

-- 	  if imgui.MenuItem('Save') then
-- 		skeleton_editor:save_skeleton()
-- 	  end

-- 	end

-- 	imgui.EndMenu()
--   end
-- end


-- function MainMenu:SkeletalAnimation()
--   if imgui.BeginMenu('Skeletal Animation') then
-- 	local skeleton_viewer = tdengine.find_entity('SkeletonViewer')
-- 	if skeleton_viewer then
-- 	  local directory = tdengine.ffi.resolve_named_path('skeletal_animations'):to_interned()
-- 	  local animations = tdengine.scandir(directory)
-- 	  for index, name in pairs(animations) do
-- 		animations[index] = string.gsub(name, '.lua', '')
-- 	  end
-- 	  table.sort(animations)

-- 	  for index, animation in pairs(animations) do
-- 		if imgui.MenuItem(animation) then
-- 		  skeleton_viewer:load_animation(animation)
-- 		end
-- 	  end
-- 	end

-- 	imgui.EndMenu()
--   end
-- end
