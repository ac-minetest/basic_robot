basic_robot.commands = {};

-- set up nodes for planting (for example seeds -> plant) : [nodename] = plant_name
basic_robot.plant_table  = {["farming:seed_barley"]="farming:barley_1",["farming:beans"]="farming:beanpole_1", -- so it works with farming redo mod
["farming:blueberries"]="farming:blueberry_1",["farming:carrot"]="farming:carrot_1",["farming:cocoa_beans"]="farming:cocoa_1",
["farming:coffee_beans"]="farming:coffee_1",["farming:corn"]="farming:corn_1",
["farming:seed_cotton"]="farming:cotton_1",["farming:cucumber"]="farming:cucumber_1",["farming:grapes"]="farming:grapes_1",
["farming:melon_slice"]="farming:melon_1",["farming:potato"]="farming:potato_1",["farming:pumpkin_slice"]="farming:pumpkin_1",
["farming:raspberries"]="farming:raspberry_1",["farming:rhubarb"]="farming:rhubarb_1",["farming:tomato"]="farming:tomato_1",
["farming:seed_wheat"]="farming:wheat_1"}


local function tick(pos) -- needed for plants to start growing: minetest 0.4.14 farming
	minetest.get_node_timer(pos):start(math.random(166, 286))
end


local pi = math.pi;

local function pos_in_dir(obj, dir) -- position after we move in specified direction
	local yaw = obj:getyaw();
	local pos = obj:getpos();
	
	if dir == 1 then
		yaw = yaw + pi/2;
		elseif dir == 2 then
			yaw = yaw - pi/2;
		elseif dir == 3 then
		elseif dir == 4 then
			yaw = yaw+pi;
		elseif dir ==  5 then -- up
			pos.y=pos.y+1
		elseif dir ==  6 then -- down
			pos.y=pos.y-1
		elseif dir ==  7 then -- forward, down
			pos.y=pos.y-1
	end
	
	if dir<5 or dir == 7 then -- left, right, back
		pos.x = pos.x+math.cos(yaw)
		pos.z = pos.z+math.sin(yaw)
	end
	
	return pos
end

basic_robot.commands.move = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)
	
	-- can move through walkable nodes
	if minetest.registered_nodes[minetest.get_node(pos).name].walkable then return end
	-- up; no levitation!
	if minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name == "air" and
		minetest.get_node({x=pos.x,y=pos.y-2,z=pos.z}).name == "air" then 
		return false
	end

	obj:moveto(pos, true)
	
	-- sit and stand up for model - doenst work for overwriten obj export
	-- if dir == 5 then-- up
		-- obj:set_animation({x=0,y=0})
	-- elseif dir == 6 then -- down
		-- obj:set_animation({x=81,y=160})
	-- end
	
	
	
	
	return true
end

basic_robot.commands.turn = function (name, angle)
	local obj = basic_robot.data[name].obj;
	local yaw = obj:getyaw()+angle;
	obj:setyaw(yaw);
end

basic_robot.commands.dig = function(name,dir)
	
	local energy = 0;
	if basic_robot.maxenergy~=0 then
		local data = basic_robot.data[name];
		energy = data.energy;
		if energy > 0 then data.energy = energy-1 else return false end
	end
	
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner) then return false end
	
	local nodename = minetest.get_node(pos).name;
	if nodename == "air" or nodename=="ignore" then return false end
	
	local spos = obj:get_luaentity().spawnpos; 
	local inv = minetest.get_meta(spos):get_inventory();
	if not inv then return end
	--inv:add_item("main",ItemStack( nodename ));
	
	basic_robot.give_drops(nodename, inv);
	minetest.set_node(pos,{name = "air"})
	
	--DS: sounds
	local sounds = minetest.registered_nodes[nodename].sounds
	if sounds then
		local sound = sounds.dug
		if sound then
			minetest.sound_play(sound,{pos=pos, max_hear_distance = 10})
		end
	end
	
	return true
end


