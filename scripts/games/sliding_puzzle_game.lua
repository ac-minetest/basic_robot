-- sliding unscramble game by rnd, made in 20 minutes
if not init then
	init = true
	spos = self.spawnpos(); spos.y = spos.y + 1
	board = {};
	size = 3;
	
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
	end

end