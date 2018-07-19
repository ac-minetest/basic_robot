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
	
	if dir == 1 then -- left
		yaw = yaw + pi/2;
	elseif dir == 2 then --right
		yaw = yaw - pi/2;
	elseif dir == 3 then -- forward
	elseif dir == 4 then
		yaw = yaw+pi; -- backward
	elseif dir ==  5 then -- up
		pos.y=pos.y+1
	elseif dir ==  6 then -- down
		pos.y=pos.y-1
		
	elseif dir ==  7 then -- left_down
		yaw = yaw + pi/2;pos.y=pos.y-1
	elseif dir ==  8 then -- right_down
		yaw = yaw - pi/2;pos.y=pos.y-1
	elseif dir ==  9 then -- forward_down
		pos.y=pos.y-1
	elseif dir ==  10 then -- backward_down
		yaw = yaw + pi; pos.y=pos.y-1
	
	elseif dir ==  11 then -- left_up
		yaw = yaw + pi/2;pos.y=pos.y+1
	elseif dir ==  12 then -- right_up
		yaw = yaw - pi/2;pos.y=pos.y+1
	elseif dir ==  13 then -- forward_up
		pos.y=pos.y+1
	elseif dir ==  14 then -- backward_up
		yaw = yaw + pi; pos.y=pos.y+1
	end
	
	if dir ~= 5 and dir ~= 6 then 
		pos.x = pos.x+math.cos(yaw)
		pos.z = pos.z+math.sin(yaw)
	end
	
	return pos
end

local check_operations = function(name, amount, quit)
	if basic_robot.maxoperations~=0 then
		local data = basic_robot.data[name];
		local operations = data.operations-amount;
		if operations >= 0 then 
			data.operations = operations 
		else 
			if quit then
				error("robot out of available operations in one step."); return false
			end
			return false
		end 
	end
end


basic_robot.commands.move = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)
	
	check_operations(name,0.25,true)
	
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
	local yaw;
	-- more precise turns by 1 degree resolution
	local mult = math.pi/180;
	local yaw = obj:getyaw();
	yaw = math.floor((yaw+angle)/mult+0.5)*mult;
	obj:setyaw(yaw);
end


basic_robot.digcosts = { -- 1 energy = 1 coal
	["default:stone"] = 1/25,

}


basic_robot.commands.dig = function(name,dir)
	
	local energy = 0;
	check_operations(name,2,true)
	
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner) then return false end
	
	local nodename = minetest.get_node(pos).name;
	if nodename == "air" or nodename=="ignore" then return false end
	
	local spos = obj:get_luaentity().spawnpos; 
	local inv = minetest.get_meta(spos):get_inventory();
	
	--require energy to dig
	if basic_robot.dig_require_energy then
		local digcost = basic_robot.digcosts[nodename];
		if digcost then
			local data = basic_robot.data[name];
			local energy = (data.menergy or 0) - digcost;
			if energy<0 then 
				error("need " .. digcost .. " energy to dig " .. nodename .. ". Use machine.generate(...) to get some energy."); 
			end
			data.menergy = energy;
		end
	end
	
	
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
	
	check_operations(name,0.4,true)
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
	["basic_robot:robot"] = true,
	["robot"] = true,
}


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
					obj:setpos({x=0,y=0,z=0}) -- no dupe
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

basic_robot.commands.place = function(name,nodename, param2,dir)
	
	check_operations(name,0.4,true)
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
	else -- normal place
		if param2 then
			minetest.set_node(pos,{name = nodename, param2 = param2})
		else
			minetest.set_node(pos,{name = nodename})
		end
	end
	
	return true
end

