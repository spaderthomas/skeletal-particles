-------------
-- STRUCTS --
-------------
GpuColorAttachment = tdengine.class.metatype('GpuColorAttachment')
function GpuColorAttachment:init(params)
  self.read = params.read and tdengine.gpus.find(params.read) or nil
  self.write = tdengine.gpus.find(params.write)
  self.load_op = tdengine.enum.load(params.load_op):to_number()
end

GpuShaderDescriptor = tdengine.class.metatype('GpuShaderDescriptor')
function GpuShaderDescriptor:init(params)
  params.kind = tdengine.enum.load(params.kind)
  self.kind = params.kind:to_number()
  self.name = params.name

  if params.kind == tdengine.enums.GpuShaderKind.Graphics then
    self.vertex_shader = params.vertex_shader
    self.fragment_shader = params.fragment_shader
  elseif params.kind == tdengine.enums.GpuShaderKind.Compute then
    self.compute_shader = params.compute_shader
  end
end

GpuRenderTargetDescriptor = tdengine.class.metatype('GpuRenderTargetDescriptor')
function GpuRenderTargetDescriptor:init(params)
  if params.resolution then
    self.size = tdengine.gpus.find(params.resolution)
  else
    self.size = Vector2:new(params.size.x, params.size.y)
  end
end

GpuGraphicsPipelineDescriptor = tdengine.class.metatype('GpuGraphicsPipelineDescriptor')
function GpuGraphicsPipelineDescriptor:init(params)
  self.color_attachment = GpuColorAttachment:new(params.color_attachment)
  self.command_buffer = tdengine.gpus.find(params.command_buffer)
end

GpuCommandBufferDescriptor = tdengine.class.metatype('GpuCommandBufferDescriptor')
function GpuCommandBufferDescriptor:init(params) 
  local allocator = tdengine.ffi.ma_find('bump')

  self.max_vertices = params.max_vertices
  self.max_draw_calls = params.max_draw_calls

  self.num_vertex_attributes = #params.vertex_attributes
  self.vertex_attributes = allocator:alloc_array('VertexAttribute', self.num_vertex_attributes)
  for i = 1, self.num_vertex_attributes, 1 do
    local attribute = self.vertex_attributes[i - 1]
    local data = params.vertex_attributes[i]
    attribute.count = data.count
    attribute.kind = tdengine.enum.load(data.kind):to_number()
  end
end

-------------
-- CLASSES --
------------
UniformBinding = tdengine.class.define('UniformBinding')
function UniformBinding:init(name, value, kind)
  self.name = name
  self.value = value
  self.kind = kind
end

function UniformBinding:bind()
  if self.kind == tdengine.enums.UniformKind.Texture then
    tdengine.ffi.set_uniform_texture(self.name, tdengine.gpus.find(self.value).color_buffer)
  elseif self.kind == tdengine.enums.UniformKind.PipelineOutput then
    local pipeline = tdengine.gpus.find(self.value)
    tdengine.ffi.set_uniform_texture(self.name, pipeline.color_attachment.write)
  elseif self.kind == tdengine.enums.UniformKind.RenderPassTexture then
   tdengine.ffi.set_uniform_texture(self.name, tdengine.gpu.find_read_texture(self.value))
  elseif self.kind == tdengine.enums.UniformKind.Enum then
    tdengine.ffi.set_uniform_enum(self.name, self.value)
  elseif self.kind == tdengine.enums.UniformKind.F32 then
    tdengine.ffi.set_uniform_f32(self.name, self.value)
  elseif self.kind == tdengine.enums.UniformKind.I32 then
    tdengine.ffi.set_uniform_i32(self.name, self.value)
  end
end


SsboBinding = tdengine.class.define('SsboBinding')
function SsboBinding:init(index, buffer_id)
  self.index = index
  self.ssbo = tdengine.gpus.find(buffer_id)
end

function SsboBinding:bind()
  tdengine.ffi.gpu_bind_buffer_base(self.ssbo, self.index)
end


GpuDrawConfiguration = tdengine.class.define('GpuDrawConfiguration')
function GpuDrawConfiguration:init(params)
  self.shader = tdengine.gpus.find(params.shader)

  self.uniforms = tdengine.data_types.Array:new()
  for binding in tdengine.iterator.values(params.uniforms) do
    self.uniforms:add(UniformBinding:new(binding))
  end

  self.ssbos = tdengine.data_types.Array:new()
  for binding in tdengine.iterator.values(params.ssbos) do
    self.ssbos:add(SsboBinding:new(binding.index, binding.id))
  end
end

