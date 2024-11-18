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

  self:draw_circle(SdfCircle:new({
    color = tdengine.colors.indian_red,
    position = Vector2:new(0, 0),
    rotation = 0,
    radius = 10,
    edge_thickness = 20,
  }))

  self.instance_buffer:sync()
  self.sdf_data:sync()
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


function SdfRenderer:clear()
  self.instance_buffer:fast_clear()
  self.sdf_data:fast_clear()

  self.instance_buffer:push(SdfInstance:new({
    kind = Sdf.Circle,
    buffer_index = self.sdf_data:size()
  }))
  self.instance_buffer:sync()

  self:draw_circle(SdfCircle:new({
    position = Vector2:new(0, 0),
    radius = 20,
    color = tdengine.colors.zomp,
    edge_thickness = 2,
    rotation = 0
  }))
  self.sdf_data:sync()
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
  self.sdf_renderer:clear()
   self.bindings = GpuBufferBinding:new({
    vertex = {
      self.sdf_renderer.vertex_buffer.gpu_buffer:to_ctype(),
      self.sdf_renderer.instance_buffer.gpu_buffer:to_ctype(),
    },
    storage = {
      {
        buffer = self.sdf_renderer.sdf_data.gpu_buffer:to_ctype(),
        base = 0
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
