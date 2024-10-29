-- UTILITIES
local types = {
	'number',
	'string',
	'bool',
	'table'
}

local function find_sorted_keys(t)
	local sorted_keys = {}
	for key, value in pairs(t) do
		table.insert(sorted_keys, key)
	end

	local compare_keys = function(k1, k2)
		local v1 = t[k1]
		local v2 = t[k2]
		if type(k1) == 'number' and type(k2) == 'number' then
			return k1 < k2
		elseif type(v1) == 'table' and type(v2) == 'table' then
			if v1.__enum and not v2.__enum then
				return false
			elseif not v1.__enum and v2.__enum then
				return true
			end
			return tostring(k1) < tostring(k2)
		elseif type(v1) == 'table' and type(v2) ~= 'table' then
			if v1.__enum then
				return tostring(k1) < tostring(k2)
			end
			return true
		elseif type(v1) ~= 'table' and type(v2) == 'table' then
			if v2.__enum then
				return tostring(k1) < tostring(k2)
			end
			return false
		elseif type(v1) ~= 'table' and type(v2) ~= 'table' then
			return tostring(k1) < tostring(k2)
		end
	end

	table.sort(sorted_keys, compare_keys)
	return sorted_keys
end

--
-- TABLE
--
imgui.extensions.TableField = function(key, value)
	local value_type = type(value)
	if value_type == 'string' then
		imgui.extensions.VariableName(key)
		imgui.SameLine()
		imgui.PushTextWrapPos(0)
		imgui.Text(value)
		imgui.PopTextWrapPos()
	elseif value_type == 'number' then
		imgui.extensions.VariableName(key)
		imgui.SameLine()
		imgui.Text(tostring(value))
	elseif value_type == 'boolean' then
		imgui.extensions.VariableName(key)
		imgui.SameLine()
		imgui.Text(tostring(value))
	elseif value_type == 'table' then
		imgui.extensions.TableMenuItem(key, value)
	end
end

imgui.extensions.Table = function(t, ignore)
	ignore = ignore or {}

	local sorted_keys = find_sorted_keys(t)

	for index, key in pairs(sorted_keys) do
		if ignore[key] then goto continue end
		if tdengine.editor.is_ignoring_field(t, key) then goto continue end

		imgui.extensions.TableField(key, t[key])

		::continue::
	end
end

imgui.extensions.TableMenuItem = function(name, t)
	local address = table_address(t)
	local imgui_id = tostring(name) .. '##' .. address

	if imgui.TreeNode(imgui_id) then
		imgui.extensions.Table(t)
		imgui.TreePop()
	end
end



--
-- TABLE EDITOR
--
imgui.extensions.TableEditor = function(editing, params)
	if not editing then dbg() end
	if not params then params = {} end
	local editor = {
		depth = params.depth or 0,
		enter_returns_true = params.enter_returns_true or false,
		on_end = params.on_end or nil,
		is_table_editor = true,
		key_id = tdengine.uuid_imgui(),
		value_id = tdengine.uuid_imgui(),
		type_id = tdengine.uuid_imgui(),
		selected_type = 'string',
		editing = editing,
		children = {},
		imgui_ignore = params.imgui_ignore or {},
		array_replace_name = params.array_replace_name or nil,
		draw_field_add = params.draw_field_add or false,
		child_field_add = params.child_field_add or false,
		field_add_key = '',
		field_add_value = '',	
		context_menu_item = nil,
		seen = params.seen or {},
		draw = function(self) return imgui.internal.draw_table_editor(self) end,
		clear = function(self) imgui.internal.clear_table_editor(self) end,
		ignore = function(self, k) self.imgui_ignore[k] = true end,
		is_field_ignored = function(self, k)
			local ignore = false
			ignore = ignore or self.imgui_ignore[k]
			if self.editing.imgui_ignore then
				ignore = ignore or self.editing.imgui_ignore[k]
			end
			return ignore
		end,
		is_self_referential = function(self, t)
			local address = table_address(t)
			return self.seen[address]
		end,
		is_enum = function(self, t)
			return type(t) == 'table' and t.__enum
		end,
		add_child = function(self, key)
			local value = self.editing[key]
			if type(value) ~= 'table' then return end
			if self.imgui_ignore[key] then return end

			recurse = true
			recurse = recurse and not (value == self.editing)
			recurse = recurse and not self.editing.is_table_editor
			recurse = recurse and not self:is_field_ignored(key)
			recurse = recurse and not self:is_self_referential(value)
			recurse = recurse and not self:is_enum(value)
			if recurse then
				local params = imgui.internal.propagate_table_editor_params(self)
				self.children[key] = imgui.extensions.TableEditor(value, params)
			end
		end
	}

	editor.imgui_ignore.imgui_ignore = true
	editor.imgui_ignore.__type = true
	editor.imgui_ignore.__internal = true
	editor.seen[table_address(editor.editing)] = true

	-- Each child member that is a non-recursive table also gets an editor
	for key, child in pairs(editing) do
		editor:add_child(key)
	end

	return editor
