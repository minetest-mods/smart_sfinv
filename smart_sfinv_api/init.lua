smart_sfinv_api = {
	registered_enhancements = {}
}


----------------------------------------------
-- API: register new enhancement
----------------------------------------------
--[[
Methods:

 - make_formspec(enh, player, context)
 - get_nav_fs(enh, player, context, nav, current_idx)
 - receive_fields(handler, player, context, fields)

Method does set Attributes:
 - enh.formspec_resize
 - enh.formspec_before_navfs
 - enh.formspec_after_navfs
 - enh.formspec_after_content
 - enh.custom_nav_fs - if set, default is skipped
]]

function smart_sfinv_api.register_enhancement(def)
	table.insert(smart_sfinv_api.registered_enhancements, def)
end

----------------------------------------------
-- Enhancement handler
----------------------------------------------
local enh_handler_class = {
		formspec_before_navfs = "",
		formspec_after_navfs = "",
		formspec_after_content = ""
	}
enh_handler_class_meta = {__index = enh_handler_class }

function enh_handler_class:run_enhancements(enh_method, ...)
	for _, enh in ipairs(smart_sfinv_api.registered_enhancements) do
		if enh[enh_method] then
			enh[enh_method](self, ...)
		end
	end
end

----------------------------------------------
-- Get the enhancement handler
----------------------------------------------
function smart_sfinv_api.get_handler( context )
	context.sfinv_navfs_handler = context.sfinv_navfs_handler or setmetatable( {}, enh_handler_class_meta)
		return context.sfinv_navfs_handler
end

----------------------------------------------
-- Redefnition sfinv.get_nav_fs
----------------------------------------------
local orig_get_nav_fs = sfinv.get_nav_fs
function sfinv.get_nav_fs(player, context, nav, current_idx)
	-- Dummy access
	if not nav then
		return ""
	end

	local handler = smart_sfinv_api.get_handler( context )
	handler:run_enhancements("get_nav_fs", player, context, nav, current_idx)

	if handler.custom_nav_fs then
		return handler.custom_nav_fs
	else
		return orig_get_nav_fs(player, context, nav, current_idx)
	end
end

----------------------------------------------
-- Redefinition sfinv.make_formspec
----------------------------------------------
local orig_make_formspec = sfinv.make_formspec
function sfinv.make_formspec(player, context, content, show_inv, size)
	context.sfinv_navfs_handler = nil  -- initialize handler
	local handler = smart_sfinv_api.get_handler( context )
	local nav_fs = sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx)

	handler:run_enhancements("make_formspec", player, context)

	local tmp = {
		handler.formspec_resize or size or smart_sfinv_api.default_size,
		smart_sfinv_api.theme_main,
		handler.formspec_before_navfs,
		nav_fs,
		handler.formspec_after_navfs,
		content,
		handler.formspec_after_content
	}
	if show_inv then
		tmp[#tmp + 1] = smart_sfinv_api.theme_inv
	end
	return table.concat(tmp, "")
end

----------------------------------------------
-- Additional on_player_receive_fields
----------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" or not sfinv.enabled then
		return false
	end

	-- Get Context
	local name = player:get_player_name()
	local context = sfinv.contexts[name]
	if not context then
		sfinv.set_player_inventory_formspec(player)
		return false
	end

	local handler = smart_sfinv_api.get_handler( context )
	handler:run_enhancements("receive_fields", player, context, fields)
end)


----------------------------------------------
-- Initialization: hacky access to some default variables
----------------------------------------------
local _dummy_page = orig_make_formspec(nil, {}, "|", true, nil)
smart_sfinv_api.default_size, smart_sfinv_api.theme_main, smart_sfinv_api.theme_inv = _dummy_page:match("(size%[[%d.,]+%]+)([^|]+)|([^|]+)") 