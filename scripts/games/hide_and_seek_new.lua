--HIDE AND SEEK game robot
if not init then init = true
	_G.minetest.forceload_block(self.pos(),true)
	timeout = 30;
	
	gamepos = {x=0,y=11,z=0} -- game of hide and seek is played around here
	maxgamedist = 100; -- how far around gamepos player can go before kicked out of game
	gameoutpos = {x=0,y=20,z=0} -- position for players that go out of game
	
	player_list = {}; 
	s=0;t=0; count = 0;
	prize = ""

	announce = function(text) -- show message to all players in game only
		for name,_ in pairs(player_list) do
			_G.minetest.chat_send_player(name, text)
		end
	end
	

	get_players = function()
		local msg = "";
		for name,_ in pairs(player_list) do
			msg = msg .. " " .. name
		end
		return msg
	end
	
	init_game = function()
		
		local msg = get_players();		
		announce(colorize("red","# HIDE AND SEEK : hide from everyone else who is playing. Winner gets DIAMONDS\nsay join to join play. say #start to start game."..
		" players: " .. msg))
		s=0;t=0;
	end
	
	--show initial message for all players
	--minetest.chat_send_all(colorize("red","# HIDE AND SEEK : hide from everyone else who is playing. Winner gets DIAMONDS\nsay join to join play. say #start to start game.")
	
	init_game()
	_G.minetest.forceload_block(self.pos(),true)
	self.listen(1); self.label(colorize("yellow","HIDE&SEEK"))
end

speaker,msg = self.listen_msg();

if s==0 then
	
	t = t +1
	if t%30 == 0 then
		init_game();
	end
	
	if msg =="join" then 
		player_list[speaker]={};
		announce(colorize("red","# HIDE AND SEEK: " .. speaker .. " joined the game"));
		announce("players: " .. get_players())
		
		local player = _G.minetest.get_player_by_name(speaker);
		count = count + 1
		if player then 
			player:setpos(gamepos);player:set_properties({nametag_color = "0x0"}) 
			player:set_hp(20)
			local inv = player:get_inventory();inv:set_list("main",{})
		end
	
	end
	if msg == "#start" and count>1 then s = 0.5 announce(colorize("red","# HIDE AND SEEK STARTS in " .. timeout .. " SECONDS!")) end
	
elseif s==0.5 then 
	t=t+1 
	if t==timeout then 
		t=0;s = 1; count = 0; 
		for pname,_ in pairs(player_list) do
			local player = _G.minetest.get_player_by_name(pname);
			if player then 
				player_list[pname].hp = player:get_hp(); 
				player_list[pname].pos = player:getpos() 
				player_list[pname].t = 0;
				count = count+1
			end
		end
		if count == 1 then 
			init = false; announce("# HIDE AND SEEK only 1 player, aborting.") 
		else
			prize = "default:diamond " .. (count-1);
			announce(colorize("red","# HIDE AND SEEK STARTS NOW WITH " .. count .. " PLAYERS."..
			"You are out if: 1.your health changes, 2. leave game area. If stay in same area for too long or you will be exposed."))
			announce(colorize("red","# WINNER WILL GET " .. prize))
			
		end
	
	end
elseif s==1 then
	players = _G.minetest.get_connected_players();	
	count = 0;
	for _,player in pairs(players) do
		local name = player:get_player_name();
		local data = player_list[name];
		if data then
			count=count+1
			local pos = player:getpos();
			local dist = math.max(math.abs(pos.x-gamepos.x),math.abs(pos.y-gamepos.y),math.abs(pos.z-gamepos.z));
			if dist>maxgamedist or (not _G.minetest.get_player_by_name(name)) then 
				announce("# HIDE AND SEEK: ".. name .. " is OUT! went too far away " )
				player:set_properties({nametag_color = "white"})
				player_list[name] = nil;
				announce("remaining players: " .. get_players())
			end
			if data.hp ~= player:get_hp() then 
				announce("# HIDE AND SEEK: ".. name .. " is OUT! his health changed!" )
				player:set_properties({nametag_color = "white"})
				player_list[name] = nil;
				announce("remaining players: " .. get_players())
				player:setpos(gameoutpos)
			end
			
			--expose campers
			local p = data.pos;
			dist = math.max(math.abs(pos.x-p.x),math.abs(pos.y-p.y),math.abs(pos.z-p.z));
			--say( name .. " dist " .. dist .. " t " .. data.t)
			if dist<8 then
				data.t = data.t+1;
				if not data.camp then
					if data.t>25 and not data.camp then 
						_G.minetest.chat_send_player(name, "# HIDE AND SEEK: move in 5s or be exposed")
						data.camp = true
					end
				elseif data.t>=30 then
						pos.x=math.ceil(pos.x);pos.y=math.ceil(pos.y);pos.z=math.ceil(pos.z);
						announce("# HIDE AND SEEK: " .. name .. " is camping at " .. pos.x .. " " .. pos.z)
						data.camp = false; data.t = 0
				end
			else
				data.t = 0; data.pos = player:getpos(); data.camp = false
			end
			
		end
	end

	self.label(count)
	
	if count<=1 then 
		if count==1 then
			for name,_ in pairs(player_list) do
				local player0=_G.minetest.get_player_by_name(name)
				if player0 then
					announce(colorize("red","****** HIDE AND SEEK: ".. name .. " wins ******"))
					local inv = player0:get_inventory();
					inv:add_item("main",_G.ItemStack(prize))
					player0:set_properties({nametag_color = "white"})
					player0:setpos(gameoutpos)
				end
				s=2
			end
		else 
			announce("# HIDE AND SEEK: no players left")
			s=2
		end
	end

elseif s==2 then
	player_list = {}
	init_game()
end