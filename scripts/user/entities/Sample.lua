SampleEntity = tdengine.entity.define('SampleEntity')

SampleEntity.components = {
  'Collider'
}


function SampleEntity:init() 
  self.__draw_shapes = false
end

function SampleEntity:late_init()
end 

function SampleEntity:deinit()
end

function SampleEntity:play()
  self.positions = {}
  self.jitters = {}
  for i = 0, 20 do
    table.insert(self.positions, tdengine.math.random_float(0, 400))
    table.insert(self.jitters, tdengine.math.random_float(0, 1.0))
  end
end

function SampleEntity:stop()
end

function SampleEntity:update()
end

function SampleEntity:draw()
  self:draw_shapes()

  local prepared_text = tdengine.ffi.prepare_text('best', 0, 0, 'tiny5')
  tdengine.ffi.draw_prepared_text(prepared_text)

  tdengine.ffi.draw_quad(100, 0, 100, 52, tdengine.colors.white:to_vec4())

  tdengine.ffi.draw_image_ex('animal-well-320-180.png', 0, 0, 320, 180, 1)

  for i = 1, 20 do
    tdengine.ffi.set_layer(i)
    local yoff = tdengine.math.ranged_sin(tdengine.elapsed_time * self.jitters[i], 0.0, 20.0)
    tdengine.ffi.draw_circle_sdf(self.positions[i], 50 + yoff, 8, tdengine.colors.zomp:to_vec4(), 2)
  end


end
 
function SampleEntity:on_load_game()
  -- This is called directly after your fields have been deserialized and assigned.
end

function SampleEntity:on_save_game()
  -- This is called right before your fields are serialized
end


function SampleEntity:draw_shapes()
  if not self.__draw_shapes then return end
  tdengine.ffi.set_world_space(true)
  tdengine.ffi.set_layer(100)

  tdengine.ffi.draw_circle_sdf(0, -100, 100, tdengine.colors.zomp:to_vec4(), 2)
  -- tdengine.ffi.draw_circle_l(tdengine.vec2(0, -100), 100, tdengine.colors.zomp, 2)
  tdengine.ffi.draw_quad(100, 0, 200, 200, tdengine.colors.charcoal:to_vec4())
  --tdengine.ffi.draw_quad_l(tdengine.vec2(100, 0), tdengine.vec2(200, 200), tdengine.colors.charcoal)
  tdengine.ffi.draw_line(500, -200, 300, 0, 2, tdengine.colors.indian_red:to_vec4())
  tdengine.ffi.draw_line(300, -200, 500, 0, 2, tdengine.colors.indian_red:to_vec4())
  tdengine.ffi.draw_image_size('studio-logo.png', 500, 0, 200, 200)
end