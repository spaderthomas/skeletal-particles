SdfRenderer = tdengine.class.define('SdfRenderer')

function SdfRenderer:init()
  local buffer_size = 256 * 1024
  self.c_renderer = ffi.new('SdfRenderer [1]')
  self.c_renderer[0] = ffi.C.sdf_renderer_create(buffer_size)
  self.vertex_buffer = BackedGpuBuffer:owned(
    'SdfVertex',
    buffer_size,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Array,
      usage = GpuBufferUsage.Static
    }))

  self.instance_buffer = BackedGpuBuffer:owned(
    'SdfInstance',
    buffer_size,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Array,
      usage = GpuBufferUsage.Static
    }))

  self.sdf_data = BackedGpuBuffer:owned(
    'float',
    buffer_size,
    GpuBufferDescriptor:new({
      kind = GpuBufferKind.Storage,
      usage = GpuBufferUsage.Dynamic
    }))

  self.sdf_combine_data = BackedGpuBuffer:owned(
    'u32',
    buffer_size,
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

  -- Add a timer
  tdengine.time_metric.add('sdf')

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
    merge_position = tdengine.interpolation.EaseInOut:new({
      start = -10,
      target = 10,
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


function SdfRenderer:push_instance(sdf)
  self.instance_buffer:push(SdfInstance:new({
    kind = sdf.header.shape,
    buffer_index = self.sdf_data:size()
  }))
end

function SdfRenderer:push_shape(sdf)
  self.sdf_data:push(sdf.header.color.x)
  self.sdf_data:push(sdf.header.color.y)
  self.sdf_data:push(sdf.header.color.z)
  self.sdf_data:push(sdf.header.position.x)
  self.sdf_data:push(sdf.header.position.y)
  self.sdf_data:push(sdf.header.rotation)
  self.sdf_data:push(sdf.header.edge_thickness)

  if Sdf.Circle:match(sdf.header.shape) then
    self.sdf_data:push(sdf.radius)
  elseif Sdf.Ring:match(sdf.header.shape) then
    self.sdf_data:push(sdf.inner_radius)
    self.sdf_data:push(sdf.outer_radius)
  elseif Sdf.OrientedBox:match(sdf.header.shape) then
    self.sdf_data:push(sdf.size.x)
    self.sdf_data:push(sdf.size.y)
  end
end

function SdfRenderer:draw_circle(sdf_circle)
  self:push_instance(sdf_circle)
  self:push_shape(sdf_circle)
end

function SdfRenderer:draw_ring(sdf_ring)
  self:push_instance(sdf_ring)
  self:push_shape(sdf_ring)
end

function SdfRenderer:draw_oriented_box(sdf_oriented_box)
  self:push_instance(sdf_oriented_box)
  self:push_shape(sdf_oriented_box)
end

function SdfRenderer:draw_combination(...)
  local sdfs = { ... }

  -- Add an instance, and give it an index into the combine data buffer
  self.instance_buffer:push(SdfInstance:new({
    kind = Sdf.Combine,
    buffer_index = self.sdf_combine_data:size()
  }))

  -- In the combine data, we'll have a header which tells us how many shapes
  -- to combine.
  local header = SdfCombineHeader:new({
    num_sdfs = #sdfs
  })
  self.sdf_combine_data:push(header.num_sdfs)

  -- Then, an array of shapes. Each shape is just a kind and index into the
  -- SDF data buffer (just like an instance), and then a combine op and kernel.
  for sdf in tdengine.iterator.values(sdfs) do
    local entry = SdfCombineEntry:new({
      kind = sdf.header.shape,
      buffer_index = self.sdf_data:size(),
      combine_op = SdfCombineOp.Union,
      kernel = SdfSmoothingKernel.PolynomialQuadratic,
    })

    self.sdf_combine_data:push(entry.kind)
    self.sdf_combine_data:push(entry.buffer_index)
    self.sdf_combine_data:push(entry.combine_op)
    self.sdf_combine_data:push(entry.kernel)

    self:push_shape(sdf)
  end
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
    position = Vector2:new(100, 0),
    color = tdengine.colors.zomp,
    edge_thickness = 1.5,
    rotation = 0,
    radius = 20,
  }))

  self:draw_circle(SdfCircle:new({
    position = Vector2:new(150, 0),
    color = tdengine.colors.indian_red,
    edge_thickness = 1.5,
    rotation = 0,
    radius = 10,
  }))


  self:draw_ring(SdfRing:new({
    position = Vector2:new(200, 0),
    color = tdengine.colors.cadet_gray,
    rotation = 0,
    edge_thickness = 1.5,
    inner_radius = 10,
    outer_radius = self.interpolation.ring_thickness:get_value(),
  }))

  self:draw_oriented_box(SdfOrientedBox:new({
    position = Vector2:new(250, 0),
    color = tdengine.colors.cadet_gray,
    rotation = self.interpolation.box_rotation:get_value(),
    edge_thickness = 1.5,
    size = Vector2:new(40, 10)
  }))

  self:draw_combination(
    SdfOrientedBox:new({
      position = Vector2:new(0, 0),
      color = tdengine.colors.indian_red,
      edge_thickness = 1.5,
      rotation = .3,
      size = Vector2:new(10, 40)
    }),
    SdfCircle:new({
      position = Vector2:new(10 + self.interpolation.merge_position:get_value(), 0),
      color = tdengine.colors.zomp,
      edge_thickness = 1.5,
      rotation = 0,
      radius = 10,
    })
  )

  tdengine.ffi.tm_begin('sdf')
  local fast = FastCpuBuffer
  fast.data = self.sdf_data.cpu_buffer.data
  fast.size = self.sdf_data.cpu_buffer.size

  local faster = {
    data = self.sdf_data.cpu_buffer.data,
    size = self.sdf_data.cpu_buffer.size
    }
  local sdf = SdfCircle:new({
    position = Vector2:new(x, y),
    color = tdengine.colors.prussian_blue,
    edge_thickness = 1.5,
    rotation = 0,
    radius = 5
  })
  local instance = SdfInstance:new({
    kind = Sdf.Circle,
    buffer_index = 0
  })
  local grid_width = 20
  local grid_size = 400
  -- for x = 0, grid_size, grid_width do
  --     for y = 0, grid_size, grid_width do
  self.c_renderer[0].vertex_data.size = 0
  for i = 0, 10000 do
    -- ffi.C.sdf_circle(self.c_renderer, 5);
        -- instance.buffer_index = self.sdf_data:size()
        -- self.instance_buffer:push(instance)
  
        -- faster.data[faster.size] = sdf.header.color.x
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.header.color.y
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.header.color.z
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.header.position.x
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.header.position.y
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.header.rotation
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.header.edge_thickness
        -- faster.size = faster.size + 1
        -- faster.data[faster.size] = sdf.radius
        -- faster.size = faster.size + 1

        -- fast:push(sdf.header.color.x)
        -- fast:push(sdf.header.color.y)
        -- fast:push(sdf.header.color.z)
        -- fast:push(x)
        -- fast:push(y)
        -- fast:push(sdf.header.rotation)
        -- fast:push(sdf.header.edge_thickness)
        -- fast:push(sdf.radius)
        -- self.sdf_data.cpu_buffer.size = fast.size


        -- self.sdf_data:push(sdf.header.color.x)
        -- self.sdf_data:push(sdf.header.color.y)
        -- self.sdf_data:push(sdf.header.color.z)
        -- self.sdf_data:push(i)
        -- self.sdf_data:push(i)
        -- self.sdf_data:push(sdf.header.rotation)
        -- self.sdf_data:push(sdf.header.edge_thickness)
        -- self.sdf_data:push(sdf.radius)
      end
  -- end

  tdengine.ffi.tm_end('sdf')

  -- print(self.sdf_data:size())
  self.instance_buffer:sync()
  self.sdf_data:sync()
  self.sdf_combine_data:sync()
