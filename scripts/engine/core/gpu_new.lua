GpuColorAttachment = tdengine.class.metatype('GpuColorAttachment')
function GpuColorAttachment:init(params)
  self.read = tdengine.gpus.find_render_target(params.read)
  self.write = tdengine.gpus.find_render_target(params.write)
  self.load_op = tdengine.enum.load(params.load_op):to_number()
end


GpuRenderPassDescriptor2 = tdengine.class.metatype('GpuRenderPassDescriptor2')
function GpuRenderPassDescriptor2:init(params)
  self.color_attachment = GpuColorAttachment:new(params.color_attachment)
end

GpuRenderTargetDescriptor = tdengine.class.metatype('GpuRenderTargetDescriptor')
function GpuRenderTargetDescriptor:init(size)
  self.size.x = size.x
  self.size.y = size.y
end

local self = tdengine.gpus
function tdengine.gpus.init()
  self.render_targets = {}
  self.render_passes = {}
end

function tdengine.gpus.add_render_target(id, descriptor)
  dbg()
  self.render_targets[tdengine.enum.load(id):to_string()] = tdengine.ffi.gpu_create_target_ex(descriptor)
end

function tdengine.gpus.add_render_pass(id, descriptor)
  self.render_passes[tdengine.enum.load(id):to_string()] = tdengine.ffi.gpu_create_render_pass_ex(descriptor)
end

function tdengine.gpus.find_render_target(id)
  if not id then
    return nil
  end

  return self.render_targets[tdengine.enum.load(id):to_string()]
end
