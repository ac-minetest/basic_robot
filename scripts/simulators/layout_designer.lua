-- rnd 2017
if not data then
	m=50;n=50; minescount = m*n/14;
	
	t0 = _G.minetest.get_gametime();
	rom.data = {}; rom.rooms = {} -- so we dont make new tables everytime
	data = rom.data; spawnpos = self.spawnpos();
	rooms = rom.rooms;
	for i = 1, minescount do local i = math.random(m); local j = math.random(n); if not data[i] then data[i] = {} end; data[i][j] = 1; end

	get_mine_count = function(i,j)
		if i<0 or i>m+1 or j<0 or j>n+1 then return 0 end; count = 0
		for k = -1,1 do	for l = -1,1 do
				if data[i+k] and data[i+k][j+l] == 1 then count = count +1 end
		end	end
		return count
	end
	
	-- generate level data
	for i = 1,m do rooms[i]={}; for j = 1,n do
		if get_mine_count(i,j) > 0 or (data[i] and data[i][j] == 1) then
			rooms[i][j] = 1 
		else
			rooms[i][j] = 0
		end
	end	end
	
	
	-- find passages
	for i = 2,m-1 do for j = 2,n-1 do
		if rooms[i][j] == 0 then
			local A11 = rooms[i-1][j-1]; local A21 = rooms[i][j-1];local A31 = rooms[i+1][j-1];
			local A12 = rooms[i-1][j];							   local A32 = rooms[i+1][j];
			local A13 = rooms[i-1][j+1]; local A23 = rooms[i][j+1];local A33 = rooms[i+1][j+1];
			
			if (A12~=1 and A32~=1 and A21 == 1 and A23 == 1) or
			   (A12==1 and A32==1 and A21 ~= 1 and A23 ~= 1)
			then
				rooms[i][j] = 2; -- passage
			end
		end	
	end	end
	
	read_room = function(i,j)
		if i<1 or i > m then return nil end
		if j<1 or j > n then return nil end
		return rooms[i][j]
	end
	
	render_rooms = function()
		for i = 1,m do for j = 1,n do
			local tile = rooms[i][j];
			if tile == 0 then
				_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j}, {name = "air"})
				_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y+1,z=spawnpos.z+j}, {name = "air"})
			elseif tile == 1 then
				_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j}, {name = "basic_robot:buttonFFFFFF"})
				_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y+1,z=spawnpos.z+j}, {name = "basic_robot:buttonFFFFFF"})
			elseif tile == 2 then -- passage, insert 1 door in it
				--determine direction
				local dir = {0,0}
				if read_room(i+1,j) == 2 then dir = {1,0}
					elseif read_room(i-1,j) == 2 then dir = {-1,0}
					elseif read_room(i,j+1) == 2 then dir = {0,1}
					elseif read_room(i,j-1) == 2 then dir = {0,-1}
					elseif read_room(i-1,j) ~= 0 or read_room(i+1,j) ~= 0 then dir = {0,1}
					else dir = {1,0}
				end
				local k1 = 0; local k2 = 0;
				for k = 1, 10 do 
					if read_room(i+dir[1]*k,j+dir[2]*k)~= 2 then k1 = k-1 break 
					else
						if rooms[i+dir[1]*k] then rooms[i+dir[1]*k][j+dir[2]*k] = 0 end
						_G.minetest.swap_node({x=spawnpos.x+i+dir[1]*k,y=spawnpos.y,z=spawnpos.z+j+dir[2]*k}, {name = "air"})
					end
				end
				for k = 1, 10 do 
					if read_room(i-dir[1]*k,j-dir[2]*k)~= 2 then k2 = -(k-1) break 
					else
						if rooms[i+dir[1]*k] then rooms[i+dir[1]*k][j+dir[2]*k] = 0 end
						_G.minetest.swap_node({x=spawnpos.x+i-dir[1]*k,y=spawnpos.y,z=spawnpos.z+j-dir[2]*k}, {name = "air"})
					end
				end
				local k = math.floor((k1+k2)/2);
				--place door
				local param = 1
				if dir[1]~=0 then param = 2 end
				_G.minetest.swap_node({x=spawnpos.x+i+dir[1]*k,y=spawnpos.y+1,z=spawnpos.z+j+dir[2]*k}, {name = "air"})
				if param == 1 then
					_G.minetest.swap_node({x=spawnpos.x+i+dir[1]*k,y=spawnpos.y,z=spawnpos.z+j+dir[2]*k}, {name = "doors:door_wood_a", param2 = 2})
				else
					_G.minetest.swap_node({x=spawnpos.x+i+dir[1]*k,y=spawnpos.y,z=spawnpos.z+j+dir[2]*k}, {name = "doors:door_wood_a", param2 = 1})
				end
				

				
			elseif tile == 3 then
				_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j}, {name = "default:stonebrick"})
				
			end
		end end
	end
	
	render_rooms()
	
	
	fill_room = function(x,y, roomIdx) -- room index: 1,2,3,... will be written as -1,-2,.. in rooms
		local tile = rooms[i][j];
		if tile ~= 0 then return false end
		
		rooms[i][j] = -roomIdx;
		local stk = {{i,j}}; -- stack to place border tiles
		local tmpstk = {}; -- temporary stack
		
		local free = true; -- are there any free room tiles
		
		while free do
			
			-- loop all stack tiles
			for i=1,#stk do
				local p = stk[i];
				tile = rooms[p[1]][p[2]];
			end
		
		end
		
		
	end
	
	
end
self.remove()