basic_robot.commands.insert_item = function(name,item, inventory,dir)  
	local obj = basic_robot.data[name].obj;
	local tpos = pos_in_dir(obj, dir); -- position of target block
	local luaent = obj:get_luaentity();
	if minetest.is_protected(tpos,luaent.owner ) then return false end
	
		
	local pos = basic_robot.data[name].spawnpos; -- position of spawner block
	
	local meta = minetest.get_meta(pos);
	local tmeta = minetest.get_meta(tpos);
	
	local inv = minetest.get_meta(pos):get_inventory();
	
	-- fertilize if soil
	if item == "farming:fertilizer" then
		local stack = ItemStack(item);
		if minetest.get_node(tpos).name == "farming:soil_wet" and (meta:get_int("admin")==1 or inv:contains_item("main", stack)) then
			inv:remove_item("main", stack);
			local nutrient = tmeta:get_int("nutrient");	nutrient = nutrient + 10; if nutrient>20 then nutrient = 20 end
			tmeta:set_int("nutrient",nutrient);
			minetest.set_node({x=tpos.x,y=tpos.y+1,z=tpos.z},{name = "air"})
			return true
		end
	end
	
	
	local tinv = minetest.get_meta(tpos):get_inventory();
	
	if not inventory then inventory = "main"; end
	--if not inv then return end
	local stack = ItemStack(item);
	if (not inv:contains_item("main", stack) or not tinv:room_for_item(inventory, stack)) and meta:get_int("admin")~=1 then
		return false 
	end
	
	tinv:add_item(inventory,stack);
	inv:remove_item("main", stack);

	return true
end

basic_robot.commands.take_item = function(name,item, inventory,dir)  
	local obj = basic_robot.data[name].obj;
	local tpos = pos_in_dir(obj, dir); -- position of target block
	local luaent = obj:get_luaentity();
	if minetest.is_protected(tpos,luaent.owner ) then return false end
	
	
	local pos = basic_robot.data[name].spawnpos; -- position of spawner block
	
	if basic_robot.bad_inventory_blocks[ minetest.get_node(tpos).name ] then return false end -- dont allow take from 
	
	local meta = minetest.get_meta(pos);
	local tmeta = minetest.get_meta(tpos);
	
	local inv = minetest.get_meta(pos):get_inventory();
	local tinv = minetest.get_meta(tpos):get_inventory();
	
	if not inventory then inventory = "main"; end
	--if not inv then return end
	local stack = ItemStack(item);
	local contains = tinv:contains_item(inventory, stack); 
	if (not contains or not inv:room_for_item("main", stack)) and meta:get_int("admin")~=1 then
		return false 
	end
	
	inv:add_item("main",stack);
	tinv:remove_item(inventory, stack);

	return true
end

-- check_inventory(item, inventory, position)
--if position>0 then it returns name of item at that position
basic_robot.commands.check_inventory = function(name,itemname, inventory, position, dir)
	local obj = basic_robot.data[name].obj;
	local tpos;
	if dir~=0 then
		tpos = pos_in_dir(obj, dir); -- position of target block in front
	else
		tpos = obj:get_luaentity().spawnpos; 
	end
	
	local tinv = minetest.get_meta(tpos):get_inventory();
	
	if not position then position = -1 end
	if position>0 then
		return tinv:get_stack(inventory, position):to_string()
	end
	
	if itemname == "" then
		return tinv:is_empty(inventory)
	end
	
	local stack = ItemStack(itemname);
	if not inventory then inventory = "main"; end
	
	return tinv:contains_item(inventory, stack); 
end


basic_robot.no_teleport_table = {
	["itemframes:item"] = true,
	["signs:text"] = true,
	["basic_robot:robot"] = true
}

-- BUG : doesnt return list!

basic_robot.commands.pickup = function(r,name)
	
	if r>8 then return false end

	local pos = basic_robot.data[name].obj:getpos();
	local spos = basic_robot.data[name].spawnpos; -- position of spawner block
	local meta = minetest.get_meta(spos);
	local inv = minetest.get_meta(spos):get_inventory();
	local picklist = {};
	
	for _,obj in pairs(minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, r)) do
		local lua_entity = obj:get_luaentity() 
		if not obj:is_player() and lua_entity and lua_entity.itemstring then
			local detected_obj = lua_entity.itemstring or "" 
			if not basic_robot.no_teleport_table[detected_obj] then -- object on no teleport list 
				-- put item in chest
				local stack = ItemStack(lua_entity.itemstring) 
				picklist[#picklist+1]=detected_obj;
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack);
				end
				obj:remove();
			end
		end
	end
	if not picklist[1] then return nil end
	return picklist
