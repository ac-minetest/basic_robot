-- digital money: transform items into key (stand on chest and write \buy) and later get them back (\sell code)

--[[
	instructions: put items in chest, stand on top of it and say: \buy. this gives you code, you can later write in
	'\sell code' and  get stuff back.
--]]

if not init then
	self.label("digital banker bot")
	password = "super secret password"
	buydb = {};
	starttime = minetest.get_gametime()
	
	_G.minetest.forceload_block(self.pos(),true)
	
	import_inventory = function(pos) -- read inventory and output digital money
		local meta = minetest.get_meta(pos); if not meta then return end
		local inv = meta:get_inventory(); if not inv then return end
		if not inv:get_size("main") then return end
		if inv:is_empty("main") then return end
		
		local invlist = {};
		for i = 1, inv:get_size("main") do
			local stack = inv:get_stack("main", i):to_string();
			local i = string.find(stack, " ");
			local itemname = stack;
			local count = 0;
			if i then
				itemname = string.sub(stack,1,i-1)
				count = count + (tonumber(string.sub(stack,i+1)) or 1)
			end
			if count == 0 then count = 1 end			
			if itemname ~= "" then invlist[itemname] = (invlist[itemname] or 0) + count end
		end
		
		local t = minetest.get_gametime()
		local out = string.sub(serialize(invlist),7)
		inv:set_list("main",{})
		return minetest.get_password_hash("",t .. out .. password) .. " " .. t .. " " .. out
		
	end
	
	export_inventory = function(speaker,msg) -- import digital money and give items
		local i1 = string.find(msg," "); if not i1 then return end
		local i2 = string.find(msg," ",i1+1); if not i2 then return end
		local sig = string.sub(msg,1,i1-1);
		local t = tonumber(string.sub(msg,i1+1,i2-1)) or 0;
		local out = string.sub(msg,i2+1);
		local sigm = minetest.get_password_hash("",t .. out .. password);
		if sigm~=sig then return end

		if t< starttime then return end -- invalid time, before bot start
		
		if buydb[t] then -- already used, prevent double spending
			return 
		else
			buydb[t] = true; 
		end
		
		local p = minetest.get_player_by_name(speaker);
		local inv = p:get_inventory();
		local invlist = deserialize("return " ..out);
		for item, count in pairs(invlist) do
			inv:add_item("main", item .. (count==1 and "" or " " .. count))
		end
	end
	
	round = function(x) if x>0 then return math.floor(x+0.5) else return -math.floor(-x+0.5) end end
	
	init = true
	self.listen(1)
end
	
speaker,msg = self.listen_msg()
if msg then
	if msg == "buy" then
		local pos = minetest.get_player_by_name(speaker):getpos(); 
		pos.x = round(pos.x);pos.y = round(pos.y);pos.z = round(pos.z)
		if pos.y>0 then pos.y = pos.y-1 end
		local out = import_inventory(pos);
		if out then
			local text = "Your code is between BEGIN and END:\nBEGIN\n" .. out.."\nEND\nSave it for future use, to reclaim items say: /sell code. code is valid until next restart."
			local form = "size[8,8]".. "textarea[0.,0;11.,9.5;text;digital money;".. minetest.formspec_escape(text) .. "]" 
			self.show_form(speaker, form)
		end
	elseif string.sub(msg,1,4) == "sell" then
		export_inventory(speaker,string.sub(msg,6))
	end
end