
if not init then init = true
	
	deposit = function(pname)
		_, text = book.read(1);
		local data = deserialize(text) or {};
			
		local player = _G.minetest.get_player_by_name(pname)
		local inv = player:get_inventory();
		local pstack = inv:get_stack("main", 1);
		local iname = pstack:to_string()
		
		
		item, count = _G.string.match(iname,"(%S+)%s?(%d*)");
		item = item or "";if item == "" then return end
		
		count = tonumber(count) or 1;
		
		--say("item " .. item .. ", count " .. count)
		
		data[pname] = data[pname] or {};
		local pdata = data[pname];
		pdata[item] = (pdata[item] or 0) + count
		
		inv:set_stack("main", 1, _G.ItemStack(""))
		
		book.write(1,"",serialize(data))
		local form =  "size [5,5] label[0,0; You deposited " .. item .. "( " .. count .. " pieces)]"
		self.show_form(pname, form)
		--say(pname .. " deposited " .. item .. "( " .. count .. " pieces) ")
	end
	
	check = function(pname)
		_, text = book.read(1);
		local data = deserialize(text) or {};
		data[pname] = data[pname] or {};
		
		--say(serialize(data[pname]))
		local text  = serialize(data[pname])
		local form =  "size[5,5] textarea[0,0;6,6;STORAGE;STORAGE;"..
		"YOU HAVE STORED FOLLOWING ITEMS:\n\n".. minetest.formspec_escape(text) .. "\n\nUse WITHDRAW to get items back]"
		self.show_form(pname, form)
		--say(pname .. " deposited " .. item .. "( " .. count .. " pieces) ")
	end
	
	withdraw = function(pname)
		_, text = book.read(1);
		local data = deserialize(text) or {};
		data[pname] = data[pname] or {};
		
		local player = _G.minetest.get_player_by_name(pname)
		local inv = player:get_inventory();
		local pdata = data[pname]
		for k,v in pairs(pdata) do
			inv:add_item("main", _G.ItemStack(k .. " " .. v))
		end
		data[pname] = nil;
		book.write(1,"",serialize(data))
	end
	
	
	local players = find_player(4)
	if not players then self.remove() end

	pname = players[1]

	local form = "size [5,5] button[0,0;2,1;DEPOSIT;DEPOSIT] button[0,1;2,1;CHECK;CHECK] button[0,2;2,1;WITHDRAW;WITHDRAW]"
	self.show_form(pname, form)
end

sender,fields = self.read_form()
if sender then
	if fields.DEPOSIT then
		deposit(sender)
	elseif fields.CHECK then
		check(sender)
	elseif fields.WITHDRAW then
		withdraw(sender)
	end
	
	--say(sender .. " clicked " .. serialize(fields))
end
