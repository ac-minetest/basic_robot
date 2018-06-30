--black box by rnd, 03/18/2017
--https://en.wikipedia.org/wiki/Black_Box_(game)

if not data then
	m=16;n=16;
	atoms = 32
	attempts = 1;turn = 0; 
	spawnpos = self.spawnpos();	spawnpos.x = spawnpos.x-m/2; spawnpos.y = spawnpos.y+2; spawnpos.z = spawnpos.z-n/2 
	
	local players = find_player(5,spawnpos);
	if not player then self.remove() else pname = players[1] end
	
	self.spam(1);t0 = _G.minetest.get_gametime();
	data = {};
	for i = 1,m do data[i]={}; for j = 1,n do data[i][j]=0 end end

	for i=1,atoms do -- put in atoms randomly
	  data[math.random(m)][math.random(n)] = 1
	end
	
	atoms = 0
	for i = 1,m do for j = 1,n do if data[i][j]==1 then atoms = atoms + 1 end end end
	
	render_board = function(mode) -- mode 0 : render without solution, 1: render solution
		for i = 1,m do for j = 1,n do -- render game
			if mode == 0 or data[i][j] == 0 then
				if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j})~="basic_robot:button808080" then
					keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},2)
				end
			else
				keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},3)
			end
		end	end
	end
	
	get_dirl = function(dir)
		local dirl; -- direction left
		if dir[1] > 0.5 then dirl = {0,-1} 
		elseif dir[1] < -0.5 then dirl = {0,1}
		elseif dir[2] > 0.5 then dirl = {-1,0}
		elseif dir[2] < -0.5 then dirl = {1,0}
		end
		return dirl
	end
	
	read_pos = function(x,z)
		if x<1 or x>m or z<1 or z>n then return nil end
		return data[x][z]
	end
	
	newdir = function(x,z,dir) -- where will ray go next
		local retdir = {dir[1],dir[2]};
		local xf = x+dir[1]; local zf = z+dir[2] -- forward
		local dirl = get_dirl(dir)
		
		local nodef = read_pos(xf,zf)
		local nodel = read_pos(xf + dirl[1],zf + dirl[2])
		local noder = read_pos(xf - dirl[1],zf - dirl[2])
		if nodef == 1 then
			retdir = {0,0} -- ray hit something
		elseif nodel == 1 and noder ~= 1 then
			retdir = {-dirl[1],-dirl[2]}
		elseif nodel ~= 1 and noder == 1 then
			retdir = {dirl[1],dirl[2]}
		elseif nodel == 1 and noder == 1 then
			retdir = {-dir[1],-dir[2]}
		end
		return retdir
	end
	
	shootray = function(x,z,dir)
		--say("ray starts " .. x .. " " .. z .. " dir " .. dir[1] .. " " .. dir[2])
		local xp = x; local zp =  z;
		local dirp = {dir[1],dir[2]};
		local maxstep = m*n;
		
		for i = 1,maxstep do
			dirp = newdir(xp,zp,dirp);
			if dirp[1]==0 and dirp[2]==0 then return -i end -- hit
			xp=xp+dirp[1];zp=zp+dirp[2];
			if xp<1 or xp>m or zp<1 or zp>n then return i,{xp,zp} end -- out
		end
		return 0 -- hit
	end
	
	count = 0; -- how many letters were used up
	border_start_ray = function(x,z)
		local rdir 
		if x==0 then rdir = {1,0}
			elseif x == m+1 then rdir = {-1,0}
			elseif z == 0 then rdir = {0,1}
			elseif z == n+1 then rdir = {0,-1}
		end
		if rdir then
			local result,out = shootray(x,z,rdir);
			if result >= 0 then 
				
				if out then
					if out[1]==x and out[2]==z then -- got back where it originated, reflection
						keyboard.set({x=spawnpos.x+out[1],y=spawnpos.y,z=spawnpos.z+out[2]},1);
					else
						if result<=1 then
							keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},6); -- immediate bounce off
						else
							local nodename = "basic_robot:button_"..(65+count);
							_G.minetest.set_node(
							{x=spawnpos.x+out[1],y=spawnpos.y+1,z=spawnpos.z+out[2]},
							{name = nodename, param2 = 1})
							_G.minetest.set_node(
							{x=spawnpos.x+x,y=spawnpos.y+1,z=spawnpos.z+z},
							{name = nodename, param2 = 1})
							count = count + 1;
							keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},4);
							keyboard.set({x=spawnpos.x+out[1],y=spawnpos.y,z=spawnpos.z+out[2]},4);
						end
					end
				end
			elseif result<0 then
				keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},3); -- hit
			end
		end
	end
	
	-- initial border loop and marking
	
	--render blue border
	for i = 1,m do keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+0},5) keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+n+1},5) end
	for j = 1,n do keyboard.set({x=spawnpos.x+0,y=spawnpos.y,z=spawnpos.z+j},5) keyboard.set({x=spawnpos.x+m+1,y=spawnpos.y,z=spawnpos.z+j},5) end
	
	for i = 1,m do keyboard.set({x=spawnpos.x+i,y=spawnpos.y+1,z=spawnpos.z+0},0) keyboard.set({x=spawnpos.x+i,y=spawnpos.y+1,z=spawnpos.z+n+1},0) end
	for j = 1,n do keyboard.set({x=spawnpos.x+0,y=spawnpos.y+1,z=spawnpos.z+j},0) keyboard.set({x=spawnpos.x+m+1,y=spawnpos.y+1,z=spawnpos.z+j},0) end

	
	z=0 -- bottom
	for x = 1,m do 
		if keyboard.read({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z}) == "basic_robot:button8080FF" then
			border_start_ray(x,z)
		end
	end
	
	x=m+1 -- right
	for z = 1,n do 
		if keyboard.read({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z}) == "basic_robot:button8080FF" then
			border_start_ray(x,z)
		end
	end
	
	z=n+1 -- top
	for x = m,1,-1 do 
		if keyboard.read({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z}) == "basic_robot:button8080FF" then
			border_start_ray(x,z)
		end
	end
	
	x=0 -- left
	for z = n,1,-1 do 
		if keyboard.read({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z}) == "basic_robot:button8080FF" then
			border_start_ray(x,z)
		end
	end
	
	check_solution = function()
		for i = 1,m do
			for j = 1,n do
				if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j}) == "basic_robot:buttonFF8080" then -- red
					if data[i][j]~=1 then return false end
				else
					if data[i][j]~=0 then return false end
				end
			end
		end	
		return true
	end
	
	--render board
	render_board(0)
	keyboard.set({x=spawnpos.x,y=spawnpos.y,z=spawnpos.z-1},4)
	keyboard.set({x=spawnpos.x+1,y=spawnpos.y,z=spawnpos.z-1},5)
	self.label("BLACKBOX with " .. atoms .. " atoms")
	
end

event = keyboard.get();
if event then
	local x = event.x - spawnpos.x;local y = event.y - spawnpos.y;local z = event.z - spawnpos.z;
	if x<1 or x>m or z<1 or z>n then
		if event.type == 4 then
			if check_solution() then
				say("#BLACKBOX : CONGRATULATIONS! " .. event.puncher .. " found all atoms after " .. attempts .. " tries."); self.remove()
			else
				say("#BLACKBOX : " .. event.puncher .. " failed to detect atoms after " .. attempts  .. " attempts.")
				attempts = attempts+1
			end
		elseif event.type == 5 then
			say("#BLACKBOX : DISPLAYING SOLUTION",pname)
			render_board(1)
			self.remove()
		end
	else -- interior punch
			nodetype = 2;
			if keyboard.read({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z}) == "basic_robot:button808080" then 
				nodetype = 3  
			end
			keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},nodetype);
	end
		
end
::END::