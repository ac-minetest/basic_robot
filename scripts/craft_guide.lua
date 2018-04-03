-- ROBOT craft guide by rnd, 2017
if not list then
	
	tname = "rnd";
	list = {};
	tmplist = _G.minetest.registered_items;
	for k,v in pairs(tmplist) do
		local texture = v.inventory_image or "";
		if texture=="" and v.tiles then texture = v.tiles[1] or "" end
		if (not v.groups.not_in_craft_guide or v.groups.not_in_craft_guide == 0) and type(texture)=="string" and texture~="" then
			list[#list+1] = {_G.minetest.formspec_escape(k),_G.minetest.formspec_escape(v.description),_G.minetest.formspec_escape(texture)}; -- v.inventory_image, k, v.description
		end
	end
	
	
	idx = 1; n = 35; row = 6; size = 1.25;
	filter = "" item = "" recipeid = 1
	filterlist = {}; for i = 1,#list do filterlist[i] = i end
	
	get_texture = function(ritem)
		local v = _G.minetest.registered_items[ritem]; if not v then return "" end
		local texture = v.inventory_image or "";
		if texture=="" and v.tiles then texture = v.tiles[1] or "" end
		if type(texture)~="string" then return "" end
		return texture
	end
	
	get_form = function()
		local form = "size[7.5,8.5]";
		local x,y,i; local idxt = idx+n; if idxt >  #filterlist then idxt  = #filterlist end
		for i = idx, idxt do
			local id = filterlist[i];
			if list[id] and list[id][3] then 
				x = ((i-idx) % row)
				y = (i-idx-x)/row;
				form = form .. "image_button[".. x*size ..",".. y*size+0.75 .. ";"..size.."," .. size .. ";" .. list[id][3] ..";".."item"..";".. list[id][1] .."]"
			end
		end
		form = form .. "textarea[0.25,0;2,0.75;filter;filter;"..filter .. "]" .. "button[2.,0;1,0.5;search;search]"..
		"button[5.5,0;1,0.5;prev;PREV]" .. "button[6.5,0;1,0.5;next;NEXT]" .. "label[4,0;".. idx .. "-"..idxt .. "/" .. #filterlist.."]";
		return form
	end
	
	get_recipe = function()
		local form = "size[7.5,8.5]";
		local recipes = _G.minetest.get_all_craft_recipes(item); if not recipes then return end; 
		local recipe = recipes[recipeid]; if not recipe then return end
		local items = recipe.items
		local x,y,i;
		for i = 0, 8 do
			local ritem = items[i+1] or ""; local sritem = "";
			local j = string.find(ritem,":"); if j then sritem = string.sub(ritem,j+1) end; --ritem = _G.minetest.formspec_escape(ritem);
			x = (i % 3)
			y = (i-x)/3;
			form = form .. "image_button[".. x*size ..",".. y*size+0.75 .. ";"..size.."," .. size .. ";" .. get_texture(ritem) ..";".."item"..";".. sritem .."]"
		end
		form = form .. "textarea[0.25,0;2,0.75;recipeid;recipeid ".. #recipes .. ";"..recipeid .. "]" .. "button[2.,0;1,0.5;go;go]"..
		"label[3,0;" .. item .. "]" ..	"button[6.5,0;1,0.5;back;BACK]" ;
		return form
	end
	
	s=0
end

if s==0 then
	local p = find_player(4); s = 1
	if p then
		self.show_form(p[1],get_form())
	else
		self.remove()
	end
end


sender,fields = self.read_form()
if sender then
	
	if fields.search then
		filter = fields.filter or ""
		filterlist = {};
		for i = 1,#list do
			if string.find(list[i][1],filter) then filterlist[#filterlist+1] = i end
		end
		idx=1;self.show_form(sender,get_form())
		
	elseif fields.prev then
		idx = idx  - n; if idx<1 then idx =#filterlist-n end
		self.show_form(sender,get_form())
	elseif fields.next then
		idx = idx+n; if idx > #filterlist then idx = 1 end
		self.show_form(sender,get_form())
	elseif fields.back then
		self.show_form(sender,get_form())
	elseif fields.recipeid then
		recipeid = tonumber(fields.recipeid) or 1;
		self.show_form(sender,get_recipe())
	elseif fields.item then
		item = fields.item;
		local recipes = _G.minetest.get_all_craft_recipes(item);
		local count = 0; if recipes then count = #recipes end
		if count>0 then
			recipeid = 1
			self.show_form(sender,get_recipe() or "")
		end
	elseif fields.quit then
		self.remove()
	end
end