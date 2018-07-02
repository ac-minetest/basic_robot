-- sliding unscramble game by rnd, made in 20 minutes
if not init then
	reward = "default:gold_ingot"
	size = 3;

	init = true
	spos = self.spawnpos(); spos.y = spos.y + 1
	board = {};
	local players = find_player(4);
	if not players then say("#sliding puzzle game: no players") self.remove() end
	name = players[1];
	
	minetest.chat_send_player(name, "#SLIDING GAME: try to sort numbers in increasing order, starting from top left")
	
	create_board = function(n)
		local k = 0;
		local ret = scramble(n*n, os.time())
		for i = 1,n do
			board[i]={};
			for j = 1,n do
				k=k+1
				board[i][j]=7+ret[k] -- 7 numbers, 82 letters
			end
		end
		board[math.random(n)][math.random(n)] = 0
	end
		
	render_board = function()
		local n = #board;
		for i = 1,n do
			for j = 1,n do
				keyboard.set({x=spos.x+i, y = spos.y, z=spos.z+j}, board[i][j]) 
			end
		end
	end
	
	check_score = function() -- check how many places are increasing in order, starting top left
		local n = #board;
		local cmax = 0;
		local score = 0;
		for j = n,1,-1 do
			for i = 1,n do
				local b = board[i][j];
				if b==0 or b<cmax then return score else score = score +1 cmax = b end
			end
		end
	end
	
	
	find_hole = function(i,j)
		if board[i][j] == 0 then return i,j end
		if i>1 and board[i-1][j] == 0 then return i-1,j end
		if i<#board and board[i+1][j] == 0 then return i+1,j end
		if j>1 and board[i][j-1] == 0 then return i,j-1 end
		if j<#board and board[i][j+1] == 0 then return i,j+1 end
		return nil
	end
	
	
	scramble = function(n,seed)
		_G.math.randomseed(seed);
		local ret = {};	for i = 1,n do ret[i]=i end
		for j = n,2,-1 do
			local k = math.random(j);
			if k~=j then 
				local tmp = ret[k]; ret[k] = ret[j]; ret[j] = tmp
			end
		end
		return ret
	end
	
	create_board(size)
	render_board()
	
end

event = keyboard.get();
if event and event.y == spos.y then
	local x = event.x-spos.x;
	local z = event.z-spos.z;
	if x<1 or x>size or z<1 or z>size then
	else
		local i,j = find_hole(x,z);
		if i then
			local tmp = board[x][z];
			keyboard.set({x=spos.x+x, y = spos.y, z=spos.z+z}, board[i][j]) 
			board[x][z] = board[i][j] 
			board[i][j]	= tmp;
			keyboard.set({x=spos.x+i, y = spos.y, z=spos.z+j}, tmp) 
		end
		local score = check_score()
		self.label("score : " .. score)
		if score >= size*size-2 then
			minetest.chat_send_player(name, "CONGRATULATIONS! YOU SOLVED PUZZLE. REWARD WAS DROPPED ON TOP OF ROBOT.") 
			pos = self.pos(); pos.y = pos.y+2;
			minetest.add_item(pos, _G.ItemStack(reward))
			self.remove()
		end
	end

end