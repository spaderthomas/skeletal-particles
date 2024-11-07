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
		'GpuMemoryBarrier',
		{
			ShaderStorage = tdengine.ffi.GpuMemoryBarrier_ShaderStorage,
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

	tdengine.enum.define(
		'Sdf',
		{
			Circle = 0,
			Ring = 1,
			Box = 2,
			OrientedBox = 3,
			}
	)
	
	imgui.internal.init_c_api()
	imgui.internal.init_lua_api()
	imgui.internal.init_lua_api_overwrites()

	local header = tdengine.module.read_from_named_path('ffi_info')
	ffi.cdef(header)
end


function tdengine.ffi.field_ptr(cdata, member)
	local inner_type = tdengine.ffi.inner_type(member)
	local type_name = tdengine.ffi.type_name(inner_type)
	local byte_ptr = ffi.cast('u8*', cdata)
	return ffi.cast(type_name .. '*', byte_ptr + member.offset)
end

function tdengine.ffi.type_name(inner_type)
	local ctype = tdengine.enums.ctype

	local type_name = inner_type.what
	if ctype.float:match(inner_type.what) then
		if inner_type.size == 4 then
			type_name = 'float'
		elseif inner_type.size == 8 then
			type_name = 'double'
		end
	elseif ctype.int:match(inner_type.what) then
		if inner_type.unsigned then
			if inner_type.size == 1 then
				type_name = 'uint8_t'
			elseif inner_type.size == 2 then
				type_name = 'uint16_t'
			elseif inner_type.size == 4 then
				type_name = 'uint32_t'
			elseif inner_type.size == 8 then
				type_name = 'uint64_t'
			end
		else
			if inner_type.size == 1 then
				type_name = 'int8_t'
			elseif inner_type.size == 2 then
				type_name = 'int16_t'
			elseif inner_type.size == 4 then
				type_name = 'int32_t'
			elseif inner_type.size == 8 then
				type_name = 'int64_t'
			end
		end
	end

	return type_name
end

function tdengine.ffi.imgui_datatype(inner_type)
	local ctype = tdengine.enums.ctype

	local type_name = inner_type.what
	if ctype.float:match(inner_type.what) then
		if inner_type.size == 4 then
			type_name = ffi.C.ImGuiDataType_Float
		elseif inner_type.size == 8 then
			type_name = ffi.C.ImGuiDataType_Double
		end
	elseif ctype.int:match(inner_type.what) then
		if inner_type.unsigned then
			if inner_type.size == 1 then
				type_name = ffi.C.ImGuiDataType_U8
			elseif inner_type.size == 2 then
				type_name = ffi.C.ImGuiDataType_U16
			elseif inner_type.size == 4 then
				type_name = ffi.C.ImGuiDataType_U32
			elseif inner_type.size == 8 then
				type_name = ffi.C.ImGuiDataType_U64
			end
		else
			if inner_type.size == 1 then
				type_name = ffi.C.ImGuiDataType_S8
			elseif inner_type.size == 2 then
				type_name = ffi.C.ImGuiDataType_S16
			elseif inner_type.size == 4 then
				type_name = ffi.C.ImGuiDataType_S32
			elseif inner_type.size == 8 then
				type_name = ffi.C.ImGuiDataType_S64
			end
		end
	end

	return type_name
end

function tdengine.ffi.imgui_datatypeof(cdata)
	return tdengine.ffi.imgui_datatype(tdengine.ffi.inner_typeof(cdata))
end

function tdengine.ffi.pretty_type(type_info)
	local ctype = tdengine.enums.ctype

	local inner_type = tdengine.ffi.inner_type(type_info)

	-- p(type_info)
	local type_name = inner_type.what
	if ctype.float:match(inner_type.what) then
		if inner_type.size == 4 then
			type_name = 'f32'
		elseif inner_type.size == 8 then
			type_name = 'f64'
		end
	elseif ctype.int:match(inner_type.what) then
		if inner_type.bool then
			return 'bool'
		elseif inner_type.unsigned then
			if inner_type.size == 1 then
				type_name = 'u8'
			elseif inner_type.size == 2 then
				type_name = 'u16'
			elseif inner_type.size == 4 then
				type_name = 'u32'
			elseif inner_type.size == 8 then
				type_name = 'u64'
			end
		else
			if inner_type.size == 1 then
				type_name = 's8'
			elseif inner_type.size == 2 then
				type_name = 's16'
			elseif inner_type.size == 4 then
				type_name = 's32'
			elseif inner_type.size == 8 then
				type_name = 's64'
			end
		end
	elseif ctype.struct:match(inner_type.what) then
		return inner_type.name or string.format('struct %d', inner_type.typeid)
	end

	return type_name

end

function tdengine.ffi.pretty_typeof(cdata)
	return tdengine.ffi.pretty_type(tdengine.ffi.typeof(cdata))
end

function tdengine.ffi.pretty_ptr(type_info)
	return string.format('%s*', tdengine.ffi.pretty_type(type_info))
end

function tdengine.ffi.pretty_ptrof(cdata)
	return string.format('%s*', tdengine.ffi.pretty_type(tdengine.ffi.typeof(cdata)))
end




function tdengine.ffi.address_of(cdata)
	local s = tostring(cdata)
	local parts = s:split(':')
	return parts[2]:gsub(' ', '')
end

function tdengine.ffi.sorted_members(type_info)
	local members = {}
	for member in type_info:members() do
		table.insert(members, member)
	end

	table.sort(members, function (a, b)
		local A_FIRST = false
		local B_FIRST = true

		local inner_type_a = tdengine.ffi.inner_type(a)
		local is_a_struct = tdengine.enums.ctype.struct:match(inner_type_a.what)
		local inner_type_b = tdengine.ffi.inner_type(b)
		local is_b_struct = tdengine.enums.ctype.struct:match(inner_type_b.what)

		if is_a_struct and not is_b_struct then
			return B_FIRST
		elseif not is_a_struct and is_b_struct then
			return A_FIRST
		else
			return a.name < b.name
		end
	end)

	return tdengine.iterator.values(members)
end

function tdengine.ffi.typeof(cdata)
	return reflect.typeof(cdata)
end

function tdengine.ffi.inner_typeof(cdata)
	return tdengine.ffi.inner_type(reflect.typeof(cdata))
end

function tdengine.ffi.inner_type(type_info)
	local ctype = tdengine.enums.ctype

	if ctype.ref:match(type_info.what) then
		type_info = type_info.element_type
	elseif ctype.ptr:match(type_info.what) then
		type_info = type_info.element_type
	elseif ctype.field:match(type_info.what) then
		type_info = tdengine.ffi.inner_type(type_info.type)
	end

	return type_info
end

function tdengine.ffi.is_opaque(cdata)
	return tdengine.ffi.inner_typeof(cdata).size == 'none'
end


Matrix3 = tdengine.class.metatype('Matrix3')

function Matrix3:Identity()
	local matrix = Matrix3:new()
	matrix.data[0][0] = 1
	matrix.data[1][1] = 1
	matrix.data[2][2] = 1
	return matrix
end

function Matrix3:init(data)
	if data then
		for i = 0, 2 do
			for j = 0, 2 do
				self.data[i][j] = data[i + 1][j + 1]
			end
		end
	end	
end

function Matrix3:serialize()
	local serialized = {}

	for i = 0, 2 do
		serialized[i + 1] = {}
		for j = 0, 2 do
			serialized[i + 1][j + 1] = self.data[i][j]
		end
	end
	return serialized
end


SdfCircle = tdengine.class.metatype('SdfCircle')

function SdfCircle:init(px, py, radius, edge_thickness)
  self.position.x = px
  self.position.y = py
  self.radius = radius
	self.edge_thickness = edge_thickness
end

tdengine.enum.define(
	'ctype',
	{
		void = 0,
		int = 1,
		float = 2,
		enum = 3,
		constant = 4,
		ptr = 5,
		ref = 6,
		array = 7,
		struct = 8,
		union = 9,
		func = 10,
		field = 11,
		bitfield = 12
	}
)


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