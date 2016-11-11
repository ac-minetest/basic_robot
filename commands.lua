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
		elseif dir ==  5 then
			pos.y=pos.y+1
		elseif dir ==  6 then
			pos.y=pos.y-1
	end
	
	if dir<5 then
		pos.x = pos.x+math.cos(yaw)
		pos.z = pos.z+math.sin(yaw)
	end
	return pos
end

basic_robot.commands.move = function(name,dir)
	local obj = basic_robot.data[name].obj;
	local pos = pos_in_dir(obj, dir)
	
	if minetest.get_node(pos).name ~= "air" then return end
	-- up; no levitation!
	if minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name == "air" and
		minetest.get_node({x=pos.x,y=pos.y-2,z=pos.z}).name == "air" then 
		return 
	end

	obj:moveto(pos, true)
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
	if minetest.is_protected(pos,luaent.owner ) then return end
	
	local nodename = minetest.get_node(pos).name;
	if nodename == "air" then return end
	
	local spos = obj:get_luaentity().spawnpos; 
	local inv = minetest.get_meta(spos):get_inventory();
	if not inv then return end
	inv:add_item("main",ItemStack( nodename ));
	
	minetest.set_node(pos,{name = "air"})
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
	if minetest.is_protected(pos,luaent.owner ) then return end
	if minetest.get_node(pos).name~="air" then return end
	
	local spos = obj:get_luaentity().spawnpos; 
	local meta = minetest.get_meta(spos);
	local inv = meta:get_inventory();
	if not inv then return end
	if not inv:contains_item("main", ItemStack(nodename)) and meta:get_int("admin")~=1 then return end
	inv:remove_item("main", ItemStack(nodename));	
	
	minetest.set_node(pos,{name = nodename})
end