end


basic_robot.commands.read_node = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	return minetest.get_node(pos).name or ""
end

basic_robot.commands.read_text = function(name,mode,dir,stringname)
	if not mode then mode = 0 end
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	
	if stringname == nil then 
		stringname = "infotext" 
	end
	
	if mode == 1 then return minetest.get_meta(pos):get_int(stringname) else
	return minetest.get_meta(pos):get_string(stringname) or "" end
end

basic_robot.commands.write_text = function(name,dir,text)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner ) then return false end
	minetest.get_meta(pos):set_string("infotext",text or "")
	return true
end

basic_robot.commands.place = function(name,nodename, dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner ) then return false end
	if minetest.get_node(pos).name~="air" then return false end
	
	local spos = obj:get_luaentity().spawnpos; 
	local meta = minetest.get_meta(spos);
	local inv = meta:get_inventory();
	if not inv then return false end
	if not inv:contains_item("main", ItemStack(nodename)) and meta:get_int("admin")~=1 then return false end
	inv:remove_item("main", ItemStack(nodename));	
	
	--DS
	local registered_node = minetest.registered_nodes[nodename];
	if registered_node then
		local sounds = registered_node.sounds
		if sounds then
			local sound = sounds.place
			if sound then
				minetest.sound_play(sound,{pos=pos, max_hear_distance = 10})
			end
		end
	end
	
	local placename = basic_robot.plant_table[nodename];
	if placename then
		minetest.set_node(pos,{name = placename})
		tick(pos); -- needed for seeds to grow
	else
		minetest.set_node(pos,{name = nodename})
	end
	
	return true
end

basic_robot.commands.attack = function(name, target) -- attack range 4, damage 5
	
	local energy = 0;
	if basic_robot.maxenergy~=0 then
		local data = basic_robot.data[name];
		energy = data.energy;
		if energy > 0 then data.energy = energy-1 else return false end
	end
	
	local reach = 4;
	local damage = 5;
	
	local tplayer = minetest.get_player_by_name(target);
	if not tplayer then return false end
	local obj = basic_robot.data[name].obj;
	local pos = obj:getpos();
	local tpos = tplayer:getpos();
	
	if math.abs(pos.x-tpos.x)> reach or math.abs(pos.y-tpos.y)> reach or math.abs(pos.z-tpos.z)> reach then
		return false
	end
	tplayer:set_hp(tplayer:get_hp()-damage)
	return true
	
end

basic_robot.commands.grab = function(name,target)

	local reach = 4;

	local tplayer = minetest.get_player_by_name(target);
	if not tplayer then return false end
	local obj = basic_robot.data[name].obj;
	local pos = obj:getpos();
	local tpos = tplayer:getpos();

	if math.abs(pos.x-tpos.x)> reach or math.abs(pos.y-tpos.y)> reach or math.abs(pos.z-tpos.z)> reach then
		return false
	end

	if tplayer:get_attach() then
		tplayer:set_detach()
		return false
	else
		tplayer:set_attach(obj, "", {x=0,y=5,z=0}, {x=0,y=0,z=0})
	end

	return true

end

basic_robot.commands.read_book = function (itemstack) -- itemstack should contain book
	local data = minetest.deserialize(itemstack:get_metadata())
	if data then
		return data.title,data.text;
	else 
		return nil
	end
end

