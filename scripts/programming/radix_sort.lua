if not integer_sort then
	-- sorts input according to keys, changes ordering to permutation corresponding to new order
	integer_sort = function(input, keys, ordering,temp_ordering, m) -- input, keys same length n, m = how many keys,  O(2*n+m)

		local n = #input;
		local freq = {} -- frequencies of keys
		local kpos = {} -- position of keys in sorted array
		
		for i=1,n do -- count how many occurences - O(n)
			local key = keys[ordering[i]]+1;
			freq[key]=(freq[key] or 0)+1
			temp_ordering[i]=ordering[i];
		end

		local curpos = 1;kpos[1]=1;
		for i =1,m-1 do -- determine positions of keys in final sorted array - O(m)
			curpos = curpos + (freq[i] or 0);
			kpos[i+1]=curpos -- {2=3, 3 = 6,..., n-1 = 321}
		end

		-- actually place values here
		for i = 1,n do -- O(n)
			local key = keys[temp_ordering[i]]+1;
			local pos = kpos[key];
			ordering[pos] = temp_ordering[i];
			kpos[key]=kpos[key]+1; -- move to next spot for that key place
		end
	end

	permutate = function(input,ordering)
		local output = {};
		for i =1,#input do
			output[i] = input[ordering[i]]
		end
		return output
	end

	get_digits = function(Num,d,base) -- number, how many digits, what base
		local digits = {};
		local num = Num;
		local r;
		for i = 1, d do
			r = num % base;
			digits[#digits+1] = r;
			num = (num-r)/base
		end
		return digits
	end
	
	dumparr = function(array)
		if _G.type(array) ~= "table" then return array end
		local ret = "{";
		for i =1,#array-1 do
			ret = ret ..  dumparr(array[i]) .. ","
		end
		ret = ret .. dumparr(array[#array])
		return ret .. "}"
	end
	

	radix_sort = function(input,d,base) -- array of numbers; base is also number of keys = m, d = how many steps of sorting = number of digits for single number

		out = out .."\nRADIX SORT\n\narray to be sorted " .. dumparr(input)

		local n = #input;
		local ordering = {}; local temp_ordering = {}; for i = 1, n do ordering[i]=i end
		local keys = {};
		local keylist = {};
		for i = 1,n do
			keylist[i] = get_digits(input[i],d,base)
		end

		
		out = out .."\nlist of keys - ".. d .. " digits of base " .. base .. " expansion of numbers : \n" ..
		dumparr(keylist)

		for step = 1, d do
			for i =1,n do
				keys[i] = keylist[i][step];
			end
			integer_sort(input, keys, ordering, temp_ordering, base)
			
			out = out .."\n"..step .. ". pass integer_sort : "  .. dumparr(permutate(input,ordering))
		end

		out = out .. "\nradix sort final result : " .. dumparr(permutate(input,ordering))

	end


	--input = {"a","b","c","d","e"}
	--keys =  {5,3,4,1,2}
	--ordering = {}; temp_ordering = {}; for i = 1, #input do ordering[i]=i end
	--m=5;

	--integer_sort(input, keys, ordering, temp_ordering,m);
	--say(string.gsub(_G.dump(ordering),"\n",""))
	--say(string.gsub(_G.dump(permutate(input,ordering)),"\n",""))
	out = ""; self.label("")

	input = {23,42,15,8,87};
	radix_sort(input,5,3) -- d, base
	self.display_text(out,60,3)
end