function tdengine.ffi.namespaced_metatype(namespace, struct_name)
	ffi.metatype(struct_name, {
		__index = function(struct_instance, fn_name)
			return ffi.C[namespace .. '_' .. fn_name]
		end
	})
end

function tdengine.ffi.init()
	setmetatable(
		tdengine.ffi,
		{
			__index = function(self, key)
				local wrapper = rawget(self, key)
				if wrapper then return wrapper end

				local found, value = pcall(function() return ffi.C[key] end)
				if found then return value end
			end
		}
	)

	local string_metatable = {
		__index = {
			to_interned = function(self)
				return ffi.string(self.data)
			end,
		}
	}
	ffi.metatype('tstring', string_metatable)
	ffi.metatype('string', string_metatable)

	tdengine.ffi.namespaced_metatype('ma', 'MemoryAllocator')

	tdengine.enum.define(
		'CoordinateSystem',
		{
			World = tdengine.ffi.CoordinateSystem_World,
			Screen = tdengine.ffi.CoordinateSystem_Screen,
			Window = tdengine.ffi.CoordinateSystem_Window,
			Game = tdengine.ffi.CoordinateSystem_Game,
		}
	)

	tdengine.enum.define(
		'ParticleKind',
		{
			Quad = tdengine.ffi.ParticleKind_Quad,
			Circle = tdengine.ffi.ParticleKind_Circle,
			Image = tdengine.ffi.ParticleKind_Image,
			Invalid = tdengine.ffi.ParticleKind_Invalid,
		}
	)

	tdengine.enum.define(
		'BlendMode',
		{
			ZERO = tdengine.ffi.ZERO,
			ONE = tdengine.ffi.ONE,
			SRC_COLOR = tdengine.ffi.SRC_COLOR,
			ONE_MINUS_SRC_COLOR = tdengine.ffi.ONE_MINUS_SRC_COLOR,
			DST_COLOR = tdengine.ffi.DST_COLOR,
			ONE_MINUS_DST_COLOR = tdengine.ffi.ONE_MINUS_DST_COLOR,
			SRC_ALPHA = tdengine.ffi.SRC_ALPHA,
			ONE_MINUS_SRC_ALPHA = tdengine.ffi.ONE_MINUS_SRC_ALPHA,
			DST_ALPHA = tdengine.ffi.DST_ALPHA,
			ONE_MINUS_DST_ALPHA = tdengine.ffi.ONE_MINUS_DST_ALPHA,
			CONSTANT_COLOR = tdengine.ffi.CONSTANT_COLOR,
			ONE_MINUS_CONSTANT_COLOR = tdengine.ffi.ONE_MINUS_CONSTANT_COLOR,
			CONSTANT_ALPHA = tdengine.ffi.CONSTANT_ALPHA,
			ONE_MINUS_CONSTANT_ALPHA = tdengine.ffi.ONE_MINUS_CONSTANT_ALPHA,
			SRC_ALPHA_SATURATE = tdengine.ffi.SRC_ALPHA_SATURATE,
			SRC1_COLOR = tdengine.ffi.SRC1_COLOR,
			ONE_MINUS_SRC1_COLOR = tdengine.ffi.ONE_MINUS_SRC1_COLOR,
			SRC1_ALPHA = tdengine.ffi.SRC1_ALPHA,
			ONE_MINUS_SRC1_ALPHA = tdengine.ffi.ONE_MINUS_SRC1_ALPHA
		}
	)

	tdengine.enum.define(
		'WindowFlags',
		{
			None = 0,
			Windowed = 1,
			Border = 2,
			Vsync = 4
		}
	)

	tdengine.enum.define(
		'VertexAttributeKind',
		{
			Float = tdengine.ffi.VertexAttributeKind_Float,
		}
	)

	tdengine.enum.define(
		'DrawMode',
		{
			Triangles = tdengine.ffi.DrawMode_Triangles,
		}
	)

	tdengine.enum.define(
		'GlId',
		{
			Framebuffer = tdengine.ffi.GlId_Framebuffer,
			Shader = tdengine.ffi.GlId_Shader,
			Program = tdengine.ffi.GlId_Program,
		}
	)


	tdengine.enum.define(
		'DisplayMode',
		{
			p480 = 0,
			p720 = 1,
			p1080 = 2,
			p1440 = 3,
			p2160 = 4,
			p1280_800 = 5,
			Fullscreen = 6,
		}
	)

	tdengine.enum.define(
		'GpuLoadOp',
		{
			None = 0,
			Clear = 1,
		}
	)


	imgui.internal.init_c_api()
	imgui.internal.init_lua_api()
	imgui.internal.init_lua_api_overwrites()

