SdfRenderer = tdengine.class.define('SdfRenderer')

function SdfRenderer:init()
  self.vertex_buffer = BackedGpuBuffer:owned(
    'SdfVertex',
    1024,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Array,
      usage = GpuBufferUsage.Static
    }))

  self.instance_buffer = BackedGpuBuffer:owned(
    'SdfInstance',
    1024,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Array,
      usage = GpuBufferUsage.Static
    }))

  self.sdf_data = BackedGpuBuffer:owned(
    'float',
    1024,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Storage,
      usage = GpuBufferUsage.Dynamic
    }))

  self.sdf_combine_data = BackedGpuBuffer:owned(
    'u32',
    1024,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Storage,
      usage = GpuBufferUsage.Dynamic
    }))

  -- There's only one quad in the vertex buffer for SDF shapes. They're transformed in the
  -- vertex shader according to the instance data.
  local sdf_quad = {
    ffi.new('SdfVertex', { {-0.5, 0.5}, {-0.5, 0.5} }),
    ffi.new('SdfVertex', { {-0.5, -0.5}, {-0.5, -0.5} }),
    ffi.new('SdfVertex', { {0.5, -0.5}, {0.5, -0.5} }),
    ffi.new('SdfVertex', { {-0.5, 0.5}, {-0.5, 0.5} }),
    ffi.new('SdfVertex', { {0.5, -0.5}, {0.5, -0.5} }),
    ffi.new('SdfVertex', { {0.5, 0.5}, {0.5, 0.5} }),
  }
  for vertex in tdengine.iterator.values(sdf_quad) do
    self.vertex_buffer:push(vertex)
  end
  self.vertex_buffer:sync()

  -- Some pretty interpolations for the shapes
  self:build_interpolations()

  self.__editor_controls = {
    reset_interpolation = false
  }

  tdengine.editor.set_editor_callbacks(self.__editor_controls, {
    on_change_field = function(field)
      self:on_change_field(field)
    end
  })
end

function SdfRenderer:build_interpolations()
  self.interpolation = {
    ring_thickness = tdengine.interpolation.EaseInOut:new({
      start = 12,
      target = 15,
      exponent = 3,
      time = 1
    }),
    box_rotation = tdengine.interpolation.EaseInOutBounce:new({
      start = 0,
      target = 2 * tdengine.math.pi,
      exponent = 2,
      time = 1.5
    }),
  }
end

function SdfRenderer:on_change_field(field)
  if field == 'reset_interpolation' then
    self:build_interpolations()
    self.__editor_controls.reset_interpolation = false
  end
end


function SdfRenderer:push_header(sdf_header)
  self.sdf_data:push(sdf_header.color.x)
  self.sdf_data:push(sdf_header.color.y)
  self.sdf_data:push(sdf_header.color.z)
  self.sdf_data:push(sdf_header.position.x)
  self.sdf_data:push(sdf_header.position.y)
  self.sdf_data:push(sdf_header.rotation)
  self.sdf_data:push(sdf_header.edge_thickness)
end

function SdfRenderer:draw_circle(sdf_circle)
  self.instance_buffer:push(SdfInstance:new({
    kind = Sdf.Circle,
    buffer_index = self.sdf_data:size()
  }))

  self:push_header(sdf_circle.header)
  self.sdf_data:push(sdf_circle.radius)
end

function SdfRenderer:draw_ring(sdf_ring)
  self.instance_buffer:push(SdfInstance:new({
    kind = Sdf.Ring,
    buffer_index = self.sdf_data:size()
  }))

  self:push_header(sdf_ring.header)
  self.sdf_data:push(sdf_ring.inner_radius)
  self.sdf_data:push(sdf_ring.outer_radius)
end

function SdfRenderer:draw_oriented_box(sdf_oriented_box)
  self.instance_buffer:push(SdfInstance:new({
    kind = Sdf.OrientedBox,
    buffer_index = self.sdf_data:size()
  }))

  self:push_header(sdf_oriented_box.header)
  self.sdf_data:push(sdf_oriented_box.size.x)
  self.sdf_data:push(sdf_oriented_box.size.y)
end

function SdfRenderer:draw_combination(...)
	local args = table.pack(...)
end