basic_robot.commands.attack = function(name, target) -- attack range 4, damage 5
	
	local energy = 0;
	check_operations(name,2,true);
	
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
	local data = itemstack:get_meta():to_table().fields -- 0.4.16
	--local data = minetest.deserialize(itemstack:get_metadata()) -- pre 0.4.16
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
	--local data_str = minetest.serialize(data) -- pre 0.4.16
	--new_stack:set_metadata(data_str);
	new_stack:get_meta():from_table({fields = data}) -- 0.4.16
	
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
		local ret = {};
		local y = 0; local x=0;
		for i=1,string.len(text) do
			local cb = string.byte(text,i); 
			local c = "";
			if cb == 10 or cb == 13 then 
				y=y+1; x=0 
			else 
				c = string.format("%03d",cb)..".png" 
				ret[#ret+1] = ":" .. (x*width) .. "," .. (y*height) .. "=" .. c;
				--tex = tex .. ":" .. (x*width) .. "," .. (y*height) .. "=" .. c;
				if x==linesize-1 then y=y+1 x=0 else x=x+1 end
			end
		end
		local background = "(black_screen.png^[resize:"..(linesize*width).. "x".. (linesize*height) ..")";
		--tex =  "([combine:"..(linesize*width).."x"..(linesize*height)..tex..")";
		return background .. "^" .."([combine:"..(linesize*width).."x"..(linesize*height)..table.concat(ret,"")..")";
end


basic_robot.commands.display_text = function(obj,text,linesize,size)
	if not linesize or linesize<1 then linesize = 20 elseif linesize>40 then linesize = 40 end
	if size and size<=0 then size = 1 end
	
	if string.len(text)>linesize*linesize then text = string.sub(text,1,linesize*linesize) end
	local tex = render_text(text,linesize);
	if not size then return tex end
	
	if string.len(tex)<=1600 then
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
		return true
	end	
	
	local table = minetest.registered_nodes[node.name];
	if table and table.mesecons and table.mesecons.effector then 
	else
		return false
	end -- error
	
	local effector=table.mesecons.effector;
	
	if not mode then mode = 1 end
	if mode > 0 then
		if not effector.action_on then return false end
		effector.action_on(tpos,node,16)
	elseif mode<0 then
		if not effector.action_off then return false end
		effector.action_off(tpos,node,16)
	end
	return true
end


local register_robot_button = function(R,G,B,type)
	minetest.register_node("basic_robot:button"..R..G..B, 
	 { 
		description = "robot button",
		tiles = {"robot_button.png^[colorize:#"..R..G..B..":180"},
		inventory_image = "robot_button.png^[colorize:#"..R..G..B..":180",
		wield_image = "robot_button.png^[colorize:#"..R..G..B..":180",
		
		is_ground_content = false,
		groups = {cracky=3},
		on_punch = function(pos, node, player)
			local name = player:get_player_name(); if name==nil then return end
			local round = math.floor;
			local r = basic_robot.radius; local ry = 2*r; -- note: this is skyblock adjusted
			local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r}; -- just on top of basic_protect:protector!
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
	inventory_image = "robot_button".. number .. ".png",
	wield_image = "robot_button".. number .. ".png",

	is_ground_content = false,
	groups = {cracky=3},
	on_punch = function(pos, node, player)
		local name = player:get_player_name(); if name==nil then return end
		local round = math.floor;
		local r = basic_robot.radius; local ry = 2*r;
		local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r};
		local meta = minetest.get_meta(ppos);
		local name = meta:get_string("name");
		local data = basic_robot.data[name];
		if data then data.keyboard = {x=pos.x,y=pos.y,z=pos.z, puncher = player:get_player_name(), type = type} end
	end		
	})
end


local register_robot_button_char = function(number,type)
minetest.register_node("basic_robot:button_"..number, 
 { 
	description = "robot button",
	tiles = {string.format("%03d",number).. ".png"},
	inventory_image = string.format("%03d",number).. ".png",
	wield_image = string.format("%03d",number).. ".png",
	is_ground_content = false,
	groups = {cracky=3},
	on_punch = function(pos, node, player)
		local name = player:get_player_name(); if name==nil then return end
		local round = math.floor;
		local r = basic_robot.radius; local ry = 2*r;
		local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r};
		local meta = minetest.get_meta(ppos);
		local name = meta:get_string("name");
		local data = basic_robot.data[name];
		if data then data.keyboard = {x=pos.x,y=pos.y,z=pos.z, puncher = player:get_player_name(), type = type} end
	end		
	})
end

local register_robot_button_custom = function(number,texture)
minetest.register_node("basic_robot:button_"..number, 
 { 
	description = "robot button",
	tiles = {texture .. ".png"},
	inventory_image = texture .. ".png",
	wield_image = texture .. ".png",
	is_ground_content = false,
	groups = {cracky=3},
	on_punch = function(pos, node, player)
		local name = player:get_player_name(); if name==nil then return end
		local round = math.floor;
		local r = basic_robot.radius; local ry = 2*r;
		local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r};
		local meta = minetest.get_meta(ppos);
		local name = meta:get_string("name");
		local data = basic_robot.data[name];
		if data then data.keyboard = {x=pos.x,y=pos.y,z=pos.z, puncher = player:get_player_name(), type = number} end
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
for i = 0,255 do register_robot_button_char(i,i+17) end

register_robot_button_custom(273,"puzzle_switch_off")
register_robot_button_custom(274,"puzzle_switch_on")
register_robot_button_custom(275,"puzzle_button_off")
register_robot_button_custom(276,"puzzle_button_on")

register_robot_button_custom(277,"puzzle_equalizer")
register_robot_button_custom(278,"puzzle_setter")
register_robot_button_custom(279,"puzzle_piston")

register_robot_button_custom(280,"puzzle_diode")
register_robot_button_custom(281,"puzzle_NOT")
register_robot_button_custom(282,"puzzle_delayer")
register_robot_button_custom(283,"puzzle_platform")

register_robot_button_custom(284,"puzzle_giver")
register_robot_button_custom(285,"puzzle_checker")



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
		
	set = function(data,pos,type)
		
		local owner = data.owner;
		local spos = data.spawnpos; 
		local dist = math.max(math.abs(spos.x-pos.x),math.abs(spos.y-pos.y),math.abs(spos.z-pos.z));
		if dist>10 then return false end
		if minetest.is_protected(pos,owner) then return false end -- with fast protect checks this shouldnt be problem!

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
		elseif type>=7 and type <= 16 then 
			nodename = "basic_robot:button"..(type-7);
		else 
			nodename = "basic_robot:button_"..(type-17);
		end
		
		minetest.swap_node(pos, {name = nodename})
		return true
		
	end,

}

