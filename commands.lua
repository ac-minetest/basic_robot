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

basic_robot.commands.move = function(obj,dir)
	local pos = pos_in_dir(obj, dir)

	if minetest.get_node(pos).name ~= "air" then return end
	-- up; no levitation!
	if minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name == "air" and
		minetest.get_node({x=pos.x,y=pos.y-2,z=pos.z}).name == "air" then
		return
	end

	obj:moveto(pos, true)
end


basic_robot.commands.turn = function (obj, angle)
	local yaw = obj:getyaw()+angle;
	obj:setyaw(yaw);
end


basic_robot.commands.dig = function(obj,dir)
	local pos = pos_in_dir(obj, dir)
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner ) then return end
	local sounds = minetest.registered_nodes[minetest.get_node(pos).name].sounds
	if sounds then
		local sound = sounds.dug
		if sound then
			minetest.sound_play(sound)
		end
	end
	minetest.set_node(pos,{name = "air"})
end

basic_robot.commands.read_node = function(obj,dir)
	local pos = pos_in_dir(obj, dir)
	return minetest.get_node(pos).name or ""
end


basic_robot.commands.place = function(obj,nodename, dir)
	local pos = pos_in_dir(obj, dir)
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos,luaent.owner ) then return end
	if minetest.get_node(pos).name~="air" then return end
	minetest.set_node(pos,{name = nodename})
	local sounds = minetest.registered_nodes[nodename].sounds
	if sounds then
		local sound = sounds.place
		if sound then
			minetest.sound_play(sound)
		end
	end
end
