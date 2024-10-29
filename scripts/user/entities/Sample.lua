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
end

function SampleEntity:stop()
end

function SampleEntity:update()
end

function SampleEntity:draw()
  self:draw_shapes()
end
 
function SampleEntity:on_load_game()
  -- This is called directly after your fields have been deserialized and assigned.
end

function SampleEntity:on_save_game()
  -- This is called right before your fields are serialized
end


function SampleEntity:draw_shapes()
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
