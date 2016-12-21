basic_robot.commands = {};

-- set up nodes for planting (for example seeds -> plant) : [nodename] = plant_name
basic_robot.plant_table  = {["farming:seed_barley"]="farming:barley_1",["farming:beans"]="farming:beanpole_1", -- so it works with farming redo mod
["farming:blueberries"]="farming:blueberry_1",["farming:carrot"]="farming:carrot_1",["farming:cocoa_beans"]="farming:cocoa_1",
["farming:coffee_beans"]="farming:coffee_1",["farming:corn"]="farming:corn_1",["farming:blueberries"]="farming:blueberry_1",
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
	
	local digcount = 0;
	if basic_robot.maxdig~=0 then
		digcount = basic_robot.data[name].digcount;
		if digcount > basic_robot.maxdig then 
			basic_robot.data[name].digcount = digcount+1;
		return false end
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
			minetest.sound_play(sound,{object=obj, max_hear_distance = 10})
		end
	end
	
	basic_robot.data[name].digcount = digcount+1;
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

	return contains
end

basic_robot.commands.check_inventory = function(name,itemname, inventory,dir)
	local obj = basic_robot.data[name].obj;
	local tpos;
	if dir~=0 then
		tpos = pos_in_dir(obj, dir); -- position of target block in front
	else
		tpos = obj:get_luaentity().spawnpos; 
	end
	
	local tinv = minetest.get_meta(tpos):get_inventory();
	local stack = ItemStack(itemname);
	if not inventory then inventory = "main"; end
	
	return tinv:contains_item(inventory, stack); 
end


basic_robot.no_teleport_table = {
	["itemframes:item"] = true,
	["signs:text"] = true,
	["basic_robot:robot"] = true
}

basic_robot.commands.pickup = function(r,name)
	
	if r>8 then return false end

	local pos = basic_robot.data[name].obj:getpos();
	local spos = basic_robot.data[name].spawnpos; -- position of spawner block
	local meta = minetest.get_meta(spos);
	local inv = minetest.get_meta(spos):get_inventory();
		
	for _,obj in pairs(minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, r)) do
		local lua_entity = obj:get_luaentity() 
		if not obj:is_player() and lua_entity and lua_entity.itemstring then
			local detected_obj = lua_entity.itemstring or "" 
			if not basic_robot.no_teleport_table[detected_obj] then -- object on no teleport list 
				-- put item in chest
				local stack = ItemStack(lua_entity.itemstring) 
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack);
				end
				obj:remove();
			end
		end
	end
	
	return true
end

				
				
				

basic_robot.commands.read_node = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	return minetest.get_node(pos).name or ""
end

basic_robot.commands.read_text = function(name,dir,stringname)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	if stringname == nil then 
		stringname = "infotext" 
	end
	return minetest.get_meta(pos):get_string(stringname) or ""
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
				minetest.sound_play(sound,{object=obj, max_hear_distance = 10})
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
	else
		tplayer:set_attach(obj, "", {x=0,y=5,z=0}, {x=0,y=0,z=0})
	end

	return true

end

basic_robot.commands.read_book = function (itemstack) -- itemstack should contain book
	local data = minetest.deserialize(itemstack:get_metadata())
	if data then
		return data.text;
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


