N = 30; -- length of program (without ])

desired_frequencies = {
	[">"] = 10,
	["<"] = 10,
	["-"]=10,
	["+"]=20,
	["."]=10,
	[","]=10,
	["["]=10, -- matching "]" will be inserted automatically!
}
matching_parenthesis = "]";
routine_lower = 1; routine_higher = 5; -- specify range, how many characters in routine [.....]

generate_selections = function(desired_frequency)
	local sum = 0
	for k,v in pairs(desired_frequency) do sum = sum + v end
	local isum = 0; local count = 0; local selections = {}
	for k,v in pairs(desired_frequency) do count = count +1 isum = isum + desired_frequency[k]/sum; selections[count] = {isum,k} end
	return selections
end

choose = function(selections, rnd)
	local low, mid, high;
	low = 1; high = #selections; mid = math.floor((low+high)/2)
	local step = 0;
	while high-low>1 and step < 20 do
		step = step + 1
		if rnd <= selections[mid][1] then high = mid else low = mid end
		mid = math.floor((low+high)/2)
	end
	return selections[mid][2]
end


generate_program = function(desired_frequencies,N, routine_lower, routine_higher)
	local selections = generate_selections(desired_frequencies);

	local ret = {};
	local count = 0
	local stack = {};

	for count = 1, N do
		local choice = choose(selections, math.random());
		if choice == "[" then 
			local i = count + math.random(routine_lower,routine_higher) 
			if i > N then i = N end
			stack[#stack+1] = i;
		end
		ret[count] = choice 
	end

	for i = 1,#stack do local j = stack[i] ret[j]=ret[j]..matching_parenthesis end
	return table.concat(ret)
end

say(generate_program(desired_frequencies,N, routine_lower, routine_higher))

self.remove()