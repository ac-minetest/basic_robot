
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
		
		pdata[item] = pdata[item] or {};
		
		local t = minetest.get_gametime()
		pdata[item][1] = (pdata[item][1] or 0) + count
		pdata[item][2] = t;
		
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
		return serialize(data[pname])
	end
	
	withdraw = function(pname)
		_, text = book.read(1);
		local data = deserialize(text) or {};
		data[pname] = data[pname] or {};
		
		local player = _G.minetest.get_player_by_name(pname)
		local inv = player:get_inventory();
		local pdata = data[pname]
		local t0 = minetest.get_gametime();
		
		for k,v in pairs(pdata) do
			local t = t0 - v[2]; -- time since last deposit
			local a = (1+interests/100)^t; 
			self.label("deposited time " .. t .. ", deposited quantity " .. v[1] .. ", new quantity : " .. math.floor(a*tonumber(v[1])) )
			inv:add_item("main", _G.ItemStack(k .. " " .. math.floor(a*tonumber(v[1]))) )
		end
		data[pname] = nil;
		book.write(1,"",serialize(data))
	end
	
	
	function show(pname)
		local itemlist = check(pname)
		local form = "size [5,5] button[0,0;2,1;DEPOSIT;DEPOSIT] button[0,1;2,1;WITHDRAW;WITHDRAW]" ..
		"textarea[0,2.5;6,3;STORAGE;YOUR DEPOSITS;" .. minetest.formspec_escape(itemlist) .. "]"
		self.show_form(pname, form)
	end
	
	
	interests = 5; -- interest rate per second (demo)
	local players = find_player(4)
	if not players then self.remove() end
	show(players[1])
	
end

sender,fields = self.read_form()
if sender then
	if fields.DEPOSIT then
		deposit(sender)
		show(sender)
	elseif fields.WITHDRAW then
		withdraw(sender)
		show(sender)
	end
	
	--say(sender .. " clicked " .. serialize(fields))
end