basic_robot.commands.craftcache = {};

basic_robot.commands.craft = function(item, mode, idx, name)
	if not item then return false end
	
	local cache = basic_robot.commands.craftcache[name];
	if not cache then basic_robot.commands.craftcache[name] = {}; cache = basic_robot.commands.craftcache[name] end
	local itemlist = {}; local output = "";
	if cache.item == item and cache.idx == idx then -- read cache
		itemlist = cache.itemlist;
		output = cache.output;
	else

		local craft;

		if not idx then 
			craft = minetest.get_craft_recipe(item);
		else
			craft = minetest.get_all_craft_recipes(item)[idx]
		end
		if craft and craft.type == "normal" and craft.items then else return false end
		output = craft.output;
		local items = craft.items;
		for _,item in pairs(items) do
			itemlist[item]=(itemlist[item] or 0)+1;
		end
		cache.item = item;
		cache.idx = idx;
		cache.itemlist = itemlist;
		cache.output = output;

		-- loop through robot inventory for those "group" items and see if anything in inventory matches group - then replace
		-- group name with that item
		
		local pos = basic_robot.data[name].spawnpos; -- position of spawner block
		local inv = minetest.get_meta(pos):get_inventory();
		
		for item,v in pairs(itemlist) do
			local k = string.find(item,"group:");
			if k then
				local group = string.sub(item,k+6);
				-- do we have that in inventory?
				local size = inv:get_size("main");
				for i=1,size do
					local itemname = inv:get_stack("main", i):get_name();
					local groups = minetest.registered_items[itemname].groups or {};
					if groups[group] then cache.itemlist[item] = nil; cache.itemlist[itemname] = v break end
				end
			end
		end
		
		
	end
	
	--minetest.chat_send_all(item)
	--minetest.chat_send_all(dump(itemlist))
	
	if mode == 1 then return itemlist end
	
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
	
	inv:add_item("main",ItemStack(output))
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


-- ROBOT TECHNIC
-- amount parameter in generate_power, smelt,... is determined by upgrade level
-- it specifies how much energy will be generated :

basic_robot.technic = { -- data cache
	fuels = {}, --[fuel] = value
	smelts = {}, -- [item] = [cooktime, cookeditem, aftercookeditem]
	
	grinder_recipes = {  --[in] ={fuel cost, out, quantity of material required for processing}
		["default:stone"] = {2,"default:sand",1},
		["default:cobble"] = {1,"default:gravel",1},
		["default:gravel"] = {0.5,"default:dirt",1},
		["default:dirt"] = {0.5,"default:clay_lump 4",1},
		["es:aikerum_crystal"] ={16,"es:aikerum_dust 2",1}, -- added for es mod
		["es:ruby_crystal"] = {16,"es:ruby_dust 2",1},
		["es:emerald_crystal"] = {16,"es:emerald_dust 2",1},
		["es:purpellium_lump"] = {16,"es:purpellium_dust 2",1},
		["default:obsidian_shard"] = {199,"default:lava_source",1},
		["gloopblocks:basalt"] = {1, "default:cobble",1}, -- enable coble farms with gloopblocks mod
		["default:ice"] = {1, "default:snow 4",1},
		["darkage:silt_lump"]={1,"darkage:chalk_powder",1},
		["default:diamond"] = {16, "basic_machines:diamond_dust_33 2", 1},
		["default:ice"] = {1, "default:snow", 1},
		["moreores:tin_lump"] = {4,"basic_machines:tin_dust_33 2",1},
		["default:obsidian_shard"] = {199, "default:lava_source",1},
		["default:mese_crystal"] = {8, "basic_machines:mese_dust_33 2",1},
		["moreores:mithril_ingot"] = {16, "basic_machines:mithril_dust_33 2",1},
		["moreores:silver_ingot"] = {5, "basic_machines:silver_dust_33 2",1},
		["moreores:tin_ingot"] = {4,"basic_machines:tin_dust_33 2",1},
		["moreores:mithril_lump"] = {16, "basic_machines:mithril_dust_33 2",1},
		["default:steel_ingot"] = {4, "basic_machines:iron_dust_33 2",1},
		["moreores:silver_lump"] = {5, "basic_machines:silver_dust_33 2",1},
		["default:gold_ingot"] = {6, "basic_machines:gold_dust_33 2", 1},
		["default:copper_ingot"] = {4, "basic_machines:copper_dust_33 2",1},
		["default:gold_lump"] = {6, "basic_machines:gold_dust_33 2", 1},
		["default:iron_lump"] = {4, "basic_machines:iron_dust_33 2",1},
		["default:copper_lump"] = {4, "basic_machines:copper_dust_33 2",1},
	},
	
	compressor_recipes = {  --[in] ={fuel cost, out, quantity of material required for processing}
		["default:snow"] = {1,"default:ice"},
		["default:coalblock"] = {41,"default:diamond"}, -- to smelt diamond dust to diamond need 25 coal + 16 for grinder
	},
}

