-- demo bot 

if not s then 
--	move.forward();--turn.angle(180)
	s=0;t=0
	mag = 3;
	
	boot = function()
		self.display_text("RND technologies\n(inc) 2016\n\n\nmemchk "..(t*1024).. "kb ",16,mag)
		t=t+1; if t == 8 then s = 0.5 t = 0 end
	end	

	boot_memchk = function()
		self.display_text("RND technologies\n(inc) 2016\n\n  ".. (8*1024).. "kb  READY",16,mag)
		t=t+1; if t==3 then t=0 s = 1 end
	end

	os_load = function()
		if t == 0 then self.display_text("============\nrndos v2.5\n============\n\nloading...\nkernel v12.2 ",12,mag) end
		t=t+1; if t == 7 then s = 2 t = 0 end
	end
	
	main_menu = function()
		if t==0 then self.display_text("MAIN MENU \n\n1) ip lister\n2) kick player\n3) teleport\n4) give fly\n5) kill\n6) turn off\n\n0 to return here from app",16,mag) end
			
		text = read_text.backward();
		if text and text~="" then
			write_text.backward("") 
			if text == "1" then s = 3 t = 0 
			elseif text == "2" then s = 4 t = 0
			elseif text == "3" then s=5 t =0 
			elseif text == "4" then s=6 t =0 
			elseif text == "5" then s=7 t =0 
			elseif text == "6" then self.remove() 
			end
		end
	end
	
	ip_lister = function()
		if t%5 == 0 then
			players = _G.minetest.get_connected_players(); msg = "IP LISTER\n\n";
			for _, player in pairs(players) do
				local name = player:get_player_name(); ip = _G.minetest.get_player_ip(name) or "";
				
				msg = msg .. name .. " " .. ip .. "\n";
			end
			self.display_text(msg,30,mag) 
			t=0
		end
		t=t+1
		if read_text.backward()  == "0" then s=2 t=0 end
		
	end

	act_on_player = function(mode)
		if t==0 then 
			msg = get_player_list()
			local txt = {[1]="KICK WHO?\n", [2] = "TELEPORT WHO HERE?\n", [3] = "GIVE FLY TO WHOM?\n", [4] = "KILL WHO?\n"}
			text = txt[mode] or "";
			self.display_text(text..msg,30,mag) t=1 
		end
		text = read_text.backward();
		if text then
			if text=="0" then s=2 t=0 else 
				write_text.backward("");
				if mode ==1 then
					_G.minetest.kick_player(player_list[tonumber(text)] or ""); 
				elseif mode ==2 then
					player =_G.minetest.get_player_by_name(player_list[tonumber(text)] or "");
					if player then player:setpos(self.spawnpos()) end
				elseif mode ==3 then
					player=_G.minetest.get_player_by_name(player_list[tonumber(text)] or "");
					if player then player:set_physics_override({gravity=0.1}) end
				elseif mode ==4 then
					player=_G.minetest.get_player_by_name(player_list[tonumber(text)] or "");
					if player then player:set_hp(0) end
				end
			end
		end
	end
	
	player_list = {}
	get_player_list =  function()
		local players = _G.minetest.get_connected_players(); local msg = ""; local i=0;
		for _, player in pairs(players) do
			local name = player:get_player_name(); 
			i=i+1;msg = msg .. i ..") " .. name .. "\n";
			player_list[i]=name;
		end
		return msg
	end

end

self.label(s)
if s == 0 then
	boot()
elseif s==0.5 then
	boot_memchk()
elseif s==1 then
	os_load()
elseif s==2 then
	main_menu()
elseif s==3 then
	ip_lister()
elseif s==4 then
	act_on_player(1)
elseif s==5 then
	act_on_player(2)
elseif s==6 then
	act_on_player(3)
elseif s==7 then
	act_on_player(4)
end