end



function tdengine.ffi.draw_line(ax, ay, bx, by, thickness, color)
	ffi.C.draw_line(
		ffi.new('Vector2', ax, ay),
		ffi.new('Vector2', bx, by),
		thickness,
		color
	)
end

function tdengine.draw_line(ax, ay, bx, by, thickness, color)
	ffi.C.draw_line(
		ffi.new('Vector2', ax, ay),
		ffi.new('Vector2', bx, by),
		thickness,
		tdengine.color_to_vec4(color)
	)
end

function tdengine.ffi.draw_image_l(image, position, size, opacity)
	ffi.C.draw_image_ex(image, position.x, position.y, size.x, size.y, opacity or 1.0)
end


function tdengine.ffi.draw_line_l(a, b, thickness, color)
	ffi.C.draw_line(a:to_ctype(), b:to_ctype(), thickness, tdengine.color_to_vec4(color))
end

function tdengine.ffi.draw_circle_l(position, radius, color, edge_thickness)
	ffi.C.draw_circle_sdf(position.x, position.y, radius, color:to_vec4(), edge_thickness or 2)
end

function tdengine.ffi.draw_quad_l(position, size, color)
	ffi.C.draw_quad(position:to_ctype(), size:to_ctype(), tdengine.color_to_vec4(color))
end

function tdengine.ffi.draw_quad_l_c(px, py, sx, sy, color)
	ffi.C.draw_quad(ffi.new('Vector2', px, py), ffi.new('Vector2', sx, sy), tdengine.color_to_vec4(color))
end

function tdengine.set_blend_enabled(enabled)
	tdengine.ffi.set_blend_enabled(enabled)
end

function tdengine.set_blend_mode(source, dest)
	tdengine.ffi.set_blend_mode(source:to_number(), dest:to_number())
end

function tdengine.get_mouse(coordinate)
	local coordinate = coordinate or tdengine.coordinate.world
	return tdengine.vec2(tdengine.cursor(coordinate))
end

function tdengine.ffi.draw_quad(px, py, sx, sy, color)
	ffi.C.draw_quad(ffi.new('Vector2', px, py), ffi.new('Vector2', sx, sy), color)
end


function tdengine.ffi.get_display_mode()
	return tdengine.enums.DisplayMode(ffi.C.get_display_mode())
end

function tdengine.ffi.set_draw_mode(mode)
	return ffi.C.set_draw_mode(mode:to_number())
end

function tdengine.ffi.set_display_mode(display_mode)
	return ffi.C.set_display_mode(display_mode:to_number())
end

function tdengine.ffi.begin_world_space()
	tdengine.ffi.set_world_space(true)
end

function tdengine.ffi.end_world_space()
	tdengine.ffi.set_world_space(false)
end

function tdengine.ffi.gpu_clear_target(target)
	ffi.C.gpu_clear_target(target)
end

function tdengine.ffi.push_fullscreen_quad()
	local n = ffi.C.get_native_resolution()
	local uvs = nil
	local opacity = 1.0
	ffi.C.push_quad(0, n.y, n.x, n.y, uvs, opacity);
end

function tdengine.ffi.set_uniform_enum(name, value)
	tdengine.ffi.set_uniform_i32(name, value:to_number())
end

function tdengine.ffi.is_nil(cdata)
	return cdata == nil
end
