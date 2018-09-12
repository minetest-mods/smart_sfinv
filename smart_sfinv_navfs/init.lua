local orig_make_formspec = sfinv.make_formspec
function sfinv.make_formspec(player, context, content, show_inv, size)
	context.site_pane_size = 3
	context.page_size_x = 8
	context.page_size_y = 8.6

	if size then
		context.page_size_x, context.page_size_y = size:sub(6,-2):match("([^,]+),([^,]+)")
		context.page_size_x = tonumber(context.page_size_x)
		context.page_size_y = tonumber(context.page_size_y)
	else
		size = 'size['..context.page_size_x..','..context.page_size_y..']'
	end
	local formspec = orig_make_formspec(player, context, content, show_inv, size)

	if context.nav_site and #context.nav_site > 0 then
		local newsize = 'size['..(context.page_size_x+context.site_pane_size+1)..','..(context.page_size_y)..']'
		formspec = formspec:gsub(size:gsub("([^%w])", "%%%1"), newsize)
		formspec = formspec .. "container_end[]"
	end
	return formspec
end


------------------------------------------------------------------------
-- Build up the enhanced nav_fs
------------------------------------------------------------------------
function sfinv.get_nav_fs(player, context, nav, current_idx)
	-- Only show tabs if there is more than one page
	if #nav < 2 then
		return ""
	end

	local nav_titles_above = {}
	local current_idx_above = -1
	context.nav_above = {}

	local nav_titles_site = {}
	local current_idx_site = 0
	context.nav_site = {}

	for idx, page in ipairs(context.nav) do
		if page:sub(1,9) == "creative:" then
			table.insert(nav_titles_site, nav[idx])
			table.insert(context.nav_site, page)
			if idx == current_idx then
				current_idx_site = #nav_titles_site
			end
		else
			table.insert(nav_titles_above, nav[idx])
			table.insert(context.nav_above, page)
			if idx == current_idx then
				current_idx_above = #nav_titles_above
			end
		end
	end

	local formspec = ""
	if #nav_titles_site > 0 then
		formspec = formspec.."textlist[0,0;" ..(context.site_pane_size-0.2).. "," .. context.page_size_y ..
			";smart_sfinv_nav_site;" .. table.concat(nav_titles_site, ",") ..
			";" .. current_idx_site .. ";true]container["..(context.site_pane_size+0.5)..",0]"
	end

	if #nav_titles_above > 0 then
		if current_idx_above == -1 then
			table.insert(nav_titles_above,"")
			current_idx_above = #nav_titles_above
		end
		formspec = formspec.."tabheader[0,0;smart_sfinv_nav_tabs_above;" .. table.concat(nav_titles_above, ",") ..
			";" .. current_idx_above .. ";true;false]"
	end
	return formspec
end

------------------------------------------------------------------------
-- Process input for enhanced navfs
------------------------------------------------------------------------
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

	-- Was a header tab selected?
	if fields.smart_sfinv_nav_button_above and context.nav_above then
		local id = context.nav_above[1]
		local page = sfinv.pages[id]
		if id and page then
			sfinv.set_page(player, id)
		end
	elseif fields.smart_sfinv_nav_tabs_above and context.nav_above then
		local tid = tonumber(fields.smart_sfinv_nav_tabs_above)
		if tid and tid > 0 then
			local id = context.nav_above[tid]
			local page = sfinv.pages[id]
			if id and page then
				sfinv.set_page(player, id)
			end
		end

	-- Was a site table selected?
	elseif fields.smart_sfinv_nav_site and context.nav_site then
		local tid = minetest.explode_textlist_event(fields.smart_sfinv_nav_site).index
		if tid and tid > 0 then
			local id = context.nav_site[tid]
			local page = sfinv.pages[id]
			if id and page then
				sfinv.set_page(player, id)
			end
		end
	end
end)

