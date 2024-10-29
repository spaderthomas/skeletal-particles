local GameView = tdengine.editor.define('GameView')

function GameView:init()
  self.game_area = {
    position = tdengine.vec2(),
    dimension = tdengine.vec2(),
  }
end

function GameView:update()
  imgui.PushStyleVar_2(ffi.C.ImGuiStyleVar_WindowPadding, 0, 0)
  tdengine.editor.begin_window('Game')

  -- The game_area should take up all room on the X axis, and then fill to 16:9.
  local cx, _ = imgui.GetContentRegionAvail()
  self.game_area.dimension.x = cx
  self.game_area.dimension.y = math.floor(cx * 9 / 16)
  tdengine.window.set_game_area_size(self.game_area.dimension)

  -- It begins where the window begins, except we move down by the size of the tab header
  local wx, wy = imgui.GetCursorScreenPos()
  self.game_area.position.x = wx
  self.game_area.position.y = wy
  tdengine.window.set_game_area_position(self.game_area.position)

  -- Render the framebuffer
  self:render_to_editor_resolution()

  self.focus = imgui.IsWindowFocused()
  self.hover = imgui.IsWindowHovered()
  ffi.C.set_game_focus(self.focus and self.hover)

  imgui.PopStyleVar()
  tdengine.editor.end_window()
end

function GameView:render_to_editor_resolution()
  local texture = tdengine.gpu.find_render_pass('scene').render_target.color_buffer
  imgui.Image(
    texture,
    imgui.ImVec2(self.game_area.dimension.x, self.game_area.dimension.y), 
    imgui.ImVec2(0, 1), imgui.ImVec2(1, 0))
end