local chk_machine_level = function(inv,level) -- does machine have upgrade to be classified with at least "level"
	if level < 1 then level = 1 end
	local upg = {"default:diamondblock","default:mese","default:goldblock"};
	for i = 1,#upg do
		if not inv:contains_item("main",ItemStack(upg[i].. " " .. level)) then return false end
	end
	return true
end


basic_robot.commands.machine = {
	
	-- convert fuel into energy
	generate_power = function(name,input, amount) -- fuel used, if no fuel then amount specifies how much energy builtin generator should produce
		
		check_operations(name,1.5, true)
						
		if amount and amount>0 then -- attempt to generate power from builtin generator
			local pos = basic_robot.data[name].spawnpos; -- position of spawner block
			local inv = minetest.get_meta(pos):get_inventory();
			local level = amount*40; -- to generate 1 unit ( coal lump per second ) we need at least upgrade 40
			if not chk_machine_level(inv, level) then error("generate_power : tried to generate " .. amount .. " energy requires upgrade level at least " .. level .. " (blocks of mese, diamond, gold )") return end
			local data = basic_robot.data[name];
			local energy = (data.menergy or 0)+amount;
			data.menergy =  energy;
			return energy;
		end
		
		local energy = 0; -- can only do one step at a run time
		
		
		if string.find(input," ") then return nil, "1: can convert only one item at once" end
		
		local pos = basic_robot.data[name].spawnpos; -- position of spawner block
		local inv = minetest.get_meta(pos):get_inventory();
		local stack = ItemStack(input);
		if not inv:contains_item("main",stack) then return nil,"2: no input material" end
		
		-- read energy value of input ( coal lump = 1)
		local add_energy = basic_robot.technic.fuels[input];
		if not add_energy then -- lookup fuel value
			local fueladd, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = {stack}}) 
			if fueladd.time > 0 then 
				add_energy = fueladd.time/40; -- fix by kurik
			else
				return nil, "3: material can not be used as a fuel"
			end
			if add_energy>0 then basic_robot.technic.fuels[input] = add_energy end
		end
		
		inv:remove_item("main", stack);
		
		--add energy
		local data = basic_robot.data[name]; energy = data.menergy or 0;
		energy = energy+ add_energy;data.menergy = energy
		return energy;
	end,
	
	-- smelting
	smelt = function(name,input,amount)  -- input material, amount of energy used for smelt
		
		local energy = 0; -- can only do one step at a run time
		check_operations(name,2,true)
		
		if string.find(input," ") then return nil, "0: only one item per smelt" end
		
		local pos = basic_robot.data[name].spawnpos; -- position of spawner block
		local meta = minetest.get_meta(pos);
		local inv = minetest.get_meta(pos):get_inventory();
		
		--read robot energy
		local cost = 1/40;
		local smelttimeboost = 1;
		local level = 1;
		if amount and amount>0 then
			level = amount*10; -- 10 level required for 1 of amount
			if not chk_machine_level(inv,level) then 
				error("3 smelting: need at least level " .. level .. " upgrade for required power " .. amount);
				return
			end
			cost = cost*(1+amount);
			smelttimeboost = smelttimeboost + amount; -- double speed with amount 1
		end
		
		local data = basic_robot.data[name]
		energy = data.menergy or 0; -- machine energy
		if energy<cost then return nil,"1: not enough energy" end
		
		local stack = ItemStack(input);
		if not inv:contains_item("main",stack) then return nil, "2: no input materials" end
		
		local src_time = (data.src_time or 0)+smelttimeboost;

		-- get smelting data
		local smelts = basic_robot.technic.smelts[input];
		if not smelts then
			local cooked, aftercooked;
			cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = {stack}})		
			if cooked.time>0 then
				basic_robot.technic.smelts[input] = {cooked.time, cooked.item, aftercooked.items[1]};
				smelts = basic_robot.technic.smelts[input];
			else 
				return nil, "3: material can not be smelted"
			end
		end
		local cooktime = smelts[1]; local cookeditem = smelts[2]; local aftercookeditem = smelts[3]
		
		-- is smelting done?
		data.menergy = energy-cost;
		if src_time >= cooktime then 
			inv:remove_item("main",stack);
			inv:add_item("main", ItemStack(aftercookeditem));
			inv:add_item("main", ItemStack(cookeditem));
			data.src_time = 0
			return true
		else
			data.src_time = src_time
			return math.floor(src_time/cooktime*100*100)/100
		end
	end,
	
	-- grind
	grind = function(name,input) 
		--[in] ={fuel cost, out, quantity of material required for processing}
		local recipe = basic_robot.technic.grinder_recipes[input];
		if not recipe then return nil, "unknown recipe" end
		local cost = recipe[1]; local output = recipe[2];

		local pos = basic_robot.data[name].spawnpos; -- position of spawner block
		local meta = minetest.get_meta(pos);
		local inv = minetest.get_meta(pos):get_inventory();

		--level requirement
		local level = math.floor((cost-1)/3);

		if not chk_machine_level(inv,level) then error("0: tried to grind " .. input .. " requires upgrade level at least " .. level) return end
		
		local stack = ItemStack(input);
		if not inv:contains_item("main",stack) then return nil, "1: missing input material" end
		
		local data = basic_robot.data[name];
		local energy = data.menergy or 0;
		if energy<cost then return nil, "2: low energy " .. energy .. "/" .. cost end
		data.menergy = energy-cost
		
		inv:remove_item("main",ItemStack(input))
		inv:add_item("main",ItemStack(output));
		return true
	end, 
		
		
	-- compress
	compress = function(name,input) 
		 --[in] ={fuel cost, out, quantity of material required for processing}
		local recipe = basic_robot.technic.compressor_recipes[input];
		if not recipe then return nil, "unknown recipe" end
		local cost = recipe[1]; local output = recipe[2];

		local pos = basic_robot.data[name].spawnpos; -- position of spawner block
		local meta = minetest.get_meta(pos);
		local inv = minetest.get_meta(pos):get_inventory();

		--level requirement
		local level = math.floor(cost/2)
		if not chk_machine_level(inv,level) then error("tried to compress " .. input .. " requires upgrade level at least " .. level) return end
		
		local stack = ItemStack(input);
		if not inv:contains_item("main",stack) then return nil, "1: missing input material" end
		
		local data = basic_robot.data[name];
		local energy = data.menergy or 0;
		if energy<cost then return nil, "2: low energy " .. energy .. "/" .. cost end
		data.menergy = energy-cost
		
		inv:remove_item("main",ItemStack(input))
		inv:add_item("main",ItemStack(output));
		return true
	end,
	
	transfer_power = function(name,amount,target)
		local pos = basic_robot.data[name].spawnpos;
		local data = basic_robot.data[name];
		local tdata = basic_robot.data[target];
		if not tdata then return nil, "target inactive" end
		
		local energy = 0; -- can only do one step at a run time
		check_operations(name,0.5, true);
		
		energy = data.menergy or 0;
		if amount>energy then return nil,"energy too low" end
		
		if not tdata.menergy then tdata.menergy = 0 end
		tdata.menergy = tdata.menergy + amount
		data.menergy = energy - amount;
		return true
		
	end,
}

