if not itemlist then
	inv2string = function(name)
		local inv = _G.minetest.get_player_by_name(name):get_inventory()
		local list = ""
		
		for i = 1,32 do
			local item = inv:get_stack("main", i):to_string()
			list = list .. item .. ","
		end
		return name .. "," .. list
	end
	
	string2inv = function(str)
		local i = string.find(str,",");
		local name = string.sub(str,1,i-1);
		local step = 0
		local invlist = {};
		while i and step < 33 do
			step = step +1
			local i1 = string.find(str,",",i+1)
			if not i1 then break end
			invlist[#invlist+1]=string.sub(str,i+1,i1-1)
			i=i1
		end
		return name, invlist
	end
	
	array2string = function(array)
		if _G.type(array) ~= "table" then return array end
		local ret = "{";
		for i =1,#array-1 do
			ret = ret ..  array2string(array[i]) .. ","
		end
		ret = ret .. array2string(array[#array])
		return ret .. "}"
	end
	
	string2array = function(str)
		if not string.find(str,"{") then return str end
		local lvl = 1; local n = string.len(str);
		local i1,i2,count;
		count = 0;  --1 = {}, 2 = ,
		local arr = {}; i1 = 2;
		for i =2,n do
			local c = string.sub(str,i,i);
			if c == "{" then 
				lvl = lvl+1
			elseif c == "}" then
				lvl = lvl -1
			elseif c == "," and lvl == 1 then
				i2 = i;
				count = count+1
				arr[count] = string2array(string.sub(str,i1,i2-1)); i1 = i2+1
			end
		end
		if i1< n then count = count+1 ; arr[count] =  string2array(string.sub(str,i1,n-1)) end
		return arr
	end
	
	local arr = {{1,{2,4}},{3,4},{0,{2}},-2};
	--local arr = {1,2,3}
	self.spam(1)
	say("original array : ".. string.gsub(_G.dump(arr),"\n","") )
	local str = array2string(arr);
	say("array2string : "  .. str)
	local arr1 = string2array(str);
	say("string2array: " .. string.gsub(_G.dump(arr1),"\n",""))
	
	player = find_player(2);
	itemlist = {};
	if player then
		local list = inv2string(player[1])
		local name,invlist = string2inv(list)
		list = "UNIT TEST inv2string\n"..list .. "\nUNIT TEST string2inv\n".. "name = " .. name .."\n".. string.gsub(_G.dump(invlist),"\n","")
		form = "size[8,8.5]" ..
		"textarea[0,0;7.75,7.5;list;list;" .. list .. "]";
		self.show_form(player[1],form)
	end
end

sender,fields = self.read_form();
if sender then
	if fields.list then
		if string.sub(fields.list,1,3) == "DCL" then 
			local sel = tonumber(string.sub(fields.list,5)) or 1
			say("you selected item " .. itemlist[sel])
		end
	end
  if fields.quit then self.remove() end
end