end

imgui.internal.draw_table_editor = function(editor)
	-- If the user right clicked a sub-table, we show a prompt to add an entry to the sub-table.
	-- Record whether a field was added in this way to return to the user
	local field_added = false
	if editor.draw_field_add then print('small'); field_added = imgui.internal.draw_table_field_add(editor) end

	local field_changed = false
	local fields_changed = {}
	local mark_field_changed = function(field)
		field_changed = true
		table.insert(fields_changed, field)
	end

	-- Figure out ImGui stuff for alignment
	local cursor = imgui.GetCursorPosX()
	local padding = imgui.internal.table_editor_padding(editor)
	local open_item_context_menu = false

	local sorted_keys = find_sorted_keys(editor.editing)

	-- Display each KVP
	for _, key in ipairs(sorted_keys) do
		local value = editor.editing[key]

		-- Skip the variable if it's in the imgui_ignore for either the editor, or the table being edited
		local display = true
		display = display and not editor.imgui_ignore[key]
		if editor.editing.imgui_ignore then
			display = display and (not editor.editing.imgui_ignore[key])
		end

		if key == '__enum' then p(editor.editing[tdengine.editor.sentinel].ignore) end
		if tdengine.editor.is_ignoring_field(editor.editing, key) then
			display = false
		end

		-- Likewise, don't display imgui_ignore
		if key == 'imgui_ignore' then display = false end
		if key == tdengine.editor.sentinel then display = false end

		-- Assign a UNIQUE label to this entry
		local label = string.format('##%s', hash_table_entry(editor.editing, tostring(key)))

		local display_key = key
		if type(key) == 'number' and editor.array_replace_name then
			display_key = editor.array_replace_name(key, value)
		end

		-- This is a two-way binding. If ImGui says that the input box was edited, we take the value from C and put it into Lua.
		-- Otherwise, we take the value from Lua and put it into C, in case any value changes in the interpreter. This is slow -- it
		-- means we copy every string in all tables we're editing into C every frame. I can't think of a better way to do it, because
		-- there is no mechanism for triggering a callback whenever a string in Lua changes (nor would we want one) short of
		-- metatable insanity.
		if display then
			local variable_name_color = imgui.internal.table_editor_depth_color(editor.depth)

			-- Strings
			if type(value) == 'string' then
				imgui.extensions.VariableName(display_key, variable_name_color)
				if imgui.IsItemClicked(1) then
					open_item_context_menu = true; editor.context_menu_item = key
				end
				imgui.SameLine()
				imgui.SetCursorPosX(cursor + padding)
				imgui.PushItemWidth(-1)

				local flags = 0
				if editor.enter_returns_true then flags = ffi.C.ImGuiInputTextFlags_EnterReturnsTrue end

				if imgui.InputText(label, editor.editing, key, flags) then
					mark_field_changed(key)
				end

				imgui.PopItemWidth()

				-- Numbers
			elseif type(value) == 'number' then
				imgui.extensions.VariableName(display_key, variable_name_color)
				if imgui.IsItemClicked(1) then
					open_item_context_menu = true; editor.context_menu_item = key
				end
				imgui.SameLine()
				imgui.SetCursorPosX(cursor + padding)
				imgui.PushItemWidth(-1)
				if imgui.InputFloat(label, editor.editing, key) then
					mark_field_changed(key)
				end
				imgui.PopItemWidth()

				-- Booleans
			elseif type(value) == 'boolean' then
				imgui.extensions.VariableName(display_key, variable_name_color)
				if imgui.IsItemClicked(1) then
					open_item_context_menu = true; editor.context_menu_item = key
				end
				imgui.SameLine()
				imgui.SetCursorPosX(cursor + padding)
				imgui.PushItemWidth(-1)

				if imgui.Checkbox(label, editor.editing, key) then
					mark_field_changed(key)
				end
			elseif type(value) == 'cdata' then
				imgui.extensions.VariableName(display_key, variable_name_color)
				imgui.SameLine()
				imgui.SetCursorPosX(cursor + padding)
				imgui.PushItemWidth(-1)

				imgui.Text('<cdata>')
				imgui.PopItemWidth()

				-- Functions, trivialls
			elseif type(value) == 'function' then
				-- @spader 2/20/23: It's useful sometimes to see whether a function member is set,
				-- but I never use this, so don't do it to avoid clutter
				if false then
					imgui.extensions.VariableName(display_key, variable_name_color)
					imgui.SameLine()
					imgui.SetCursorPosX(cursor + padding)
					imgui.PushItemWidth(-1)

					imgui.Text('function')
					imgui.PopItemWidth()
				end
			elseif type(value) == 'thread' then

			-- Colors (at this point, we know it's a table)
			elseif tdengine.is_color_like(value) then
				local picker_flags = 0

				imgui.PushStyleColor(ffi.C.ImGuiCol_Text, variable_name_color:to_u32())
				if imgui.TreeNode(display_key .. label) then
					imgui.ColorPicker4(label, editor.editing, key, picker_flags)
					imgui.TreePop()
				end
				imgui.PopStyleColor()

			elseif editor:is_self_referential(value) then
				if false then
					imgui.extensions.VariableName(display_key, variable_name_color)
					imgui.SameLine()
					imgui.SetCursorPosX(cursor + padding)
					imgui.PushItemWidth(-1)

					imgui.Text('self referential')
					imgui.PopItemWidth()
				end

			elseif value.__enum then
				imgui.extensions.VariableName(display_key, variable_name_color)
				if imgui.IsItemClicked(1) then
					open_item_context_menu = true; 
					editor.context_menu_item = key
				end
				imgui.SameLine()
				imgui.SetCursorPosX(cursor + padding)
				imgui.PushItemWidth(-1)

				if imgui.BeginCombo(label, value:to_string()) then
					local enum_data = tdengine.enum_data[value.__enum]
					local enums = {}
					for name, _ in pairs(enum_data) do
						table.insert(enums, name)
					end
					table.sort(enum_data)

					for _, enum in pairs(enums) do
						if imgui.Selectable(enum) then
							editor.editing[key] = enum_data[enum]
							mark_field_changed(key)
						end
					end
					imgui.EndCombo()
				end
				imgui.PopItemWidth()

				-- All other tables
			elseif type(value) == 'table' then
				-- If this is the first time we've seen this sub-table, make an editor for it.
				if not editor.children[key] then
					local params = imgui.internal.propagate_table_editor_params(editor)
					editor.children[key] = imgui.extensions.TableEditor(value, params)
					mark_field_changed(key)
				end
				local child = editor.children[key]
				child.editing = value

				-- Here's where we draw the tree node for the child table. If it's down, we recurse. We
				-- also keep track of whether we'll need to open the modals
				local open_context_menu = false
				local unique_treenode_id = display_key .. label
				imgui.PushStyleColor(ffi.C.ImGuiCol_Text, variable_name_color:to_u32())
				if imgui.TreeNode(unique_treenode_id) then
					imgui.PopStyleColor()
					if imgui.IsItemClicked(1) then open_context_menu = true end
					sub_field_added, sub_field_changed = imgui.internal.draw_table_editor(child, seen)
					field_added = field_added or sub_field_added
					if sub_field_changed then mark_field_changed(key) end

					imgui.TreePop()
				else
					imgui.PopStyleColor()
					if imgui.IsItemClicked(1) then open_context_menu = true end
				end

				-- At this point, table + header are drawn. We've just got to show any popups.
				-- Show the context menu
				local open_field_editor = false
				local context_menu_id = label .. ':context_menu'
				if open_context_menu then
					imgui.OpenPopup(context_menu_id)
				end
				if imgui.BeginPopup(context_menu_id) then
					if imgui.MenuItem('Add field') then
						open_field_editor = true
					end
					imgui.EndPopup()
				end

				-- Show the aforementioned field editor modal
				local field_editor_id = label .. ':field_editor'
				if open_field_editor then
					imgui.OpenPopup(field_editor_id)
				end
				if imgui.BeginPopup(field_editor_id) then
					if imgui.internal.draw_table_field_add(child) then
						imgui.CloseCurrentPopup()
					end
					imgui.EndPopup()
				end

				::done_table::
			end
		end
	end

	-- If any variable was right clicked, we show a little context menu where you can delete it
	local item_context_menu_id = '##' .. hash_table_entry(editor.editing, editor.context_menu_item)
	if open_item_context_menu then
		imgui.OpenPopup(item_context_menu_id)
	end
	if imgui.BeginPopup(item_context_menu_id) then
		if imgui.Button('Delete') then
			editor.editing[editor.context_menu_item] = nil
			editor.context_menu_item = nil
			imgui.CloseCurrentPopup()
		end
		imgui.EndPopup()
	end

	if editor.on_done then editor.on_done() end

	for _, field in pairs(fields_changed) do
		tdengine.editor.run_editor_callback(editor.editing, 'on_change_field', field)
	end

	return field_added, field_changed
end

imgui.internal.draw_table_field_add = function(editor)
	imgui.PushItemWidth(80)
	if imgui.BeginCombo(editor.type_id, editor.selected_type) then
		for index, name in pairs(types) do
			if imgui.Selectable(name) then
				editor.selected_type = name
			end
		end
		imgui.EndCombo()
	end
	imgui.PopItemWidth()

	imgui.SameLine()
	imgui.extensions.VariableName('key')


	local enter_on_key = false
	local enter_on_value = false
	imgui.PushItemWidth(100)
	imgui.SameLine()
	if imgui.InputText(editor.key_id, editor, 'field_add_key', ffi.C.ImGuiInputTextFlags_EnterReturnsTrue) then
		enter_on_key = true
	end
	imgui.PopItemWidth()

	imgui.PushItemWidth(170)
	if editor.selected_type ~= 'table' then
		imgui.SameLine()
		imgui.extensions.VariableName('value')

		imgui.SameLine()
		if imgui.InputText(editor.value_id, editor, 'field_add_value', ffi.C.ImGuiInputTextFlags_EnterReturnsTrue) then
			enter_on_value = true
		end
	end

	if enter_on_key or enter_on_value then
		local key = editor.field_add_key
		key = tonumber(key) or key

		local value = editor.field_add_value

		editor.field_add_key = ''
		editor.field_add_value = ''

		if value == 'nil' then
			value = nil
		elseif editor.selected_type == 'number' then
			value = tonumber(value) or 0
		elseif editor.selected_type == 'string' then
			value = tostring(value) or ''
		elseif editor.selected_type == 'bool' then
			value = (value == 'true')
		elseif editor.selected_type == 'table' then
			local params = imgui.internal.propagate_table_editor_params(editor)
			editor.children[key] = imgui.extensions.TableEditor(value, params)
		end

		editor.editing[key] = value
		imgui.SetKeyboardFocusHere(-1)
	end
	imgui.PopItemWidth()

	return enter_on_key or enter_on_value
end

imgui.internal.table_editor_padding = function(editor)
	-- Very hacky way to line up the inputs: Figure out the largest key, then when drawing a key,
	-- use the difference in length between current key and largest key as a padding. Does not work
	-- that well, but kind of works
	local padding_threshold = 12
	local padding_target = 0
	for key, value in pairs(editor.editing) do
		local key_len = 0
		if type(key) == 'string' then key_len = #key end
		if type(key) == 'number' then key_len = #tostring(key) end -- whatever
		if type(key) == 'boolean' then key_len = #tostring(key) end
		padding_target = math.max(padding_target, key_len)
	end

	local min_padding = 80
	local padding = math.max(padding_target * 10, min_padding)
	return padding
end

imgui.internal.table_editor_depth_color = function(depth)
	colors = {
		tdengine.colors.celadon:copy(),
		tdengine.colors.cool_gray:copy(),
	}
	return colors[(depth % 2) + 1]
end

imgui.internal.propagate_table_editor_params = function(editor)
	local params = {}
	params.draw_field_add = editor.child_field_add
	params.depth = editor.depth + 1
	params.enter_returns_true = editor.enter_returns_true
	params.seen = table.shallow_copy(editor.seen)
	return params
end

imgui.internal.clear_table_editor = function(editor)
	editor.key_id = tdengine.uuid_imgui()
	editor.value_id = tdengine.uuid_imgui()
	editor.type_id = tdengine.uuid_imgui()
	editor.children = {}
end

--
-- WIDGETS
--
imgui.extensions.VariableName = function(name, color)
	color = color or tdengine.colors.celadon
	color = color:to_u32()
	imgui.PushStyleColor(ffi.C.ImGuiCol_Text, color)
	imgui.Text(tostring(name))
	imgui.PopStyleColor()
	if imgui.IsItemHovered() then
		sx, sy = imgui.GetItemRectSize();
		x, y = imgui.GetItemRectMin();
		px, py = 5, 3

		imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(x - px, y - py), imgui.ImVec2(x + sx + px, y + sy + py), color)
	end