-- CRPYTOGRAPHY

-- rnd 2017
-- nonlinear block stream cypher encryption with scrambling

	local scramble = function(input,password,sgn) -- permutes text randomly, nice after touch to stream cypher to prevent block analysis
		_G.math.randomseed(password);
		local n = #input;
		local permute = {}
		for i = 1, n do permute[i] = i end --input:sub(i, i)
		for i = n,2,-1 do
			local j = math.random(i-1);
			local tmp = permute[j];
			permute[j] = permute[i]; permute[i] = tmp;
		end
		local out = {};
		if sgn>0 then -- unscramble
			for i = 1,n	do out[permute[i]] = string.sub(input,i,i) end
		else -- scramble
			for i = 1,n	do out[i] = string.sub(input,permute[i],permute[i]) end
		end
		return table.concat(out,"")
	end
	
	local scramble_test = function()
		local text = "testing scrambling 1 2 3";
		local enc = scramble(text,10,1); -- scramble
		local dec = scramble(enc,10,-1); -- descramble
		say("SCRAMBLED--> ".. enc .. " DESCRAMBLED--> ".. dec)
	end
	--scramble_test()
	
	local get_hash = function(s,p) -- basic modular hash, first convert string into 4*8=32 bit int
		if not s then return end
		local h = 0; local n = string.len(s);local m = 4; -- put 4 characters together
		local r = 0;local i = 0;
		while i<n do
			i=i+1;r = 256*r+ string.byte(s,i);
			if i%m == 0 then h=h+(r%p) r=0 end
		end
		if i%m~=0 then h=h+(r%p) end
		return h%p
	end
	
	local encrypt_ = function(input,password,sgn) -- nonlinear stream cypher with extra block offsets
		
		local n = 16; -- range 0-255 (for just chat can use 32 - 132)
		local m = 65;
		local ret = "";input = input or "";
		local rndseed = get_hash(password, 10^30);
		_G.math.randomseed(rndseed);
		
		local block_offset = 1+math.random(n);
		local offset=1+math.random(n);
		
		for i=1, string.len(input) do
			offset = math.random(n+math.random(2+(i+offset+block_offset)^2)); -- yay, nested nonlinearity is fun and makes cryptanalysis 'trivial' hehe
			if i%8 == 1 then -- every 8 characters new offset using strong hash function incorporating recent offsets in nonlinear way
				block_offset = get_hash(_G.minetest.get_password_hash("",i*(offset+1)..password .. (block_offset^2)),n); -- composite fun with more serious hash function
				math.randomseed(rndseed+ block_offset) -- time for change of tune, can you keep up ? :)
				if math.random(100)>50 then block_offset = block_offset*math.random(n*(1+block_offset)) end -- extra fun, why not
			end
			offset = (offset + block_offset)%n;
			local c = string.byte(input,i)-m;
			c = m+((c+offset*sgn) % n);
			ret = ret .. string.char(c)
		end
		return ret
	end
	
	local ascii2hex = function(input) -- compress 256 char set to 16 charset range
		local ret = ""
		for i = 1, string.len(input) do
			local c = string.byte(input,i); -- c = c2*16+c1
			local c1 = c % 16;
			local c2 = (c-c1)/16;
			ret = ret .. (string.char(c1+65)..string.char(c2+65))
		end
		return ret;
	end
	
	local hex2ascii = function(input)
		local ret = ""
		if string.len(input)%2 == 1 then input = input .. "A" end -- padding
		for i = 1, string.len(input),2 do
			local c1 = string.byte(input,i)-65; -- c = c2*16+c1
			local c2 = string.byte(input,i+1)-65;
			ret = ret .. string.char(c2*16+c1)
		end
		return ret;
	end
	
	-- scheme: encrypt: (stream cypher) encrypt+scramble,  decrypt: unscramble+decrypt
	local encrypt = function(input, password)
		local ret = encrypt_(ascii2hex(input),password,1);
		local scrambleseed = get_hash(_G.minetest.get_password_hash("",password),10^30); -- strong hash from password, 10^30 possible permutes
		return scramble(ret, scrambleseed, 1);
	end
	
	local decrypt = function(input, password) 
		local scrambleseed = get_hash(_G.minetest.get_password_hash("",password),10^30);
		input = scramble(input, scrambleseed, -1); -- descramble
		return hex2ascii(encrypt_(input,password,-1)) 
	end

	-- just test
	local encrypt_test = function()
		local text = "testing encryption 1 2 3"; local password = "hello encryptions";
		local enc = encrypt(text, password);local dec = decrypt(enc, password);
		say("INPUT: " .. text .. " ENC: " .. enc .. " DEC: " .. dec)
	end

