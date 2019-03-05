compact_inventory = function(item)
	local size = 32
	local count = 0

	for i = 1,size do
		local stringname = check_inventory.self("","main",i);
		local itemname, j = stringname:match("(%S+) (%d+)")
		if itemname  == item then
			count = count + tonumber(j) 
		end
	end

	say(string.format("total count of %s is %s",item,count))

	insert.forward(string.format("%s %s",item,count)) -- will join all items together
end