-- minesweeper
if not data then
	m=24;n=22; minescount = m*n/5;
	reward = 30;

	if not find_player(4) then error("minesweeper: no players near") end
	
	self.spam(1)	
	t0 = _G.minetest.get_gametime();
	data = {}; spawnpos = self.spawnpos() -- place mines
	for i = 1, minescount do local i = math.random(m); local j = math.random(n); if not data[i] then data[i] = {} end; data[i][j] = 1; end
	if not data[1] then data[1] = {} end if not data[2] then data[2] = {} end -- create 2x2 safe area
	data[1][1] = 0;data[1][2] = 0;data[2][1] = 0;data[2][2] = 0;
	
	minescount = 0; 
	for i = 1,m do for j = 1,n do  -- render game
		if data[i] and data[i][j] == 1 then minescount = minescount + 1 end
		if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j})~="basic_robot:button808080" then
			puzzle.set_node({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},{name = "basic_robot:button808080"})
		end
	end	end
	puzzle.set_node({x=spawnpos.x+1,y=spawnpos.y,z=spawnpos.z+1},{name = "basic_robot:button80FF80"})

	get_mine_count = function(i,j)
		if i<0 or i>m+1 or j<0 or j>n+1 then return 0 end; count = 0
		for k = -1,1 do	for l = -1,1 do
				if data[i+k] and data[i+k][j+l] == 1 then count = count +1 end
		end	end
		return count
	end
	chk_mines = function()
		local count = minescount;
		for i=1,m do for j=1,n do 
		if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j})=="basic_robot:buttonFF8080" and data[i] and data[i][j]==1 then
			count=count-1
		end
		end end
		return count
	end
	say("minesweeper " .. m .. "x" ..n .. " with " .. minescount .. " mines ")
	self.label("find all hidden mines! mark mine by standing on top of block and punch,\notherwise it will uncover the block (and possibly explode).")
		
end

event = keyboard.get();
if event then
	local x = event.x - spawnpos.x;local y = event.y - spawnpos.y;local z = event.z - spawnpos.z;
	if x<1 or x>m or z<1 or z>n then
		if x == 0 and z == 1 then 
			local count = chk_mines(); 
			if count == 0 then 
				t0 = _G.minetest.get_gametime() - t0;
				say("congratulations! " .. event.puncher .. " discovered all mines in " .. t0 .. " s")
				_G.minetest.add_item({x=spawnpos.x,y=spawnpos.y+1,z=spawnpos.z},_G.ItemStack("default:gold_ingot "..reward)) -- diamond reward
			else
				reward = reward*(1-(count/minescount))^(1.5); reward = math.floor(reward);
				say("FAIL! " .. count .. " mines remaining. You get " .. reward .. " gold for found mines")
				_G.minetest.add_item({x=spawnpos.x,y=spawnpos.y+1,z=spawnpos.z},_G.ItemStack("default:gold_ingot "..reward)) -- diamond reward
			end
			self.remove()
		end
	else --if event.type == 2 then
		local ppos = player.getpos(event.puncher)
		if ppos and math.abs(ppos.x-event.x)<0.5 and math.abs(ppos.z-event.z)<0.5 then -- just mark mine
			if keyboard.read({x=event.x,y=event.y,z=event.z})~="basic_robot:button808080" then
				puzzle.set_node({x=event.x,y=event.y,z=event.z},{name = "basic_robot:button808080"})
			else
				puzzle.set_node({x=event.x,y=event.y,z=event.z},{name = "basic_robot:buttonFF8080"})
			end
		else
			if data[x] and data[x][z]==1 then
					say("boom! "..event.puncher .. " is dead ");puzzle.set_node({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},{name = "basic_robot:buttonFF8080"});
					local player_ = puzzle.get_player(event.puncher);
					player_:setpos({x=spawnpos.x-1,y=spawnpos.y+1,z=spawnpos.z-1});					
					self.remove()
			else
				local count = get_mine_count(x,z);
				if count == 0 then puzzle.set_node({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},{name = "basic_robot:button80FF80"})
				else puzzle.set_node({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},{name = "basic_robot:button"..count}) end
			end
		end
	end
end