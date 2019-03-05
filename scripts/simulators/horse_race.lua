if not init then init = true
	horses = {10,5,5,5,5,5}; -- ratings, probability that horse wins is proportional to its rating

	
	
	local rndseed = 1;
	local random = function(n)
		rndseed = (48271*rndseed)% 2147483647;
		return rndseed % n
	end
	
	-- race simulation: output is winner, 2nd, 3rd, ...
	-- algorithm sketch: first choose 1st, then from  remainder select 2nd, then ...

	race = function(horses)
	
		rndseed = os.time()
		local n = #horses; local sum = 0
		local res = {};
		for i = 1,n do sum = sum + horses[i]; res[i]=i end
		
		for i = 1,n do
			-- select random idx  from i..n as winner of i-th round
			local sel = random(sum);
			--find first j such  that partial sums i,..,j exceed sel ( probability that horse will be selected is proportional to its rating)
			local psum = 0; local j = n
			for k = i,n do
				psum = psum + horses[res[k]]
				if psum>= sel then j = k break end
			end
			--dout(i..".  j= " ..j .. ", sel " .. sel )
			
			--swap j-th and i-th to put selected horse on i-th position
			local tmp = res[j]; res[j] = res[i]; res[i] = tmp
			sum = sum - horses[ tmp ] -- remove winner from sum
		end
		return res
	end

	self.label( serialize(race(horses)) )
	
end