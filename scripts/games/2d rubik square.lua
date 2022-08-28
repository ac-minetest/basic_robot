-- 2d rubik cube slide puzzle by rnd in 40 mins

if not init then init = true
	m=4;
	n=m;
	data = {};
	
	nodelist = {};
	for i = 1,m do
		for j = 1,n do
			nodelist[(i-1)*n+j] = "basic_robot:button_"..(64+(n-j+1-1)*n+i)
		end
	end
	
	for i = 1,m do 
		data[i] = {};local dat = data[i]; 
		for j = 1,n do
			dat[j] = (i-1)*n+j;
		end
	end
	spos = self.spawnpos(); spos.x=spos.x+1; spos.z=spos.z+1
	
	
	render = function(t,mode) -- mode 1:row, 2: coloumn
		if not mode then
			for i=1,m do
				for j = 1,n do
					minetest.swap_node({x=spos.x+i,y=spos.y,z=spos.z+j},{name = nodelist[data[i][j]]})
				end
			end
			return
		end
		
		if mode == 1 then -- row only
			for i=1,m do
				minetest.swap_node({x=spos.x+i,y=spos.y,z=spos.z+t},{name = nodelist[data[i][t]]})
			end
			return
		else -- coloumn only
			for j=1,n do
				minetest.swap_node({x=spos.x+t,y=spos.y,z=spos.z+j},{name = nodelist[data[t][j]]})
			end
			return
		end
	end
	
	pnames = find_player(4);
	if not pnames then self.remove() end
	player = minetest.get_player_by_name(pnames[1]);
	
	
	check_rot_dir = function()
		local vdir = player:get_look_dir()
		local mode = 0;
		if math.abs(vdir.x)<math.abs(vdir.z) then 
			if vdir.z>0 then 
				mode = 2
			else
				mode = -2
			end	
		else
			if vdir.x>0 then
				mode = 1
			else
				mode = -1
			end
		end -- rotate in z dir
		return mode
	end
	
	rotx = function(col,dir)
		if dir > 0 then
			local tmp = data[1][col]
			for i = 1,m-1 do
				data[i][col] = data[i+1][col]
			end
			data[m][col] = tmp
		else
			local tmp = data[m][col]
			for i = m,2,-1 do
				data[i][col] = data[i-1][col]
			end
			data[1][col] = tmp
		end
	end
	
	rotz = function(row,dir)
		if dir > 0 then
			local tmp = data[row][1]
			for j = 1,n-1 do
				data[row][j] = data[row][j+1]
			end
			data[row][m] = tmp
		else
			local tmp = data[row][n]
			for j = n,2,-1 do
				data[row][j] = data[row][j-1]
			end
			data[row][1] = tmp
		end
	end
	
	rndshuffle = function(steps)
		for step = 1,steps do
			local mode = math.random(4);
			if mode <=2 then
				local z = math.random(m);
				if mode == 2 then mode = -1 end
				rotx(z,mode)
			else
				local x = math.random(n);
				if mode == 3 then mode = -2 else mode = 2 end
				rotz(x,mode)
			end
		end		
	end
	
	self.listen_punch(self.pos())
	
	self.label("try to get all letters sorted started with A top left")
	rndshuffle(m*n)
	render()
end

event = keyboard.get()
if event then 
	--self.label(serialize(event))
	local x = event.x-spos.x;
	local z = event.z-spos.z;
	local mode = check_rot_dir() 
	if x>0 and x<=m and z>0 and z<=n then
		if math.abs(mode) == 1 then 
			rotx(z,-mode) 
			render(z,1)
		else 
			rotz(x,-mode) 
			render(x,2)
		end
	end
	
end
