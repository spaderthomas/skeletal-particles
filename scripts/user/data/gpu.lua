return {
	resolutions = {
		{
			id = Resolution.Native,
			size = {
				x = 320,
				y = 180
			}
		},
		{
			id = Resolution.Upscaled,
			size = {
				x = 1024,
				y = 576
			}
		},
	},
	render_targets = {
		{
			id = RenderTarget.Color,
			descriptor = {
				resolution = Resolution.Native,
			}
		},
		{
			id = RenderTarget.Normals,
			descriptor = {
				resolution = Resolution.Native,
			}
		},
		{
			id = RenderTarget.LightMap,
			descriptor = {
				resolution = Resolution.Native,
			}
		},
		{
			id = RenderTarget.LitScene,
			descriptor = {
				resolution = Resolution.Native,
			}
		},
		{
			id = RenderTarget.UpscaledColor,
			descriptor = {
				resolution = Resolution.Upscaled,
			}
		},
		{
			id = RenderTarget.UpscaledNormals,
			descriptor = {
				resolution = Resolution.Upscaled,
			}
		},
		{
			id = RenderTarget.UpscaledLitScene,
			descriptor = {
				resolution = Resolution.Upscaled,
			}
		},
	},

	command_buffers = {
		{
			id = CommandBuffer.Color,
			descriptor = {
				max_vertices = 1024,
				max_draw_calls = 64,
				vertex_attributes = {
					{
						count = 3,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 4,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 2,
						kind = tdengine.enums.VertexAttributeKind.Float
					}
				}
			}
		},
		{
			id = CommandBuffer.Normals,
			descriptor = {
				max_vertices = 1024,
				max_draw_calls = 64,
				vertex_attributes = {
					{
						count = 3,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 4,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 2,
						kind = tdengine.enums.VertexAttributeKind.Float
					}
				}
			}
		},
		{
			id = CommandBuffer.Upscale,
			descriptor = {
				max_vertices = 1024,
				max_draw_calls = 64,
				vertex_attributes = {
					{
						count = 3,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 4,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 2,
						kind = tdengine.enums.VertexAttributeKind.Float
					}
				}
			}
		},
		{
			id = CommandBuffer.LightMap,
			descriptor = {
				max_vertices = 1024,
				max_draw_calls = 64,
				vertex_attributes = {
					{
						count = 3,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 4,
						kind = tdengine.enums.VertexAttributeKind.Float
					},
					{
						count = 2,
						kind = tdengine.enums.VertexAttributeKind.Float
					}
				}
			}
		},
	},

	graphics_pipelines = {
		{
			id = RenderPass.Color,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.Color,
					load_op = tdengine.enums.GpuLoadOp.Clear
				}
			}
		},
		{
			id = RenderPass.Normals,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.Normals,
					load_op = tdengine.enums.GpuLoadOp.Clear
				}
			}
		},
		{
			id = RenderPass.VisualizeLightMap,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.LightMap,
					load_op = tdengine.enums.GpuLoadOp.Clear
				}
			}
		},
		{
			id = RenderPass.LightScene,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.LitScene,
					load_op = tdengine.enums.GpuLoadOp.Clear
				},
				shader = Shader.ApplyLighting,
				uniforms = {
					{
						name = 'light_map',
						kind = tdengine.enums.UniformKind.RenderTarget,
						-- actually, color attachment means "pull the read texture from some render pass' color attachment"
						value = RenderTarget.LightMap
					},
					{
						name = 'color_buffer',
						kind = tdengine.enums.UniformKind.RenderTarget,
						value = RenderTarget.Color
					},
					{
						name = 'normal_buffer',
						kind = tdengine.enums.UniformKind.RenderTarget,
						value = RenderTarget.Normals
					},
					{
						name = 'editor',
						kind = tdengine.enums.UniformKind.RenderTarget,
						value = RenderTarget.LightMap -- @fix
					},
					{
						name = 'num_lights',
						kind = tdengine.enums.UniformKind.I32,
						value = 0
					}
				},
				ssbos = {
					{
						id = StorageBuffer.Lights
					}
				}
			}
		},
		{
			id = RenderPass.UpscaleColor,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.UpscaledColor,
					load_op = tdengine.enums.GpuLoadOp.Clear
				}
			}
		},
		{
			id = RenderPass.UpscaleNormals,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.UpscaledNormals,
					load_op = tdengine.enums.GpuLoadOp.Clear
				}
			}
		},
		{
			id = RenderPass.UpscaleLitScene,
			descriptor = {
				color_attachment = {
					read = nil,
					write = RenderTarget.UpscaledLitScene,
					load_op = tdengine.enums.GpuLoadOp.Clear
				}
			}
		}
	}

}
