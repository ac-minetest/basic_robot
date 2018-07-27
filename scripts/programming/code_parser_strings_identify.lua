function identify_strings(code) -- returns list of positions {start,end} of literal strings in lua code

	local i = 0; local j; local length = string.len(code);
	local mode = 0; -- 0: not in string, 1: in '...' string, 2: in "..." string, 3. in [==[ ... ]==] string
	local modes = {
		{"'","'"},
		{"\"","\""},
		{"%[=*%[","%]=*%]"}
	}
	local ret = {}
	while i < length do
		i=i+1
	
		local jmin = length+1;
		if mode == 0 then -- not yet inside string
			for k=1,#modes do
				j = string.find(code,modes[k][1],i);
				if j and j<jmin then  -- pick closest one
					jmin = j
					mode = k
				end
			end
			if mode ~= 0 then -- found something
				j=jmin
				ret[#ret+1] = {jmin}
			end
			if not j then break end -- found nothing
		else
			_,j = string.find(code,modes[mode][2],i); -- search for closing pair
			if not j then break end
			if (mode~=2 or string.sub(code,j-1,j-1) ~= "\\") then -- not (" and \")
				ret[#ret][2] = j
				mode = 0
			end
		end
		i=j -- move to next position
	end
	if mode~= 0 then ret[#ret][2] = length end
	return ret
end

identify_strings_test = function()
	local code =
	[[code; a = "text \"text\" more text"; b = 'some more text'; c = [==[ text ]==] ]]
	local strings = identify_strings(code);
	say(minetest.serialize(strings))
	for i =1,#strings do
		say(i ..": " .. string.sub(code, strings[i][1],strings[i][2]))
	end
end
identify_strings_test()

self.remove()