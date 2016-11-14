basic_robot.commands = {};

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
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner ) then return false end
	
	local nodename = minetest.get_node(pos).name;
	if nodename == "air" then return false end
	
	local spos = obj:get_luaentity().spawnpos; 
	local inv = minetest.get_meta(spos):get_inventory();
	if not inv then return end
	inv:add_item("main",ItemStack( nodename ));
	
	
	--DS
	local sounds = minetest.registered_nodes[minetest.get_node(pos).name].sounds
	if sounds then
		local sound = sounds.dug
		if sound then
			minetest.sound_play(sound,{object=obj, max_hear_distance = 10})
		end
	end
	
	minetest.set_node(pos,{name = "air"})
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
	if (not tinv:contains_item(inventory, stack) or not inv:room_for_item("main", stack)) and meta:get_int("admin")~=1 then
		return false 
	end
	
	inv:add_item("main",stack);
	tinv:remove_item(inventory, stack);

	return true
end



basic_robot.commands.read_node = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	return minetest.get_node(pos).name or ""
end

basic_robot.commands.read_text = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)	
	return minetest.get_meta(pos):get_string("infotext") or ""
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
	if not inv:contains_item("main", ItemStack(nodename)) and meta:get_int("admin")~=1 then return end
	inv:remove_item("main", ItemStack(nodename));	
	
	--DS
	local sounds = minetest.registered_nodes[nodename].sounds
	if sounds then
		local sound = sounds.place
		if sound then
			minetest.sound_play(sound,{object=obj, max_hear_distance = 10})
		end
	end
	
	minetest.set_node(pos,{name = nodename})
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


basic_robot.commands.read_book = function (itemstack) -- itemstack should contain book
	local data = minetest.deserialize(itemstack:get_metadata())
	if data then
		return data.text;
	else 
		return nil
	end
end

basic_robot.commands.write_book = function(name,text) -- returns itemstack containing book
	
	local lpp = 14;
	local new_stack = ItemStack("default:book_written")
	local data = {} 
	
	data.title = "program book"
	data.text = text
	data.text_len = #data.text
	data.page = 1
	data.page_max = math.ceil((#data.text:gsub("[^\n]", "") + 1) / lpp)
	data.owner = name
	local data_str = minetest.serialize(data)
	
	new_stack:set_metadata(data_str);
	return new_stack;	
	
end

