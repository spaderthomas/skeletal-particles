local GameView = tdengine.editor.define('GameView')

function GameView:init()
  self.game_area = {
    position = tdengine.vec2(),
    dimension = tdengine.vec2(),
  }

  self.fill_window = false
end

function GameView:update()
  if self.fill_window then
    self:calc_resolution()
    self:render_main_view(self.game_area.dimension)
  else
    self:set_resolution(tdengine.app.native_resolution)
    self:render_view(tdengine.app.native_resolution, 'Game')
  end
end

function GameView:calc_resolution()
  local cx, _ = imgui.GetContentRegionAvail()
  local resolution = tdengine.vec2(cx, math.floor(cx * 9 / 16))
  self:set_resolution(resolution)
end

function GameView:set_resolution(resolution)
  imgui.PushStyleVar_2(ffi.C.ImGuiStyleVar_WindowPadding, 0, 0)
  tdengine.editor.begin_window('Game')

  self.game_area.dimension = resolution:copy()
  tdengine.window.set_game_area_size(self.game_area.dimension)

  local wx, wy = imgui.GetCursorScreenPos()
  self.game_area.position.x = wx
  self.game_area.position.y = wy
  tdengine.window.set_game_area_position(self.game_area.position)

  self.focus = imgui.IsWindowFocused()
  self.hover = imgui.IsWindowHovered()
  ffi.C.set_game_focus(self.focus and self.hover)

  tdengine.editor.end_window()
  imgui.PopStyleVar()
end

function GameView:render_view(resolution, window_name)
  imgui.PushStyleVar_2(ffi.C.ImGuiStyleVar_WindowPadding, 0, 0)
  tdengine.editor.begin_window(window_name)

  local texture = tdengine.gpu.find_render_pass('scene').render_target.color_buffer
  imgui.Image(
    texture,
    imgui.ImVec2(resolution.x, resolution.y),
    imgui.ImVec2(0, 1), imgui.ImVec2(1, 0))

  tdengine.editor.end_window()
  imgui.PopStyleVar()
end