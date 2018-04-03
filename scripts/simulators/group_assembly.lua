-- rnd's robot swarm assembly algorithm 2017
-- https://www.youtube.com/watch?v=xK54Bu9HFRw&feature=youtu.be&list=PLC7119C2D50BEA077
-- notes: 
--   1. limitation: there must be room for diagonal move
-- 	 	this is not big limitation: assume bots are circles of radius 1, then to allow diagonal movement 
--   	just spread them by factor sqrt(2)~1.4 initially
--   2. initial random placement(not part of move algorithm): due to collision some bots may occupy same place

if not pos then
	n=50; m  = 500;
	stuck = m;
	state = 0;
	step = 0
	
	pos = {}; tpos = {};
	-- INIT
	for i = 1, m do
		--local r = i % n;local c = (i-r)/n;pos[i]={n-c,r+1}; -- regular rectangle shape
		pos[i]={math.random(n),math.random(n)}; 
		--tpos[i]={math.random(n),math.random(n)}; -- random shape
		local r = i % n;local c = (i-r)/n;tpos[i]={c+1,r+1}; -- regular rectangle shape
	end
	doswap = true -- use closest swap or not?
	
	-- initially swap ids so that i-th bot is closest to i-th target
	permute2closest = function()
		-- swap bot i with one closest to i-th target
		free = {}; for i = 1, m do free[i] = i end -- list of available ids for swapping
		local opos = {};
		for i=1,m do opos[i] =  {pos[i][1],pos[i][2]} end
		closest = {};
		
		for i = 1,m do
			-- find closest bot to i-th point
			local dmin = 2*n;
			local jmin = -1;
			local tp = tpos[i];
			for j = 1,#free do
				local p = opos[free[j]];
				local d = math.sqrt((p[1]-tp[1])^2+(p[2]-tp[2])^2);
				if d< dmin then dmin = d; jmin = j end
			end
			if jmin>0 then
				local newj = free[jmin];
				pos[i] = {opos[newj][1], opos[newj][2]}; -- reassign id
				table.remove(free,jmin);
			end
		end
	end
	
	if doswap then
		permute2closest()
	else
		for i=1,m do pos[i] = opos[i] end -- just copy positions
	end
	
	data = {};
	
	for i = 1,n do data[i]={}; for j=1,n do data[i][j] = {0,0,1} end end -- 0/1 present, id, move status?
	for i = 1,#pos do data[pos[i][1]][pos[i][2]] = {1,i,1} end -- 1=present,i = id, 1=move status


	step_move = function()
		local count = 0;
		for i = 1, #pos do
			local p = pos[i];
			local tp = tpos[i];
			local x = tp[1]-p[1];
			local y = tp[2]-p[2];
			local d = math.sqrt(x^2+y^2); 
			if d~=0 then 
				x=x/d;y=y/d 
				x=p[1]+x;y=p[2]+y;
				x=math.floor(x+0.5);y=math.floor(y+0.5);
				if data[x][y][1]==0 then -- target is empty
					data[p[1]][p[2]][1] = 0; data[x][y][1] = 1
					pos[i]={x,y}; data[x][y][2] = i; data[x][y][3] = 1;
				end
			else 
				data[p[1]][p[2]][3] = 0 -- already at position
				count = count +1 
			end
		end
		return m-count -- how many missaligned
	end

	render = function()
		out = "";
		for i = 1,n do
			for j= 1,n do
				if data[i][j][1]==1 then
					local id = data[i][j][2]; id = id % 10;
					if data[i][j][3] == 0 then
						out = out ..  id
					else
						out = out .. "S" -- didnt move last step
					end
				else
					out = out .. "_" -- empty
				end
			end
			out = out .. "\n"
		end
		return out
	end

	s=1
	self.listen(1)
end

speaker,msg = self.listen_msg()
if speaker == "rnd" then
	if msg == "p" then
		say("permute2closest()")
		permute2closest()
	end
end

if s == 1 then 
	step = step + 1
	local c = step_move();
	--state = how many times stuck count was constant; if more than 3x then perhaps it stabilized?
	-- stuck = how many robots not yet in position
	if c<stuck then stuck = c else state = state + 1; if state > 3 then state = 0 s = 2 end end
	self.label(render().. "\nleft " .. stuck .. "="..(100*stuck/m) .. "%")
	if stuck == 0 then say("*** COMPLETED! in " ..  step .." steps ***") s = 3 end
elseif s == 2 then
	-- do swaps of stuck ones..
	for i = 1, #pos do
			local p = {pos[i][1], pos[i][2]};
			local tp = tpos[i];
			local x = tp[1]-p[1];
			local y = tp[2]-p[2];
			local d = math.sqrt(x^2+y^2); 
			if d~=0 then 
				x=x/d;y=y/d 
				x=p[1]+x;y=p[2]+y;
				x=math.floor(x+0.5);y=math.floor(y+0.5); -- see whats going on in attempted move direction
				if data[x][y][1]==1 then -- there is obstruction, do id swap
					local x1,y1;
					x1 = x; y1 = y;
					local idb = data[x][y][2]; -- blocker id, stuck robot id is i
					pos[i]={x,y};  -- new position for id-i is position of blocker
					pos[idb] = {p[1],p[2]}; -- new position for blocker is position of stuck robot
					-- reset stuck status
					data[x][y][3]=1;data[p[1]][y][p[2]]=1;
				end
			end
		end
	
	s=1
end
--TO DO: if robots stuck do permute2closest again