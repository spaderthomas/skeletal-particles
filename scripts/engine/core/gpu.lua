local self = tdengine.gpu

---------------------
-- UTILITY STRUCTS --
---------------------
local RenderPass = tdengine.class.define('RenderPass')
function RenderPass:init(params)
  self.name = params.name
  self.handle = params.handle
  self.command_buffer = params.command_buffer
end

local RenderTarget = tdengine.class.define('RenderTarget')
function RenderTarget:init(params)
  self.name = params.name
  self.size = params.size
  self.handle = params.handle
end

local CommandBuffer = tdengine.class.define('CommandBuffer')
function CommandBuffer:init(params)
  self.name = params.name
  self.handle = params.handle
end

---------
-- GPU --
---------
function tdengine.gpu.init()
  self.render_targets = {}
  self.render_passes = {}
  self.command_buffers = tdengine.data_types.Array:new()
end

function tdengine.gpu.render()
  tdengine.ffi.tm_begin('render')

  tdengine.lifecycle.run_callback(tdengine.lifecycle.callbacks.on_render_scene)
  tdengine.lifecycle.run_callback(tdengine.lifecycle.callbacks.on_scene_rendered)

  -- After this, the game has rendered everything for a frame. We just need to tell the app to
  -- do the final rendering to the swapchain, and then swap the buffers
  local swapchain = tdengine.ffi.gpu_acquire_swapchain()
  tdengine.ffi.gpu_bind_target(swapchain)
  tdengine.ffi.gpu_clear_target(swapchain)
  tdengine.app:on_swapchain_ready()
  tdengine.ffi.gpu_swap_buffers()

  -- Update metadata
  for _, render_pass in pairs(self.render_passes) do
    -- print(render_pass.name, render_pass.handle.clear_render_target)
    render_pass.handle.dirty = false
  end
  tdengine.ffi.tm_end('render')
end

function tdengine.gpu.bind_entity(entity)
  local render = entity:find_component('Render')
  if render then
    self.bind_render_pass(render.render_pass)
  else
    self.bind_render_pass('scene')
  end
end

function tdengine.gpu.bind_render_pass(name)
  -- @hack: When you're typing in the editor, this is ill formed
  if not self.render_passes[name] then return end

  self.bound_render_pass = self.render_passes[name]
  tdengine.ffi.gpu_begin_pass(self.bound_render_pass.handle, self.bound_render_pass.command_buffer)

  return self.bound_render_pass.handle
end

function tdengine.gpu.submit_render_pass(name)
  local render_pass = self.render_passes[name]
  tdengine.ffi.gpu_submit_commands(render_pass.command_buffer)
end

function tdengine.gpu.add_command_buffer(name, buffer_descriptor)
  self.command_buffers:add(CommandBuffer:new({
    name = name,
    handle = tdengine.ffi.gpu_create_command_buffer(buffer_descriptor)
  }))

  return self.command_buffers:back().handle
end

function tdengine.gpu.add_render_target(name, x, y)
  local render_target = tdengine.ffi.gpu_create_target(x, y)
  tdengine.ffi.set_gl_name(tdengine.enums.GlId.Framebuffer:to_number(), render_target.handle, #name, name)

  self.render_targets[name] = RenderTarget:new({
    name = name,
    size = tdengine.vec2(x, y),
    handle = render_target
  })
  return self.render_targets[name].handle
end

function tdengine.gpu.add_render_pass(name, command_buffer, target, ping_pong, load_op)
  load_op = load_op or tdengine.enums.GpuLoadOp.None

  local pass_descriptor = ffi.new('GpuRenderPassDescriptor')
  pass_descriptor.target = target
  pass_descriptor.ping_pong = ping_pong
  pass_descriptor.clear_render_target = load_op == tdengine.enums.GpuLoadOp.Clear

  self.render_passes[name] = RenderPass:new({
    name = name,
    command_buffer = command_buffer,
    handle = tdengine.ffi.gpu_create_pass(pass_descriptor),
  })

  return self.render_passes[name]
end

function tdengine.gpu.find_render_target(name)
  return self.render_targets[name].handle
end

function tdengine.gpu.find_render_pass(name)
  if not self.render_passes[name] then dbg() end
  return self.render_passes[name]
end

function tdengine.gpu.find_command_buffer(name)
  for index, command_buffer in self.command_buffers:iterate() do
    if name == command_buffer.name then
      return command_buffer.handle
    end
  end
end

function tdengine.gpu.apply_ping_pong(name)
  local render_pass = self.render_passes[name]
  
  if render_pass and not tdengine.ffi.is_nil(render_pass.handle.ping_pong) then
    local temp = render_pass.handle.render_target
    render_pass.handle.render_target = render_pass.handle.ping_pong
    render_pass.handle.ping_pong = temp
  end
end

function tdengine.gpu.find_current_texture(pass_name)
  local render_pass = self.render_passes[pass_name]
  if not render_pass then
    log.warn('Could not find color buffer because render pass did not exist; render_pass = %s', pass_name)
  end

  return render_pass.handle.render_target.color_buffer
end

function tdengine.gpu.find_read_texture(pass_name)
  local render_pass = self.render_passes[pass_name]
  if not render_pass then
    log.warn('Could not find color buffer because render pass did not exist; render_pass = %s', pass_name)
  end

  return render_pass.handle.ping_pong.color_buffer
end

function tdengine.gpu.find_write_texture(pass_name)
  local render_pass = self.render_passes[pass_name]
  if not render_pass then
    log.warn('Could not find color buffer because render pass did not exist; render_pass = %s', pass_name)
  end

  return render_pass.handle.render_target.color_buffer
end



function tdengine.gpu.find_current_target(pass_name)
  local render_pass = self.render_passes[pass_name]
  if not render_pass then
    log.warn('Could not find render target because render pass did not exist; render_pass = %s', pass_name)
  end

  return render_pass.handle.render_target
end

function tdengine.gpu.find_read_target(pass_name)
  local render_pass = self.render_passes[pass_name]
  if not render_pass then
    log.warn('Could not find render target because render pass did not exist; render_pass = %s', pass_name)
  end

  return render_pass.handle.ping_pong
end

function tdengine.gpu.find_write_target(pass_name)
  local render_pass = self.render_passes[pass_name]
  if not render_pass then
    log.warn('Could not find render target because render pass did not exist; render_pass = %s', pass_name)
  end

  return render_pass.handle.render_target
end