function GpuDrawConfiguration:add_uniform(name, value, kind)
  for uniform in self.uniforms:iterate_values() do
    if uniform.name == name then
      uniform.value = value
      return
    end
  end

  self.uniforms:add(UniformBinding:new(name, value, kind))
end

function GpuDrawConfiguration:bind()
  tdengine.ffi.set_active_shader_ex(self.shader)
  tdengine.ffi.set_draw_mode(tdengine.enums.DrawMode.Triangles)

  for uniform in self.uniforms:iterate_values() do
    uniform:bind()
  end

  for ssbo in self.ssbos:iterate_values() do
    ssbo:bind()
  end
end


ConfiguredPostProcess = tdengine.class.define('ConfiguredPostProcess')
function ConfiguredPostProcess:init(pipeline, draw_configuration)
  self.pipeline = pipeline
  self.draw_configuration = draw_configuration
end

function ConfiguredPostProcess:render()
  tdengine.ffi.gpu_graphics_pipeline_bind(self.pipeline)
  self.draw_configuration:bind()

  local size = self.pipeline.color_attachment.write.size
  ffi.C.push_quad(
    0, size.y,
    size.x, size.y,
    nil,
    1.0)


    tdengine.ffi.gpu_graphics_pipeline_submit(self.pipeline)
    -- tdengine.gpu.apply_ping_pong(self.graphics_pipeline)
end

local todo = [[
- Properly clear render targets on load
- Clean up push_vertex() so the call stack isn't four deep
- Make sure the old draw API works and make sure the GPU setup for that is included in the base engine
  - Why is the grid totally filling up the vertex buffer? Are the sizes correct?
- What is a store op?
- Figure out the actual minimum number of command buffers you need
- UniformBinding is still a mess of unimplemented and messy uniforms; fix those up
  - Can I just move all the union-uniform stuff into Lua? I think that'd mean moving all of your current draw stuff into Lua, which 
  isn't necessarily a problem. It's more that your whole immediate mode API doesn't make as much sense here. Or does it...? That's
  something else. What is actually my bottleneck in drawing? I definitely want, for example, all the grid draw calls to get batched
  together. I want *some* kind of auto-batching.
- Rename Shader
- Rename ConfiguredPostProcess
- Rename RenderPass enum -> GraphicsPipeline
- Draw an SDF circle using the other buffer
- Render component should draw to the correct pipeline
- Reimplement all of the post processing stuff
  - Reimplement ping-pong
- Make the benchmark timer API better (e.g. local timer = tdengine.ffi.tm_begin(Timer.Render); timer:end())
- Fully remove gpu.lua
- Merge into the base engine...?
]]

local done = [[
- find_resource() -> find()
  - Move the named assets thing into the right place in the user folder
]]

----------------
-- GPU MODULE --
----------------

GpuResourceKind = tdengine.enum.define(
  'GpuResourceKind',
  {
    RenderTarget = 0,
    GraphicsPipeline = 1,
    CommandBuffer = 2,
    StorageBuffer = 3,
    Shader = 4,
    Resolution = 5,
    DrawConfiguration = 6,
  }
)

local self = tdengine.gpus
function tdengine.gpus.init()
  self.render_targets = {}
  self.graphics_pipelines = {}
  self.command_buffers = {}
  self.storage_buffers = {}
  self.shaders = {}
  self.resolutions = {}
  self.draw_configurations = {}
end

function tdengine.gpus.update()
  for pipeline in tdengine.iterator.values(self.graphics_pipelines) do
    tdengine.ffi.gpu_graphics_pipeline_begin_frame(pipeline)
  end
end

function tdengine.gpus.render()
    tdengine.ffi.tm_begin('render')

  tdengine.lifecycle.run_callback(tdengine.lifecycle.callbacks.on_render_scene)
  tdengine.lifecycle.run_callback(tdengine.lifecycle.callbacks.on_scene_rendered)

  local swapchain = tdengine.ffi.gpu_acquire_swapchain()
  tdengine.ffi.gpu_bind_target(swapchain)
  tdengine.ffi.gpu_clear_target(swapchain)
  tdengine.app:on_swapchain_ready()
  tdengine.ffi.gpu_swap_buffers()

  tdengine.ffi.tm_end('render')
end

function tdengine.gpus.bind_entity(entity)
  local pipeline = self.find(RenderPass.Editor)

  local render = entity:find_component('Render')
  if render then
    pipeline = render.pipeline
  end

  tdengine.ffi.gpu_graphics_pipeline_bind(pipeline)
end


