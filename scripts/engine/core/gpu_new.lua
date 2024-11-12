-------------
-- STRUCTS --
-------------
GpuColorAttachment = tdengine.class.metatype('GpuColorAttachment')
function GpuColorAttachment:init(params)
  self.read = tdengine.gpus.find_render_target(params.read)
  self.write = tdengine.gpus.find_render_target(params.write)
  self.load_op = tdengine.enum.load(params.load_op):to_number()
end

GpuUniformBinding = tdengine.class.metatype('GpuUniformBinding')
function GpuUniformBinding:init(params)
  self.name = params.name
  self.kind = tdengine.enum.load(params.kind):to_number()
  if tdengine.enums.UniformKind.F32:match(self.kind) then
    self.f32 = params.value
  elseif tdengine.enums.UniformKind.I32:match(self.kind) then
    self.i32 = params.value
  elseif tdengine.enums.UniformKind.Vector2:match(self.kind) then
    self.vec2 = Vector2:new(params.value.x, params.value.y)
  elseif tdengine.enums.UniformKind.Vector3:match(self.kind) then
    self.vec3 = Vector3:new(params.value.x, params.value.y, params.value.z)
  elseif tdengine.enums.UniformKind.Vector4:match(self.kind) then
    self.vec4 = Vector4:new(params.value.x, params.value.y, params.value.z, params.value.w)
  elseif tdengine.enums.UniformKind.Matrix3:match(self.kind) then
    self.mat3 = Matrix3:new(params.value)
  elseif tdengine.enums.UniformKind.Matrix4:match(self.kind) then
    self.mat4 = Matrix4:new(params.value)
  elseif tdengine.enums.UniformKind.PipelineOutput:match(self.kind) then
    self.pipeline = tdengine.gpus.find_graphics_pipeline(params.value)
  elseif tdengine.enums.UniformKind.RenderTarget:match(self.kind) then
    self.render_target = tdengine.gpus.find_render_target(params.value)
  end
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
    self.size = tdengine.gpus.find_resolution(params.resolution)
  else
    self.size = Vector2:new(params.size.x, params.size.y)
  end
end

GpuGraphicsPipelineDescriptor = tdengine.class.metatype('GpuGraphicsPipelineDescriptor')
function GpuGraphicsPipelineDescriptor:init(params)
  local allocator = tdengine.ffi.ma_find('bump')

  self.color_attachment = GpuColorAttachment:new(params.color_attachment)
  self.shader = tdengine.gpus.find_shader(params.shader)

  self.num_uniforms = params.uniforms and #params.uniforms or 0
  if self.num_uniforms > 0 then dbg() end
  self.uniforms = allocator:alloc_array('GpuUniformBinding', self.num_uniforms)
  for i = 1, self.num_uniforms do
    self.uniforms[i - 1] = GpuUniformBinding:new(params.uniforms[i])
  end
  if self.num_uniforms > 0 then dbg() end

  self.num_storage_buffers = params.storage_buffers and #params.storage_buffers or 0

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

----------------
-- GPU MODULE --
----------------
local self = tdengine.gpus
function tdengine.gpus.init()
  self.render_targets = {}
  self.render_passes = {}
  self.command_buffers = {}
  self.storage_buffers = {}
  self.shaders = {}
  self.resolutions = {}
end

function tdengine.gpus.build(gpu_info)
  self.add_resolutions(gpu_info.resolutions)
  self.add_render_targets(gpu_info.render_targets)
  self.add_storage_buffers(gpu_info.storage_buffers)
  self.add_command_buffers(gpu_info.command_buffers)
  self.add_graphics_pipelines(gpu_info.graphics_pipelines)
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

function tdengine.gpus.find_render_target(id)
  if not id then
    return nil
  end

  return self.render_targets[tdengine.enum.load(id):to_string()]
end


-----------------------
-- GRAPHICS PIPELINE --
-----------------------
function tdengine.gpus.add_graphics_pipeline(id, descriptor)
  self.render_passes[id:to_string()] = tdengine.ffi.gpu_create_graphics_pipeline(descriptor)
end

function tdengine.gpus.add_graphics_pipelines(pipelines)
	for pipeline in tdengine.iterator.values(pipelines) do
		self.add_graphics_pipeline(
			pipeline.id,
			GpuGraphicsPipelineDescriptor:new(pipeline.descriptor)
		)
	end
end

function tdengine.gpus.find_graphics_pipeline(id)
  if not id then dbg(); return nil end

  id = tdengine.enum.load(id):to_string()
  local pipeline = self.render_passes[id]
  if not pipeline then
    log.warn('Could not find graphics pipeline; name = %s', id)
  end
  return pipeline
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

function tdengine.gpus.find_command_buffer(id)
  if not id then
    return nil
  end

  return self.command_buffers[tdengine.enum.load(id):to_string()]
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

function tdengine.gpus.find_storage_buffer(id)
  if not id then
    return nil
  end

  return self.storage_buffers[tdengine.enum.load(id):to_string()]
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

function tdengine.gpus.find_shader(id)
  if not id then
    return nil
  end

  return self.shaders[tdengine.enum.load(id):to_string()]
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

function tdengine.gpus.find_resolution(id)
  if not id then
    return nil
  end

  return self.resolutions[tdengine.enum.load(id):to_string()]
end
