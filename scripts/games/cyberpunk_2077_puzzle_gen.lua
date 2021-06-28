--cyberpunk 2077 'breach protocol puzzle' generator
--by rnd, 20 min


if not init then init = true
	n=4; -- size of square
	steps = n*n; -- length of sequence
	tries = n*10; -- how many tries in current row/col before giving up

	tb = {};
	for i = 1,n do 
		tb[i] ={}; local tbi = tb[i] 
		for j = 1,n do 
			tbi[j] = (i-1)*n+j
		end 
	end

	--make random path col/row/col... starting at random position

	row = true;
	posi = 1; -- row
	posj = 1; -- col
	path = {}
	used = {}; -- [num] = true, when taken
	
	for i = 1, steps do
	if row then
		local tmp = posj;
		local s = 0
		while (tmp == posj or used[tb[posi][tmp]]) and s < tries do
			tmp = math.random(n);
			s=s+1
		end
		if s == tries then say("stuck at lenght " .. #path) break end
		posj = tmp
	else
		local tmp = posi;
		local s = 0
		while (tmp == posi or used[tb[tmp][posj]]) and s < tries do
			tmp = math.random(n);
			s=s+1
		end
		if s == tries then say("stuck at lenght " .. #path) break end
		posi = tmp
	end
	row = not row
	path[#path+1] = tb[posi][posj];
	used[path[#path]] = true
	end
	
	local ret = {};
	for i = 1,n do
		for j = 1,n do
			ret[#ret+1] = string.format("%02d",(i-1)*n+j).." ";
		end
		ret[#ret+1] = "\n"
	end	
	

	self.label(table.concat(path," ") .. "\n\n"..table.concat(ret))

end