basic_robot.commands.crypto =  {encrypt = encrypt, decrypt = decrypt, scramble = scramble, basic_hash = get_hash}

-- PUZZLE GAMEPLAY - need puzzle privs

local is_same_block = function(pos1,pos2)
	local round = math.floor;
	local r = basic_robot.radius; local ry = 2*r; -- note: this is skyblock adjusted
	local ppos1 = {round(pos1.x/r+0.5)*r,round(pos1.y/ry+0.5)*ry,round(pos1.z/r+0.5)*r};
	local ppos2 = {round(pos2.x/r+0.5)*r,round(pos2.y/ry+0.5)*ry,round(pos2.z/r+0.5)*r};
	return ppos1[1]==ppos2[1] and ppos1[2]==ppos2[2] and ppos1[3] == ppos2[3]
end

local cmd_set_node = function(data,pos,node)
	if minetest.is_protected(pos,data.owner) then return end
	local spos = data.spawnpos;
	if not is_same_block(pos,spos) then return end -- only allow to edit same block as spawner is in
	minetest.swap_node(pos,node)
end

local cmd_get_node_inv = function(data,pos)
	local spos = data.spawnpos;
	if minetest.is_protected(pos,data.owner) then return end
	if not is_same_block(pos,spos) then return end
	return minetest.get_meta(pos):get_inventory()
end