function SdfRenderer:update()
  for interpolation in tdengine.iterator.values(self.interpolation) do
    if interpolation:update() then
      interpolation:reset()
      interpolation:reverse()
    end
  end
  
  self.instance_buffer:fast_clear()
  self.sdf_data:fast_clear()
  self.sdf_combine_data:fast_clear()

  self:draw_circle(SdfCircle:new({
    position = Vector2:new(0, 0),
    color = tdengine.colors.zomp,
    edge_thickness = 1.5,
    rotation = 0,
    radius = 20,
  }))

  self:draw_circle(SdfCircle:new({
    position = Vector2:new(100, 0),
    color = tdengine.colors.indian_red,
    edge_thickness = 1.5,
    rotation = 0,
    radius = 10,
  }))


  self:draw_ring(SdfRing:new({
    position = Vector2:new(50, 0),
    color = tdengine.colors.cadet_gray,
    rotation = 0,
    edge_thickness = 1.5,
    inner_radius = 10,
    outer_radius = self.interpolation.ring_thickness:get_value(),
  }))

  self:draw_oriented_box(SdfOrientedBox:new({
    position = Vector2:new(150, 0),
    color = tdengine.colors.cadet_gray,
    rotation = self.interpolation.box_rotation:get_value(),
    edge_thickness = 1.5,
    size = Vector2:new(40, 10)
  }))

  -- self:draw_combination(
  --   SdfCircle:new({
  --     position = Vector2:new(200, 0),
  --     color = tdengine.colors.zomp,
  --     edge_thickness = 1.5,
  --     rotation = 0,
  --     radius = 20,
  --   }),
  --   SdfCircle:new({
  --     position = Vector2:new(210, 0),
  --     color = tdengine.colors.zomp,
  --     edge_thickness = 1.5,
  --     rotation = 0,
  --     radius = 20,
  --   }))

  -- )

  self.instance_buffer:sync()
  self.sdf_data:sync()
  self.sdf_combine_data:sync()
end

DeferredRenderer = tdengine.subsystem.define('DeferredRenderer')

function DeferredRenderer:init()
  self.render_enabled = true
  self.max_lights = 16;
  self.lights = nil
  self.sdf_buffer_length = 1024
  self.shape_buffers = {}
end

function DeferredRenderer:on_start_game()
  self.shape_buffers = {
    circle = BackedGpuBuffer:new('SdfCircle', self.sdf_buffer_length)
  }

  self.lights = BackedGpuBuffer:new('Light', self.max_lights, tdengine.gpus.find(Buffer.Lights))
  self.lights.gpu_buffer:zero()

  self.sdf_renderer = SdfRenderer:new()

  self.command_buffer = tdengine.gpu.command_buffer_create(GpuCommandBufferDescriptor:new({
    max_commands = 1024
  }))

  self.render_pass = GpuRenderPass:new({
    color = RenderTarget.Color
  })

  self.pipeline = GpuPipeline:new({
    raster = {
      shader = Shader.Shape,
      primitive = GpuDrawPrimitive.Triangles
    },
    buffer_layouts = {
      {
        vertex_attributes = {
          {
            count = 2,
            kind = tdengine.enums.GpuVertexAttributeKind.Float
          },
          {
            count = 2,
            kind = tdengine.enums.GpuVertexAttributeKind.Float
          }
        }
      },
      {
        vertex_attributes = {
          {
            count = 1,
            kind = tdengine.enums.VertexAttributeKind.U32,
            divisor = 1
          },
        }
      }
    }
  })
end

function DeferredRenderer:on_begin_frame()
end

function DeferredRenderer:on_scene_rendered()
  self.sdf_renderer:update()

  self.bindings = GpuBufferBinding:new({
    vertex = {
      self.sdf_renderer.vertex_buffer.gpu_buffer:to_ctype(),
      self.sdf_renderer.instance_buffer.gpu_buffer:to_ctype(),
    },
    storage = {
      {
        buffer = self.sdf_renderer.sdf_data.gpu_buffer:to_ctype(),
        base = 0
      },
      {
        buffer = self.sdf_renderer.sdf_combine_data.gpu_buffer:to_ctype(),
        base = 1
      }
    }
  })

  -- begin a render pass
  tdengine.gpu.begin_render_pass(self.command_buffer, self.render_pass)
  tdengine.gpu.bind_pipeline(self.command_buffer, self.pipeline)
  tdengine.gpu.apply_bindings(self.command_buffer, self.bindings)
  tdengine.gpu.set_world_space(self.command_buffer, true)
  tdengine.gpu.set_camera(self.command_buffer, tdengine.editor.find('EditorCamera').offset:to_ctype())
  tdengine.gpu.command_buffer_draw(self.command_buffer, GpuDrawCall:new({
    mode = GpuDrawMode.Instance,
    vertex_offset = 0,
    num_vertices = 6,
    num_instances = self.sdf_renderer.instance_buffer:size(),
  }))
  tdengine.gpu.end_render_pass(self.command_buffer)
  tdengine.gpu.command_buffer_submit(self.command_buffer)

  -- bind the buffers
  -- draw a triangle
  -- end the render pass
  -- submit the commands

  -- update dynamic uniforms
  -- bind
  -- draw a fullscreen quad
  -- submit
  -- self.visualize_light_map:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)
  -- self.visualize_light_map:render()

  -- self.light_scene:render()
  -- self.apply_lighting:add_uniform('num_lights', self.lights.cpu_buffer.size, tdengine.enums.UniformKind.I32)

  -- self.shapes:render()

  -- tdengine.subsystem.find('PostProcess'):upscale()
end
