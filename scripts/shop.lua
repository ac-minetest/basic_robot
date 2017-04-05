if not s then
	s=0;item = 1; price =""; buyer = ""
	_G.minetest.forceload_block(self.pos(),true)
	_G.basic_robot.data[self.name()].obj:set_properties({nametag = ""})
	self.listen(1);self.spam(1)
	shoplist = {};
	--scan shops:
	pos = self.pos(); pos.y=pos.y-5; pos.x=pos.x-6
	pos1 = {x=pos.x-8,y=pos.y-2,z=pos.z-8};pos2 = {x=pos.x+8,y=pos.y+2,z=pos.z+8};
	local shoppos = _G.minetest.find_nodes_in_area(pos1, pos2, "shop:shop");
	--say("scanning... i found " .. #shoppos .. " shops ");
	count = 0
	for _,p in pairs(shoppos) do
		local inv = _G.minetest.get_meta(p):get_inventory()
		local s = inv:get_list("sell");local b = inv:get_list("buy")
		local k = s[1]:to_string();
		local v = b[1]:to_string();
		if (k and k~="") and (v and v~="") then count = count +1 shoplist[count] = {k,v}  end
	end
	
	local f_sort = function(a,b) return a[1]<b[1] end; 
	table.sort(shoplist,f_sort)

	itemlist = ""; count = 0;
	shopinventory = {};
	for k,v in pairs(shoplist) do
		if v[1] then
			count = count +1
			itemlist = itemlist .. string.format("%-5s%-40s%-32s",k,v[1],v[2]) .. ","
		end
	end
	t = 0; ct = 0;	ci = 0
	say("scanning shops ... completed. Added " .. count .. " items for sale ");
end


ct=ct+1
if ct%5 == 0 then
	ct=0
	ctext = "say #shop to buy";
	if ci>0 and ci<=count then
		if shoplist[ci] then
			iname = shoplist[ci][1];local p=string.find(iname,":");	if p then iname = string.sub(iname,p+1) end
			sname = shoplist[ci][2];p=string.find(sname,":");	if p then sname = string.sub(sname,p+1) end
			ctext = "#SHOP ".. ci .."\n" ..iname .. "\nPRICE\n" .. sname
		end
		ci=ci+1
	elseif ci == count+1 then ci=0
	elseif ci == 0 then ci=1
	end
	
	text = "SHOP ROBOT"..os.date("%x") .."  " .. os.date("%H:%M:%S").. "\n\n"..ctext
	self.display_text(text,10,3);
end

speaker,msg = self.listen_msg()
if msg then
	if s == 0 then
		if string.sub(msg,1,5)=="#shop" then
			if msg == "#shop" then
				--say("say #shop command, where command is list OR armor OR item number. Example: #shop list or #shop 1")
				
				local list = "1,2,3";
				local form = "size[8,8.5]" ..
				"label[0.,0.5;ID]"..
				"label[0.4,0.5;BUY]"..
				"label[3.,0.5;SELL]" ..
				"field[7.2,0.25;1.,1;count;count;".. 1 .."]"..
				"button[5.,-0.05;2.,1;ARMOR;ARMOR]"..
				"textlist[0,1;7.75,7.5;list;" .. itemlist .. "]";
				self.show_form(speaker,form)
			end
		end
	elseif s == 1 then 
		if string.sub(msg,1,3)~="buy" then 
			t=t+1; if t>1 then say("timeout. trade cancelled."); s = 0 end
		else
			
			
			s=0
		end
	end
end

sender,fields = self.read_form()
if sender then
	local sel = fields.list; --"CHG:3"
	--say( string.gsub(_G.dump(fields),"\n",""))
	if sel and string.sub(sel,1,3) == "DCL" then
		local quantity = tonumber(fields.count) or 1;
		local select = tonumber(string.sub(sel,5) or "") or 1;
		local item, price
		
		if shoplist[select] then
			item,price = shoplist[select][1],shoplist[select][2];
		end
		
		local player = _G.minetest.get_player_by_name(sender);
		if player and item and price then
			
			local inv = player:get_inventory();
			if quantity > 99 then quantity = 99 end
			if quantity > 1 then
				local k = 1;
				local i = string.find(price," ");
				if i then 
					k = tonumber(string.sub(price,i+1)) or 1 
					price = string.sub(price,1,i-1).. " " .. k*quantity
				else 
					price = price.. " " .. quantity
				end
				
				k=1;i = string.find(item," ");
				if i then 
					k = tonumber(string.sub(item,i+1)) or 1 
					item = string.sub(item,1,i-1).. " " .. k*quantity
				else
					item = item .. " " .. quantity
				end
			end
			
			if inv:contains_item("main", price ) then 
				inv:remove_item("main",price)
				inv:add_item("main",item)
				_G.minetest.chat_send_player(sender,"#SHOP ROBOT: " .. item .. " sold to " .. sender .. " for " .. price)
			else 
				_G.minetest.chat_send_player(sender,"#SHOP ROBOT: you dont have " .. price .. " in inventory ")
			end
		end
	elseif fields.ARMOR then
		local player = _G.minetest.get_player_by_name(sender);
		if player then
			local inv = player:get_inventory();
			if inv:contains_item("main",_G.ItemStack("default:diamond 30")) then
				player:set_armor_groups({fleshy = 50})
				_G.minetest.chat_send_player(sender,"#SHOP ROBOT: you bought 50% damage reduction.")
			else
				_G.minetest.chat_send_player(sender,"#SHOP ROBOT: you need 30 diamonds to get armor effect")
			end
		end
	end
end