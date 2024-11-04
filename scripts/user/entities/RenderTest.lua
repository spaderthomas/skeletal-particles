RenderTest = tdengine.entity.define('RenderTest')

function RenderTest:init()
end

function RenderTest:update()
end

function RenderTest:draw()
  tdengine.gpu.bind_render_pass('color')
  tdengine.editor.find('EditorUtility'):draw_grid()
  tdengine.ffi.set_layer(10000)
  tdengine.ffi.draw_circle_sdf(100, 0, 20, tdengine.colors.red:to_vec4(), 2)
  tdengine.gpu.submit_render_pass('color')

  tdengine.gpu.bind_render_pass('normals')
  tdengine.ffi.set_world_space(true)
  self:draw_sdf_normal(100, 0, 20, 2)
  tdengine.gpu.submit_render_pass('normals')

end

function RenderTest:draw_sdf_normal(px, py, radius, edge_thickness)
	tdengine.ffi.set_active_shader("sdf_normal");
	tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles);
	tdengine.ffi.set_uniform_vec2("point", ffi.new('Vector2', px, py));
	tdengine.ffi.set_uniform_f32("edge_thickness", edge_thickness);
	tdengine.ffi.set_uniform_enum("shape", tdengine.enums.Sdf.Circle);
	tdengine.ffi.set_uniform_f32("radius", radius);

	tdengine.ffi.push_quad(
    px - radius, py + radius,
    2 * radius, 2 * radius,
    nil,
    1.0);
end



local PointLight = tdengine.entity.define('PointLight')
PointLight:include_ctype('Light')

PointLight.components = {
  'Collider'
}

PointLight.editor_fields = {
  'radial_falloff',
  'angular_falloff',
  'intensity'
} 

function PointLight:init(params)
  self.radial_falloff = params.radial_falloff or 0.5
  self.angular_falloff = params.radial_falloff or 0.5
  self.intensity = params.intensity or 0.5 
  
  local collider = self:find_component('Collider')
  collider:set_shape(tdengine.enums.ColliderShape.Circle)
  collider.impl:set_radius(12)
end


function PointLight:draw()
end  
 