end

DeferredRenderer = tdengine.subsystem.define('DeferredRenderer')

function DeferredRenderer:init()
  self.render_enabled = true
  self.max_lights = 16;
  self.lights = nil
  self.shape_buffers = {}
end

function DeferredRenderer:on_start_game()
  self.sdf_renderer = ffi.new('SdfRenderer [1]');
  self.sdf_renderer = tdengine.ffi.sdf_renderer_create(1024)

  self.command_buffer = tdengine.gpu.command_buffer_create(GpuCommandBufferDescriptor:new({
    max_commands = 1024
  }))

  self.render_pass = GpuRenderPass:new({
    color = RenderTarget.Color
  })
end

function DeferredRenderer:on_begin_frame()
end

function DeferredRenderer:on_scene_rendered()
  tdengine.ffi.sdf_circle_ex(
    self.sdf_renderer,
    0, 0,
    1.0, 0.0, 1.0,
    0.0,
    1.5,
    10
  )
  tdengine.gpu.begin_render_pass(self.command_buffer, self.render_pass)
  tdengine.gpu.set_world_space(self.command_buffer, true)
  tdengine.gpu.set_camera(self.command_buffer, tdengine.editor.find('EditorCamera').offset:to_ctype())
  tdengine.ffi.sdf_renderer_draw(self.sdf_renderer, self.command_buffer)
  tdengine.gpu.end_render_pass(self.command_buffer)
  tdengine.gpu.command_buffer_submit(self.command_buffer)
end