function tdengine.gpus.build(gpu_info)
  self.add_resolutions(gpu_info.resolutions)
  self.add_render_targets(gpu_info.render_targets)
  self.add_storage_buffers(gpu_info.storage_buffers)
  self.add_shaders(gpu_info.shaders)
  self.add_command_buffers(gpu_info.command_buffers)
  self.add_graphics_pipelines(gpu_info.graphics_pipelines)
  self.add_draw_configurations(gpu_info.draw_configurations)
end

function tdengine.gpus.find(id)
  if not tdengine.enum.is_enum(id) then 
    log.warn('Tried to find GPU resource, but ID passed in was not an enum; id = %s', tostring(id))
    return nil
  end

  local resource_map
  if tdengine.enums.RenderTarget:match(id) then
    resource_map = self.render_targets
  elseif tdengine.enums.RenderPass:match(id) then
    resource_map = self.graphics_pipelines
  elseif tdengine.enums.CommandBuffer:match(id) then
    resource_map = self.command_buffers
  elseif tdengine.enums.StorageBuffer:match(id) then
    resource_map = self.storage_buffers
  elseif tdengine.enums.Shader:match(id) then
    resource_map = self.shaders
  elseif tdengine.enums.Resolution:match(id) then
    resource_map = self.resolutions
  elseif tdengine.enums.DrawConfiguration:match(id) then
    resource_map = self.draw_configurations
  end

  local string_id = tdengine.enum.load(id):to_string()
  local resource = resource_map[string_id]
  if not resource then
    dbg()
    log.warn('Could not find GPU resource; id = %s', string_id)
  end

  return resource
end


-------------------
-- RENDER TARGET -- 
-------------------
function tdengine.gpus.add_render_target(id, descriptor)
  self.render_targets[id:to_string()] = tdengine.ffi.gpu_create_target_ex(descriptor)
end

function tdengine.gpus.add_render_targets(targets)
  for target in tdengine.iterator.values(targets) do
		self.add_render_target(
			target.id,
			GpuRenderTargetDescriptor:new(target.descriptor)
		)
	end
end

-----------------------
-- GRAPHICS PIPELINE --
-----------------------
function tdengine.gpus.add_graphics_pipeline(id, descriptor)
  self.graphics_pipelines[id:to_string()] = tdengine.ffi.gpu_graphics_pipeline_create(descriptor)
end

function tdengine.gpus.add_graphics_pipelines(pipelines)
	for pipeline in tdengine.iterator.values(pipelines) do
		self.add_graphics_pipeline(
			pipeline.id,
			GpuGraphicsPipelineDescriptor:new(pipeline.descriptor)
		)
	end
end

--------------------
-- COMMAND BUFFER --
--------------------
function tdengine.gpus.add_command_buffer(id, descriptor)
  self.command_buffers[id:to_string()] = tdengine.ffi.gpu_create_command_buffer(descriptor)
end

function tdengine.gpus.add_command_buffers(command_buffers)
  for buffer in tdengine.iterator.values(command_buffers) do
    self.add_command_buffer(
      buffer.id,
      GpuCommandBufferDescriptor:new(buffer.descriptor)
    )
  end
end

----------------
-- GPU BUFFER --
----------------
function tdengine.gpus.add_storage_buffer(id)
  self.storage_buffers[id:to_string()] = tdengine.ffi.gpu_create_buffer()
end

function tdengine.gpus.add_storage_buffers(storage_buffers)
  for storage_buffer in tdengine.iterator.values(storage_buffers) do
		self.add_storage_buffer(storage_buffer.id)
	end
end

------------
-- SHADER --
------------
function tdengine.gpus.add_shader(id, descriptor)
  self.shaders[id:to_string()] = tdengine.ffi.gpu_create_shader(descriptor)
end

function tdengine.gpus.add_shaders(shaders)
  for shader in tdengine.iterator.values(shaders) do
		self.add_shader(
			shader.id,
			GpuShaderDescriptor:new(shader.descriptor)
		)
	end
end

----------------
-- RESOLUTION --
----------------
function tdengine.gpus.add_resolution(id, size)
  self.resolutions[id:to_string()] = Vector2:new(size.x, size.y)
end

function tdengine.gpus.add_resolutions(resolutions)
  for resolution in tdengine.iterator.values(resolutions) do
    self.add_resolution(resolution.id, resolution.size)
	end
end

------------
-- SHADER --
------------
function tdengine.gpus.add_draw_configuration(id, draw_configuration)
  self.draw_configurations[id:to_string()] = draw_configuration
end

function tdengine.gpus.add_draw_configurations(draw_configurations)
  for draw_configuration in tdengine.iterator.values(draw_configurations) do
		self.add_draw_configuration(
			draw_configuration.id,
			GpuDrawConfiguration:new(draw_configuration)
		)
	end
end