local cmd_get_player = function(data,pname) -- return player for further manipulation
	local player = minetest.get_player_by_name(pname)
	if not player then error("player does not exist"); return end
	local spos = data.spawnpos;
	local ppos =  player:getpos();
	if not is_same_block(ppos,spos) then error("can not get player in another protection zone") return end
	return player	
end

local cmd_get_player_inv = function(data,pname) 
	local player = minetest.get_player_by_name(pname)
	if not player then return end
	local spos = data.spawnpos;
	local ppos =  player:getpos();
	if not is_same_block(ppos,spos) then error("can not get player in another protection zone") return end
	return player:get_inventory();
end

-- spatial triggers with hashing

local trigger_range = 5 -- how close player must be to "activate" - also size/2 of cells

local round = math.floor

local cmd_get_pos_id = function(data,pos, no_neighbors) -- return 4 nearby block ids
		local r = trigger_range*2;
		local range = 1000*2; -- coordinates from -1000 to +1000 allowed
		local n = range/r;
		
		local x1 = round(pos.x/r+0.5)
		local z1 = round(pos.z/r+0.5)
		local y1 = round(pos.y/r+0.5)
		local baseid = x1 + z1*n + y1*n^2 -- hash value
		if no_neighbors then return baseid end
		
		--check 4 nearby closest squares: 2D
		local x0 = round(pos.x/r); 
		local z0 = round(pos.z/r); 
		if x0<x1 and z0<z1 then -- lower left
			data.block_ids = {baseid,baseid-1-n,baseid-n,baseid-1};
			return 
		elseif x0==x1 and z0<z1 then 
			data.block_ids = {baseid, baseid-n, baseid+1-n, baseid+1}
			return 
		elseif x0==x1 and z0==z1 then
			data.block_ids = {baseid, baseid+1, baseid+1+n, baseid+n}
			return 
		else -- upper left
			data.block_ids = {baseid,baseid-1, baseid-1+n, baseid+n}
			return 
		end

	end

