-- nonogram game, created in 1hr 40 min by rnd

-- INIT
if not grid then 
	n=6
	solved = false -- do we render solution or blank?
--	_G.math.randomseed(3)
	
	self.spam(1)
	function get_score_from_string(score)
		--say(score)
		local scores = {};
		local j=1;    --j k   l
		for i=0,5 do -- 0 - 999 1 - 999 2 - 999 3 - 999 4 - 999 5 - 999
			j = string.find(score," ", j+1);
			local k = string.find(score," ", j+1);
			local l = string.find(score," ", k+1);
			if i==5 then l = string.len(score)+1 end
			scores[i] = {string.sub(score,j+1,k-1),tonumber(string.sub(score,k+1,l-1))};
			j=l
		end
		return scores
	end
	
	if not rom.score then _,rom.score = book.read(1) end
	if not rom.score then rom.score = "0 - 999 1 - 999 2 - 999 3 - 999 4 - 999 5 - 999" end
	highscore = get_score_from_string(rom.score)
	--self.label(string.gsub(_G.dump(highscore), "\n",""))
	
	function get_score_string(scores)
		local out = ""
		for i = 0,5 do
			out = out .. i .. " " .. 
			scores[i][1] .. " " .. 
			scores[i][2] .. " "
		end
		return out
	end
	
	t0 = _G.minetest.get_gametime()
	local intro ="numbers at beginning of each row (coloumn) tell how many\nred blocks are together in each row ( coloumn )." ..
    "\npunch gray blocks to toggle them and reveal hidden red blocks.\npunch green to check solution. If you give up punch blue.";
	self.label(intro)

	grid = {}
	spawnpos = self.spawnpos(); 
	offsetx = 10 - math.ceil(n/2); offsetz = math.floor(n/2);
	spawnpos.x = spawnpos.x - offsetx; spawnpos.z = spawnpos.z - offsetz;
	spawnpos.y = spawnpos.y+3
	
	for i=1,n do
		grid[i]={};
		for j=1,n do
			grid[i][j]=math.random(2)-1
		end
	end
	
	getcounts = function(grid)
		local rowdata = {};
		for i=1,n do
			rowdata[i]={}; local data = rowdata[i];
			local s=0;local c=0;
			for j = 1, n do
				if s == 0 and grid[i][j]==1 then s=1;c=0 end
				if s == 1 then
					if grid[i][j]==1 then 
						c=c+1 
						if j == n then data[#data+1]=c end
					else
						data[#data+1]=c; s=0
					end
					
				end
			end
		end
		local coldata = {};
		for j=1,n do
			coldata[j]={}; local data = coldata[j];
			local s=0;local c=0;
			for i = 1, n do
				if s == 0 and grid[i][j]==1 then s=1;c=0 end
				if s == 1 then
					if grid[i][j]==1 then 
						c=c+1 
						if i == n then data[#data+1]=c end
					else
						data[#data+1]=c; s=0
					end
					
				end
			end
		end
		return rowdata,coldata
	end
	
	read_field = function()
		local grid = {};
		for i = 1, n do
			grid[i]={};
			for j = 1,n do
				local typ = keyboard.read({x=spawnpos.x+j,y=spawnpos.y,z=spawnpos.z+i});
				if typ == "basic_robot:button808080" then grid[i][j] = 0 else grid[i][j] = 1 end
			end
		end
		return grid
	end
	
	rowdata,coldata = getcounts(grid)
	
	check_solution = function()
		local rdata,cdata;
		rdata,cdata = getcounts(read_field())
		for i = 1,#rdata do
			if #rdata[i]~=#rowdata[i] then return false end
			for j = 1, #rdata[i] do
				if rdata[i][j]~=rowdata[i][j] then return false end
			end
		end
		
		for i = 1,#cdata do
			if #cdata[i]~=#coldata[i] then return false end
			for j = 1, #rdata[i] do
				if cdata[i][j]~=coldata[i][j] then return false end
			end
		end
		return true
	end
	
	get_difficulty = function()
		local easy = 0;
		for k = 1, n do
			local sum=0
			for i = 1,#rowdata[k]-1 do
				sum = sum + rowdata[k][i]+1;
			end
			if #rowdata[k]>0 then sum = sum + rowdata[k][#rowdata[k]] else sum = n end
			if sum == n then easy = easy + 1 end
		end
		
		for k = 1, n do
			local sum=0
			for i = 1,#coldata[k]-1 do
				sum = sum + coldata[k][i]+1;
			end
			if #coldata[k]>0 then sum = sum + coldata[k][#coldata[k]] else sum = n end
			if sum == n then easy = easy + 1 end
		end
		easy = 5-easy;
		if easy < 0 then easy = 0 end
		return easy
	end
	
	-- render game
	for i=1,n do
		for j =1,n do
			keyboard.set({x=spawnpos.x-n+j,y=spawnpos.y,z=spawnpos.z+i},0) -- clear
			keyboard.set({x=spawnpos.x+j,y=spawnpos.y,z=spawnpos.z+2*n-i+1},0) -- clear
			local typ;
			if grid[j][i]==0 then typ = 2 else typ = 3 end
			if not solved then typ = 2 end
			keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},typ) --board
		end
	end
	
	--render counts rows
	for i=1,n do
		length = #rowdata[i]
		for k = 1,length do
			keyboard.set({x=spawnpos.x-length+k,y=spawnpos.y,z=spawnpos.z+i},rowdata[i][k]+7)
		end
	end
	--render counts coloumns
	for j=1,n do
		length = #coldata[j]
		for k = 1,length do
			keyboard.set({x=spawnpos.x+j,y=spawnpos.y,z=spawnpos.z+k+n},coldata[j][k]+7) 
		end
	end
	keyboard.set({x=spawnpos.x+1,y=spawnpos.y,z=spawnpos.z},4) -- game check button
	keyboard.set({x=spawnpos.x+2,y=spawnpos.y,z=spawnpos.z},5) -- game check button

	local players = find_player(4,spawnpos)
	if not players then error("minesweeper: no players near") end
	local pname = players[1];
	
	
	--self.label()
	
	--self.label(string.gsub(_G.dump(read_field()),"\n","") )
	difficulty = get_difficulty()
	 reward = 0; limit = 0;

	if difficulty == 5 then limit = 120 reward = 10
		elseif difficulty == 4 then limit = 115 reward = 9 -- 60s
		elseif difficulty == 3 then limit =  100 reward = 8
		elseif difficulty == 2 then limit = 80 reward = 7
		elseif difficulty <= 1 then limit = 70 reward = 6
	end
	minetest.chat_send_player(pname, "nonogram difficulty " .. difficulty .. ". you will get " .. reward .. " gold if you solve it in faster than " .. limit .."s" ..
	". Current record " .. highscore[difficulty][2] .. " by " .. highscore[difficulty][1])
	
end

event = keyboard.get()
if event then
	if event.y == spawnpos.y and event.z == spawnpos.z then
		if event.x == spawnpos.x+1 then -- check solution
			if check_solution() then 
				t = _G.minetest.get_gametime(); t = t- t0;
				local msg = "";
				keyboard.set({x=spawnpos.x+1,y=spawnpos.y,z=spawnpos.z},2)
				msg = n .. "x" .. n .. " nonogram (difficuly " .. difficulty .. ") solved by " .. event.puncher .. " in " .. t .. " seconds. "
				
				if t < limit then 
					msg = msg .. " He gets " .. reward .. " gold for quick solve.";
				else
					reward = reward*2*(1-2*(t-limit)/limit)/2; if reward<0 then reward = 0 end
					reward = math.floor(reward);
					msg = msg .. " Your time was more than " .. limit .. ", you get " .. reward .. " gold ";
				end
				
				-- highscore
				if t<highscore[difficulty][2] then 
					say("nonogram: new record " .. t .. " s ! old record " .. highscore[difficulty][2] .. "s by " .. highscore[difficulty][1])
					highscore[difficulty] = {event.puncher, t}
					rom.score = get_score_string(highscore)
					book.write(1,"scores", rom.score)
				end
				
				if reward>0 then
					local player = _G.minetest.get_player_by_name(event.puncher);
					if player then
						local inv =  player:get_inventory();
						inv:add_item("main",_G.ItemStack("default:gold_ingot " .. reward))
					end
				end
				minetest.chat_send_player(event.puncher,msg)
				
				self.remove() 
				
			else self.label("FAIL") end
		elseif event.x == spawnpos.x+2 then -- solve
			minetest.chat_send_player(event.puncher,"you gave up on game, displaying solution")
			for i=1,n do
				for j =1,n do
					local typ;
					if grid[j][i]==0 then typ = 2 else typ = 3 end
					keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},typ) 
				end
			end
			self.remove()
		end
	else
		local i = event.x-spawnpos.x;local j = event.z-spawnpos.z;
		if i>0 and i<=n and j>0 and j<=n then
			local typ = keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j});
			local newtyp;
			if typ == "basic_robot:button808080" then newtyp = 3 
				else newtyp = 2 
			end
			keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},newtyp);
		end
	end
end