-- CONNECT, coded in 20 minutes by rnd
if not data then
	m=8;n=8;turn = 0; num = 4;
	self.spam(1);t0 = _G.minetest.get_gametime();
	spawnpos = self.spawnpos() -- place mines
	state = 0; -- 0 signup 1 game
	players = {};
	data = {};
	for i = 1,m do data[i]={}; for j = 1,n do data[i][j]=0 end end
	for i = 1,m do for j = 1,n do  -- render game
		if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j})~="basic_robot:button808080" then
			keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},2)
		end
	end	end
	
	get_count_in_dir = function(dir,x,y)
		local r = num; -- num=4? in a row
		local snode = data[x][y];local count = 1;
		for j = 1,2 do
			for i = 1,r-1 do
				local x1 = x + dir[1]*i;local y1 = y + dir[2]*i;
				if not data[x1] or not data[x1][y1] then break end; if data[x1][y1]~= snode then break end
				count = count +1
			end
			dir[1]=-dir[1];dir[2]=-dir[2];
		end
		return count
	end
	
	get_count = function(x,y)
		local c1 = get_count_in_dir({0,1},x,y);	local c2 = get_count_in_dir({1,0},x,y)
		local c3 = get_count_in_dir({1,1},x,y);	local c4 = get_count_in_dir({1,-1},x,y)
		if c2>c1 then c1 = c2 end; if c3>c1 then c1 = c3 end; if c4>c1 then c1 = c4 end
		return c1
	end
	
	self.label("CONNECT 4 : GREEN starts play. 2 players punch to join game.")		
end

event = keyboard.get();
if event then
	local x = event.x - spawnpos.x;local y = event.y - spawnpos.y;local z = event.z - spawnpos.z;
	if x<1 or x>m or z<1 or z>n then
	elseif event.type == 2 then --if event.type == 2 then
			if state == 0 then
				if #players<2 then players[#players+1] = event.puncher
				else state = 1 end
				if #players==2 then state = 1 end
			end
			keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},4+turn);
			data[x][z] = 4+turn;
			if get_count(x,z) == num then say("CONGRATULATIONS! " .. event.puncher .. " has "..num .. " in a row"); self.remove(); goto END end
			turn = 1-turn
			if state == 1 then
				local msg = "";	if turn == 0 then msg = "GREEN " else msg = "BLUE" end
				self.label(msg .. " : " .. players[turn+1])
			end
	end
end
::END::