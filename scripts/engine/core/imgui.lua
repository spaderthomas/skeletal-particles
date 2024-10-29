-- https://github.com/sonoro1234/LuaJIT-ImGui/blob/docking_inter/lua/imgui/glfw.lua
--
-- CImGui wraps ImGui by more or les hand-mangling the symbols in a consistent way (e.g. igPushStyleVar_Float). We could
-- stop here and call these directly, but it's not ergonomic. The FFI requires you pass every parameter to a function,
-- and ImGui is full of rarely used parameters which are meant to be optional.
--
-- This file is a second autogenerated(?) binding layer which wraps the C API with functions that (again, more or less)
-- un-mangle the symbols and provide a bootleg form of function overloading. It's qctually quite ugly; most of the functions
-- in here check the types of their arguments, and dispatch to the C API. But, it's ergonomic.
--
-- The only caveat is that there are some functions which:
-- 1. Returned a tuple in the old bindings but a vector in the new ones, and I'm too lazy to fix every instance (e.g. GetItemRectSize) 
-- 2. Are from some ImGui extension not included in CImGui (e.g. ImFileBrowser)
-- 3. Require actual extra functionality to be ergonomic (e.g. Input*)
--
-- Call the C API IMGUI_LAYER_1, the Lua API IMGUI_LAYER_2, and my (few) caveats IMGUI_LAYER_3.
--
-- This file contains IMGUI_LAYER_2 and IMGUI_LAYER_3. Layer 2 is pulled straight from the above link, but I modified it
-- to not use require() and stuck it in a function so I can control when it's initialized.

-- IMGUI_LAYER_1
function imgui.internal.init_c_api()
	local header = tdengine.module.read_from_named_path('cimgui_header')
	ffi.cdef(header)
end


-- IMGUI_LAYER_2
function imgui.internal.init_lua_api()
  local function exists_in_ffi(fn_name)
    local success, fn = pcall(function() return ffi.C[fn_name] end)
    return success and type(fn) == "cdata"
  end
  
  local function ffi_or_stub(fn_name)
    if not exists_in_ffi(fn_name) then
      log.warn('CImGui function was not exported; fn = %s', fn_name)
      return function() end
    end
  
    return ffi.C[fn_name]
  end
  
  -- The original code expects ImGui to be compiled into a library (...?), and so expects lib to be the result
  -- of ffi.load(). I do not do that, so just point it at ffi.C
  local lib = {}
  setmetatable(lib, {
    __index = function(t, k)
      return ffi_or_stub(k)
    end
  })

  -- This is the namespace that the engine will use to call ImGui functions
  imgui.internal.load_imgui_lua_wrapper_verbatim_from_sonoro1234(lib, imgui)
end