end

imgui.extensions.Vec2 = function(name, v)
	if not name or not v then
		print(v)
		print('vec2 missing a parameter')
		return
	end
	imgui.extensions.VariableName(name)
	imgui.SameLine()
	imgui.Text('(' .. tostring(v.x) .. ', ' .. tostring(v.y) .. ')')
end

imgui.extensions.WhitespaceSeparator = function(whitespace)
	imgui.Dummy(0, whitespace)
	imgui.Separator()
	imgui.Dummy(0, whitespace)
end

imgui.extensions.CursorBubble = function(extents, color)
	extents       = extents or tdengine.vec2(15, 15)
	color         = color or tdengine.color32(0, 255, 128, 255)

	-- Draw a bubble around the cursor, which separates the nodes
	local color   = tdengine.color32(0, 255, 128, 255)
	local extents = tdengine.vec2(15, 15)
	local middle  = tdengine.vec2(imgui.GetMousePos(0))
	local min     = middle:subtract(extents:scale(.5))
	local max     = middle:add(extents)
	imgui.GetWindowDrawList():AddRectFilled(
		imgui.ImVec2(min.x, min.y), imgui.ImVec2(max.x, max.y), color, 50)
end

imgui.extensions.TextColored = function(text, color)
	imgui.PushStyleColor(ffi.C.ImGuiCol_Text, color)
	imgui.Text(text)
	imgui.PopStyleColor()
end

imgui.extensions.ComboBox = function(label, active, items, on_select, ...)
	local change = false
	if imgui.BeginCombo(label, active) then
		for index, item in pairs(items) do
			local is_item_selected = item == active;
			if imgui.Selectable(item, is_item_selected) then
				on_select(item, ...)
				change = true
			end
		end

		imgui.EndCombo()
	end

	return change
end
