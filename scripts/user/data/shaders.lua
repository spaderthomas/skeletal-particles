return {
  {
     id = Shader.ApplyLighting,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'apply_lighting',
        vertex_shader = 'apply_lighting.vertex',
        fragment_shader = 'apply_lighting.fragment'
     }
  },
  {
     id = Shader.Shape,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'shape',
        vertex_shader = 'shape.vertex',
        fragment_shader = 'shape.fragment'
     }
  },
  {
     id = Shader.Sdf,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'sdf',
        vertex_shader = 'sdf.vertex',
        fragment_shader = 'sdf.fragment'
     }
  },
  {
     id = Shader.SdfNormal,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'sdf_normal',
        vertex_shader = 'sdf_normal.vertex',
        fragment_shader = 'sdf_normal.fragment'
     }
  },
  {
     id = Shader.LightMap,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'light_map',
        vertex_shader = 'light_map.vertex',
        fragment_shader = 'light_map.fragment'
     }
  },
  {
     id = Shader.Solid,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'solid',
        vertex_shader = 'solid.vertex',
        fragment_shader = 'solid.fragment'
     }
  },
  {
     id = Shader.Sprite,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'sprite',
        vertex_shader = 'sprite.vertex',
        fragment_shader = 'sprite.fragment'
     }
  },
  {
     id = Shader.Text,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'text',
        vertex_shader = 'text.vertex',
        fragment_shader = 'text.fragment'
     }
  },
  {
     id = Shader.PostProcess,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'post_process',
        vertex_shader = 'post_process.vertex',
        fragment_shader = 'post_process.fragment'
     }
  },
  {
     id = Shader.Blit,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'blit',
        vertex_shader = 'blit.vertex',
        fragment_shader = 'blit.fragment'
     }
  },
  {
     id = Shader.Particle,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'particle',
        vertex_shader = 'particle.vertex',
        fragment_shader = 'particle.fragment'
     }
  },
  {
     id = Shader.Fluid,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'fluid',
        vertex_shader = 'fluid.vertex',
        fragment_shader = 'fluid.fragment'
     }
  },
  {
     id = Shader.FluidEulerian,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'fluid_eulerian',
        vertex_shader = 'fluid_eulerian.vertex',
        fragment_shader = 'fluid_eulerian.fragment'
     }
  },
  {
     id = Shader.Scanline,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'scanline',
        vertex_shader = 'scanline.vertex',
        fragment_shader = 'scanline.fragment'
     }
  },
  {
     id = Shader.Bloom,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'bloom',
        vertex_shader = 'bloom.vertex',
        fragment_shader = 'bloom.fragment'
     }
  },
  {
     id = Shader.ChromaticAberration,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Graphics,
        name = 'chromatic_aberration',
        vertex_shader = 'chromatic_aberration.vertex',
        fragment_shader = 'chromatic_aberration.fragment'
     }
  },
  {
     id = Shader.FluidInit,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Compute,
        name = 'fluid_init',
        compute_shader = 'fluid_init.compute',
     }
  },
  {
     id = Shader.FluidUpdate,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Compute,
        name = 'fluid_update',
        compute_shader = 'fluid_update.compute',
     }
  },
  {
     id = Shader.FluidEulerianInit,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Compute,
        name = 'fluid_eulerian_init',
        compute_shader = 'fluid_eulerian_init.compute',
     }
  },
  {
     id = Shader.FluidEulerianUpdate,
     descriptor = {
        kind = tdengine.enums.GpuShaderKind.Compute,
        name = 'fluid_eulerian_update',
        compute_shader = 'fluid_eulerian_update.compute',
     }
  },
}