-- IMGUI_LAYER_3
function imgui.internal.init_lua_api_overwrites()
	function imgui.IsMouseClicked(button)
		return ffi.C.igIsMouseClicked_Bool(button, false)
	end

	function imgui.Dummy(x, y)
		return ffi.C.igDummy(imgui.ImVec2(x, y))
	end
	
	function imgui.SetCursorScreenPos(x, y)
		return ffi.C.igSetCursorScreenPos(imgui.ImVec2(x, y))
	end
	
	function imgui.PushStyleVar_2(var, x, y)
		return ffi.C.igPushStyleVar_Vec2(var, imgui.ImVec2(x, y))
	end

	function imgui.SetNextWindowSize(x, y)
		return ffi.C.igSetNextWindowSize(imgui.ImVec2(x, y), 0)
	end

	function imgui.SetNextWindowPos(x, y)
		return ffi.C.igSetNextWindowPos(imgui.ImVec2(x, y), 0, imgui.ImVec2(0, 0))
	end

	function imgui.GetItemRectSize()
		local as_imvec = ffi.new("ImVec2")
		ffi.C.igGetItemRectSize(as_imvec)
		return as_imvec.x, as_imvec.y
	end
	
	function imgui.GetItemRectMin()
		local as_imvec = ffi.new("ImVec2")
		ffi.C.igGetItemRectMin(as_imvec)
		return as_imvec.x, as_imvec.y
	end
	
	function imgui.GetCursorScreenPos()
		local as_imvec = ffi.new("ImVec2")
		ffi.C.igGetCursorScreenPos(as_imvec)
		return as_imvec.x, as_imvec.y
	end
	
	function imgui.GetContentRegionAvail()
		local as_imvec = ffi.new("ImVec2")
		ffi.C.igGetContentRegionAvail(as_imvec)
		return as_imvec.x, as_imvec.y
	end
	
	function imgui.GetWindowPos()
		local as_imvec = ffi.new("ImVec2")
		ffi.C.igGetWindowPos(as_imvec)
		return as_imvec.x, as_imvec.y
	end

	function imgui.InvisibleButton(label, sx, sy, flags)
		flags = flags or 0
		return ffi.C.igInvisibleButton(label, ffi.new('ImVec2', sx, sy), flags)
	end


	function imgui.PushFont(font_name)
		ffi.C.IGE_PushGameFont(font_name)
	end

	function imgui.GameImage(image, sx, sy)
		sx = sx or 0
		sy = sy or 0
		ffi.C.IGE_GameImage(image, sx, sy)
	end

	function imgui.OpenFileBrowser()
		ffi.C.IGE_OpenFileBrowser()
	end

	function imgui.CloseFileBrowser()
		ffi.C.IGE_CloseFileBrowser()
	end

	function imgui.SetFileBrowserWorkDir(directory)
		ffi.C.IGE_SetFileBrowserWorkDir(directory)
	end

	function imgui.IsAnyFileSelected()
		return ffi.C.IGE_IsAnyFileSelected()
	end

	function imgui.GetSelectedFile()
		return ffi.C.IGE_GetSelectedFile():to_interned()
	end


	function imgui.Checkbox(label, t, k)
		local value = ffi.new('bool [1]', t[k])
		local changed = ffi.C.igCheckbox(label, value)
	
		t[k] = value[0]
	
		return changed
	end

	-- ImGui expects that we're using a static buffer here, so when we add more characters than there is room for and it
	-- resizes its internal buffer, it expects that we need to reuse ours too. However, this is all implemented with 
	-- temporary storage; every frame, I copy the interned Lua string into a temporary storage string. 
	--
	-- Because of that, I never need to "resize" my string buffer. However, ImGui requires us to pass a callback anyway.
	local empty_resize_callback = ffi.cast("ImGuiInputTextCallback", function(data)
		return 0
	end)

	local max_chars_per_frame = 8

	function imgui.InputText(label, t, k, flags)
		local value = t[k]
		local len = #value

		local allocator = tdengine.ffi.ma_find('bump')
		local buffer_len = len + max_chars_per_frame
		local buffer = allocator:alloc(buffer_len)
		tdengine.ffi.copy_string_n(value, len, buffer, buffer_len)
	
		flags = flags or 0
		flags = bitwise(tdengine.op_or, flags, ffi.C.ImGuiInputTextFlags_CallbackResize)
		local callback = empty_resize_callback
		local userdata = nil
		local changed = ffi.C.igInputText(label, buffer, buffer_len, flags, callback, userdata)
	
		t[k] = ffi.string(buffer)
		return changed
	end

	function imgui.InputFloat(label, t, k, step, step_fast, format, flags)
		local value = ffi.new('float [1]', t[k])
	
		step = step or 0
		step_fast = step_fast or 0
		format = format or "%.3f"
		flags = flags or 0
		local changed = ffi.C.igInputFloat(label, value, step, step_fast, format, flags)
	
		t[k] = value[0]
	
		return changed
	end

	function imgui.ColorPicker4(label, t, k, flags)
		local value = t[k]:to_floats()
	
		flags = flags or 0
		local ref_col = nil
		local changed = ffi.C.igColorPicker4(label, value, flags, ref_col)
	
		t[k] = tdengine.color(value)
	
		return changed
	end
end
