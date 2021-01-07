if not perm2cycles then
	
	perm2cycles = function(perm)
		local n = #perm;
		local i = 1; -- already reached number
		local ret = {};
		local visited = {};
		local step = 0;
		
		while (true) do
			local cycle = {i}
			local j=i;
			
			while (true) do
				step = step +1
				if step > 2*n then return {} end
				j=perm[j];
				visited[j] = 1;
				if j and j~=cycle[1] then cycle[#cycle+1]=j  else break end
			end
			
			i=n+1;
			for k=1,n do -- find smallest non visited yet
				if not visited[k] and k<i then i = k end
			end
			
			ret[#ret+1] = cycle;
			if i == n+1 then return ret end
		end
	end

	random_permute = function(arr)
		local n = #arr;
		for i = n,3,-1 do
			local j = math.random(i);
			local tmp = arr[j]; arr[j] = arr[i]; arr[i] = tmp;
		end
	end

	get_permutations = function(n) 
		free = {}; --[1] = {stack of free for 1 : head, a1,..., a_head}
		isfree = {}; -- [i]=1 if item i free, 0 if not
		current = 1; --{1,..., current element, ... , n}
		selection = {}; 
		local data = free[1]; for i=1,n do data[i]=i isfree[i]=1 end data[0] = n;
		
		--1. pick free spot from free stack ( if not possible backtrack ) and move on onto next element ( if not possible  stay at this one)
		--   backtrack:  current--
		local data = free[current]; 
		if data[0]<1 then -- backtrack
			isfree[selection[current]] = 1;
			current = current - 1; 
			if current <=0 then return end -- exhausted all options
		else 
			local i = data[data[0]]; -- free possibility
			selection[current] = i; isfree[i] = 0;
			data[0]=data[0]-1; -- pop the stack
			--try move forward
			if current<n then
				current = current+1;
				-- get new free spots for new current
				local data = free[current]; data = {};
				for i = 1,n do if isfree[i] == 1 then data[#data+1]=i; break end end;
				data[0]=#data;
				if data[0] == 0 then -- nothing free, backtrack
					isfree[selection[current]] = 1;
					current = current - 1; 
				end
			end
		end
	end
	
	
	
	arr2string = function(arr)
		return string.gsub(_G.dump(arr),"\n","")
	end
	
	local arr = {}; for i =1,10 do arr[i] =i end; random_permute(arr);
	local cycles = perm2cycles(arr);
	say("random permutation = " .. arr2string(arr) .. " => cycles = " .. arr2string(cycles) )
	
end