basic_robot.commands.write_book = function(name,title,text) -- returns itemstack containing book
	
	local lpp = 14;
	local new_stack = ItemStack("default:book_written")
	local data = {} 
	
	if title == "" or not title then title = "program book "..minetest.get_gametime() end
	data.title = title
	data.text = text or ""
	data.text_len = #data.text
	data.page = 1
	data.page_max = math.ceil((#data.text:gsub("[^\n]", "") + 1) / lpp)
	data.owner = name
	local data_str = minetest.serialize(data)
	
	new_stack:set_metadata(data_str);
	return new_stack;	
	
end


basic_robot.give_drops = function(nodename, inv) -- gives apropriate drops when node is dug
	
	local table = minetest.registered_items[nodename];
	local dropname;
	if table~=nil then --put in chest
		if table.drop~= nil then -- drop handling 
			if table.drop.items then
			--handle drops better, emulation of drop code
			local max_items = table.drop.max_items or 0;
				if max_items==0 then -- just drop all the items (taking the rarity into consideration)
					max_items = #table.drop.items or 0;
				end
				local drop = table.drop;
				local i = 0;
				for k,v in pairs(drop.items) do
					if i > max_items then break end; i=i+1;								
					local rare = v.rarity or 1;
					if math.random(1, rare)==1 then
						dropname = v.items[math.random(1,#v.items)]; -- pick item randomly from list
						inv:add_item("main",dropname);
						
					end
				end
			else
				inv:add_item("main",table.drop);
			end	
		else
			inv:add_item("main",nodename);
		end
	end
end


local render_text = function(text,linesize) 
		local count = math.floor(string.len(text)/linesize)+1;
		local width = 18; local height = 24;
		local tex = "";
		local y = 0; local x=0;
		for i=1,string.len(text) do
			local cb = string.byte(text,i); 
			local c = "";
			if cb == 10 or cb == 13 then 
				y=y+1; x=0 
			else 
				c = string.format("%03d",cb)..".png" 
				tex = tex .. ":" .. (x*width) .. "," .. (y*height) .. "=" .. c;
				if x==linesize-1 then y=y+1 x=0 else x=x+1 end
			end
		end
		local background = "(black_screen.png^[resize:"..(linesize*width).. "x".. (linesize*height) ..")";
		tex =  "([combine:"..(linesize*width).."x"..(linesize*height)..tex..")";
		tex = background .. "^" ..  tex;
		return tex;
end


basic_robot.commands.display_text = function(obj,text,linesize,size)
	if not linesize or linesize<1 then linesize = 20 end
	if not size or size<=0 then size = 1 end
	if string.len(text)>linesize*linesize then text = string.sub(text,1,linesize*linesize) end
	local tex = render_text(text,linesize);
	
	if string.len(tex)<60000 then
		obj:set_properties({textures={"arrow.png","basic_machine_side.png",tex,"basic_machine_side.png","basic_machine_side.png","basic_machine_side.png"},visual_size = {x=size,y=size}})
	else
		self.label("error: string too long")
	end
end

local robot_activate_furnace = minetest.registered_nodes["default:furnace"].on_metadata_inventory_put; -- this function will activate furnace
basic_robot.commands.activate = function(name,mode, dir)
	local obj = basic_robot.data[name].obj;
	local tpos = pos_in_dir(obj, dir); -- position of target block in front
	
	local node = minetest.get_node(tpos);
	if node.name == "default:furnace" or node.name == "default:furnace_active" then
		if mode>0 then robot_activate_furnace(tpos) end
		return
	end	
	
	local table = minetest.registered_nodes[node.name];
	if table and table.mesecons and table.mesecons.effector then 
	else
		return 
	end -- error
	
	local effector=table.mesecons.effector;
	
	if mode > 0 then
		if not effector.action_on then return end
		effector.action_on(tpos,node,16)
	elseif mode<0 then
		if not effector.action_off then return end
		effector.action_off(tpos,node,16)
	end
end


local register_robot_button = function(R,G,B,type)
minetest.register_node("basic_robot:button"..R..G..B, 
 { 
	description = "robot button",
	tiles = {"robot_button.png^[colorize:#"..R..G..B..":180"},
	is_ground_content = false,
	groups = {cracky=3},
	on_punch = function(pos, node, player)
		local name = player:get_player_name(); if name==nil then return end
		local round = math.floor;
		local r = 20; local ry = 2*r;
		local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r};
		local meta = minetest.get_meta(ppos);
		local name = meta:get_string("name");
		local data = basic_robot.data[name];
		if data then data.keyboard = {x=pos.x,y=pos.y,z=pos.z, puncher = player:get_player_name(), type = type} end
	end		
	})
end

local register_robot_button_number = function(number,type)
minetest.register_node("basic_robot:button"..number, 
 { 
	description = "robot button",
	tiles = {"robot_button".. number .. ".png"},
	is_ground_content = false,
	groups = {cracky=3},
	on_punch = function(pos, node, player)
		local name = player:get_player_name(); if name==nil then return end
		local round = math.floor;
		local r = 20; local ry = 2*r;
		local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r};
		local meta = minetest.get_meta(ppos);
		local name = meta:get_string("name");
		local data = basic_robot.data[name];
		if data then data.keyboard = {x=pos.x,y=pos.y,z=pos.z, puncher = player:get_player_name(), type = type} end
	end		
	})
end

register_robot_button("FF","FF","FF",1);
register_robot_button("80","80","80",2);
register_robot_button("FF","80","80",3);
register_robot_button("80","FF","80",4);
register_robot_button("80","80","FF",5);
register_robot_button("FF","FF","80",6);

for i = 0,9 do register_robot_button_number(i,i+7) end



-- interactive button for robot: place robot on top of protector to intercept events

basic_robot.commands.keyboard = {

	get = function(name)
		local data = basic_robot.data[name];
		if data.keyboard then 
			local keyboard = data.keyboard;
			local event = {x=keyboard.x,y=keyboard.y,z=keyboard.z, puncher = keyboard.puncher, type = keyboard.type};
			data.keyboard = nil;
			return event
		else 
			return nil
		end
	end,
		
	set = function(spos,pos,type)

		if math.abs(pos.x-spos.x)>10 or math.abs(pos.y-spos.y)>10 or math.abs(pos.z-spos.z)>10 then return false end
		local nodename;
		if type == 0 then
			nodename = "air"
		elseif type == 1 then
			nodename = "basic_robot:buttonFFFFFF";
		elseif type == 2 then
			nodename = "basic_robot:button808080";
		elseif type == 3 then
			nodename = "basic_robot:buttonFF8080";
		elseif type == 4 then
			nodename = "basic_robot:button80FF80";
		elseif type == 5 then
			nodename = "basic_robot:button8080FF";
		elseif type == 6 then
			nodename = "basic_robot:buttonFFFF80";
		elseif type>=7 then
			nodename = "basic_robot:button"..(type-7);
		end
		
		minetest.swap_node(pos, {name = nodename})
		return true
		
	end,

}

basic_robot.commands.craftcache = {};
basic_robot.commands.craft = function(item, name)
	if not item then return end
	
	local cache = basic_robot.commands.craftcache[name];
	if not cache then basic_robot.commands.craftcache[name] = {}; cache = basic_robot.commands.craftcache[name] end
	local itemlist = {};
	if cache.item == item then-- read cache
		itemlist = cache.itemlist;
	else
		--local table = minetest.registered_items[nodename];
		local craft = minetest.get_craft_recipe(item);
		if craft and craft.type == "normal" and craft.items then else return end
		local items = craft.items;
		for _,item in pairs(items) do
			itemlist[item]=(itemlist[item] or 0)+1;
		end
		cache.item = item;
		cache.itemlist = itemlist;		
	end
	
	--minetest.chat_send_all(item)
	--minetest.chat_send_all(dump(itemlist))
	
	-- check if all items from itemlist..
	-- craft item
	
	local pos = basic_robot.data[name].spawnpos; -- position of spawner block
	local inv = minetest.get_meta(pos):get_inventory();
	
	for item,quantity in pairs(itemlist) do
		local stack = ItemStack(item .. " " .. quantity);
		if not inv:contains_item("main",stack) then return false end
	end
	
	for item,quantity in pairs(itemlist) do
		local stack = ItemStack(item .. " " .. quantity);
		inv:remove_item("main",stack);
	end
	
	inv:add_item("main",ItemStack(item))
	return true
end

--FORMS
basic_robot.commands.show_form = function(name, playername, form)
	minetest.show_formspec(playername, "robot_form".. name, form)
end


-- handle robots receiving fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not string.sub(formname,1,10) == "robot_form" then return end
	local name = string.sub(formname,11); -- robot name
	if not basic_robot.data[name] then return end
	basic_robot.data[name].read_form = fields;
	basic_robot.data[name].form_sender = player:get_player_name() or "";
end)