local cmd_set_triggers = function(pdata, triggers)
	pdata.triggers = {};
	local dtriggers = pdata.triggers;
	for i = 1,#triggers do
		dtriggers[i] = triggers[i];
	end
		
	-- init triggerdata
	pdata.triggerdata = {};
	local triggerdata = pdata.triggerdata;
	
	for i = 1, #triggers do
		local data = triggers[i]; 
		local id = cmd_get_pos_id(nil,data.pos, true);
		local tdata = triggerdata[id];
		if not tdata then triggerdata[id] = {}; tdata = triggerdata[id] end
		tdata[#tdata+1] = i; -- add index (=id)
		triggers[i].init(i) -- initialize trigger
	end
end

local cmd_checkpos = function(data,pos,pname) -- does the position pos trigger any triggers?
		
		cmd_get_pos_id(data,pos); -- we dont init new table structure every time but store ids in block_ids
		
		local block_ids = data.block_ids;
		local gamedata = data.gamedata;
		local triggerdata = data.triggerdata;
		local triggers = data.triggers;
		
		for j = 1,4 do -- check 4 nearby blocks cause we could be near border
			local block_id = block_ids[j];
			local gdata = gamedata;
			
			local tdata = triggerdata[block_id]; -- list of trigger indices in this block
			if tdata then 
				for i = 1,#tdata do -- check all triggers inside block
					local trigger = triggers[tdata[i]];
					local id = tdata[i]; -- trigger id
					if trigger.onetime and gdata[id] then -- trigger already "triggered"
					else 
						--say("trigger " .. id)
						trigger.action(pname,id)
					end
				end
			end
		end
	end

	
-- PUZZLE COMMANDS
basic_robot.commands.puzzle = {
	set_triggers = cmd_set_triggers, checkpos = cmd_checkpos,set_node = cmd_set_node, get_node_inv=cmd_get_node_inv, get_player_inv = cmd_get_player_inv,
	get_player = cmd_get_player,
	get_meta =  function(data,pos)
		local spos = data.spawnpos;	
		if minetest.is_protected(pos,data.owner) then return end
		if not is_same_block(pos,spos) then return end
		if minetest.get_node(pos).name == "basic_robot:spawner" then return end
		local meta = minetest.get_meta(pos);
		if not meta then error("get_meta in puzzle returned nil"); return end
		return meta
	end,
	get_gametime = function() return minetest.get_gametime() end,
	
	activate = function(data,mode,tpos)
		local spos = data.spawnpos;
		if minetest.is_protected(tpos,data.owner) then return end
		if not is_same_block(tpos,spos) then return end
		
		local node = minetest.get_node(tpos);
		if node.name == "default:furnace" or node.name == "default:furnace_active" then
			if mode>0 then robot_activate_furnace(tpos) end
			return true
		end	
		
		local table = minetest.registered_nodes[node.name];
		if table and table.mesecons and table.mesecons.effector then 
		else
			return false
		end -- error
		
		local effector=table.mesecons.effector;
		
		if not mode then mode = 1 end
		if mode > 0 then
			if not effector.action_on then return false end
			effector.action_on(tpos,node,16)
		elseif mode<0 then
			if not effector.action_off then return false end
			effector.action_off(tpos,node,16)
		end
		return true
	end,
}

--   VIRTUAL PLAYER   --


local Vplayer = {};
function Vplayer:new(name) -- constructor
	if not basic_robot.data[name].obj then return end -- only make it for existing robot
	if basic_robot.virtual_players[name] then return end -- already exists

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.obj = basic_robot.data[name].obj;
	o.data = basic_robot.data[name];
	
	local spawnpos = o.data.spawnpos;
	local meta = minetest.get_meta(spawnpos); if not meta then return end
	o.inv = meta:get_inventory();
	
	basic_robot.virtual_players[name] = o;
end
 
 -- functions
 function Vplayer:getpos() return self.obj:getpos() end
 function Vplayer:remove() end
 function Vplayer:setpos() end
 function Vplayer:move_to() end
 function Vplayer:punch() end
 function Vplayer:rightlick() end
 function Vplayer:get_hp() return 20 end
 function Vplayer:set_hp() return 20 end
 
 function Vplayer:get_inventory() return self.inv end
 function Vplayer:get_wield_list() return "main" end
 function Vplayer:get_wield_index() return 1 end
 function Vplayer:get_wielded_item() return self.inv:get_stack("main", 1) end
 function Vplayer:set_wielded_item() end
 function Vplayer:set_armor_groups() end
 function Vplayer:get_armor_groups() return {fleshy = 100} end
 function Vplayer:set_animation() end
 function Vplayer:get_animation() end
 function Vplayer:set_attach() end
 function Vplayer:get_attach() end
 function Vplayer:set_detach() end
 function Vplayer:set_bone_position() end
 function Vplayer:get_bone_position() end
 function Vplayer:set_properties() end
 function Vplayer:get_properties() end
 function Vplayer:is_player() return true end
 function Vplayer:get_nametag_attributes() end
 function Vplayer:set_nametag_attributes() end
 
 function Vplayer:set_velocity() end
 function Vplayer:get_velocity() end
 function Vplayer:set_acceleration() end
 function Vplayer:get_acceleration() end
 function Vplayer:set_yaw() end
 function Vplayer:get_yaw() end
 function Vplayer:set_texture_mod() end
 function Vplayer:get_luaentity() end
 
 function Vplayer:get_player_name() return self.data.name end
 function Vplayer:get_player_velocity() return {x=0,y=0,z=0} end
 function Vplayer:get_look_dir() return {x=1,y=0,z=0} end
 function Vplayer:get_look_vertical() return 0 end
 function Vplayer:get_look_horizontal() return 0 end
 function Vplayer:set_look_vertical() end
 function Vplayer:set_look_horizontal() end
 function Vplayer:get_breath() return 1 end
 function Vplayer:set_breath() end
 function Vplayer:set_attribute() end
 function Vplayer:get_attribute() end
 function Vplayer:set_inventory_formspec() end
 function Vplayer:get_inventory_formspec() return "" end
 function Vplayer:get_player_control() return {} end
 function Vplayer:get_player_control_bits() return 0 end
 function Vplayer:set_physics_override() end
 function Vplayer:get_physics_override() return {} end
 function Vplayer:hud_add() end
 function Vplayer:hud_remove() end
 function Vplayer:hud_change() end
 function Vplayer:hud_get() end
 function Vplayer:hud_set_flags() end
 function Vplayer:hud_get_flags() return {} end
 function Vplayer:hud_set_hotbar_itemcount() end
 function Vplayer:hud_get_hotbar_itemcount() return 0 end
 function Vplayer:hud_set_hotbar_image() end
 function Vplayer:hud_get_hotbar_image() return "" end
 function Vplayer:hud_set_hotbar_selected_image() end
 function Vplayer:hud_get_hotbar_selected_image() return "" end
 function Vplayer:set_sky() end
 function Vplayer:get_sky() end
 function Vplayer:set_clouds() end
 function Vplayer:get_clouds() end
 function Vplayer:override_day_night_ratio() end
 function Vplayer:get_day_night_ratio() end
 function Vplayer:set_local_animation() end
 function Vplayer:get_local_animation() end
 function Vplayer:set_eye_offset() end
 function Vplayer:get_eye_offset() end
 
  
 -- code for act borrowed from: https://github.com/minetest-mods/pipeworks/blob/fa4817136c8d1e62dafd6ab694821cba255b5206/wielder.lua, line 372
 
 
 
 
 
 
 
 
 

