SdfShape = tdengine.entity.define('SdfShape')

SdfShape.components = {
  'Collider'
}

SdfShape.editor_fields = {
  'shape',
  'shape_data',
  'edge_thickness',
}

function SdfShape:init(params)
  self.shape = tdengine.enum.load(params.shape) or tdengine.enums.Sdf.Circle
  self.shape_data = params.shape_data or {

  }

  self.edge_thickness = params.edge_thickness or 2
  self.color = tdengine.color(params.color)
end

function SdfShape:draw()
  self:draw_to('color', 'sdf')
  self:draw_to('scene', 'sdf')
  self:draw_to('normals', 'sdf_normal')
end

function SdfShape:draw_to(render_pass, shader)
  tdengine.gpu.bind_render_pass(render_pass)
  tdengine.ffi.set_active_shader(shader)
  tdengine.ffi.set_world_space(true)
	tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles);
  tdengine.ffi.set_uniform_f32('edge_thickness', self.edge_thickness)
	tdengine.ffi.set_uniform_enum("shape", self.shape);

  local p = self:find_component('Collider'):get_position()
  local s = self:find_component('Collider'):get_dimension()

  if self.shape == tdengine.enums.Sdf.Box then
    tdengine.ffi.set_uniform_vec2('point', ffi.new('Vector2', p.x, p.y))
    tdengine.ffi.set_uniform_vec2('size', ffi.new('Vector2', s.x, s.y))
    tdengine.ffi.push_quad(
      p.x, p.y,
      s.x, s.y,
      nil,
      1.0
    )
  elseif self.shape == tdengine.enums.Sdf.OrientedBox then
    local center_a = ffi.new('Vector2', p.x, p.y)
    local center_b = ffi.new('Vector2', p.x + s.x, p.y - s.y)
    local thickness = 8

    tdengine.ffi.set_uniform_vec2('center_a', center_a)
    tdengine.ffi.set_uniform_vec2('center_b', center_b)
    tdengine.ffi.set_uniform_f32('thickness', thickness)
    tdengine.ffi.push_quad(
      p.x - thickness / 2, p.y + thickness / 2,
      s.x + thickness, s.y + thickness,
      nil,
      1.0
    )

  elseif self.shape == tdengine.enums.Sdf.Circle then
    local radius = math.min(s.x, s.y)

    tdengine.ffi.set_uniform_vec2("point", ffi.new('Vector2', p.x, p.y));
    tdengine.ffi.set_uniform_f32("edge_thickness", self.edge_thickness);
    tdengine.ffi.set_uniform_enum("shape", tdengine.enums.Sdf.Circle);
    tdengine.ffi.set_uniform_f32("radius", radius);
  
    tdengine.ffi.push_quad(
      p.x - radius, p.y + radius,
      2 * radius, 2 * radius,
      nil,
      1.0);

    local renderer = tdengine.subsystem.find('DeferredRenderer')
    renderer:draw_circle(SdfCircle:new(p.x, p.y, radius, self.edge_thickness))
  end

  tdengine.gpu.submit_render_pass(render_pass)
end