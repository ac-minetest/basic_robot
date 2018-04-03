--HIDE AND SEEK game robot, by rnd
if not gamemaster then
	timeout = 10;
	gamemaster = "rnd"
	player_list = {}; 
	_G.minetest.chat_send_all("# HIDE AND SEEK .. say #hide to join play")
	s=0;t=0; count = 0;
	_G.minetest.forceload_block(self.pos(),true)
	self.listen(1); self.label(colorize("yellow","HIDE&SEEK"))
end

speaker,msg = self.listen_msg();

if s==0 then
	if msg =="#hide" then 
		player_list[speaker]={};
		_G.minetest.chat_send_all("# HIDE AND SEEK: " .. speaker .. " joined the game")
		local player = _G.minetest.get_player_by_name(speaker);
		if player then 
			player:setpos({x=0,y=5,z=0});player:set_properties({nametag_color = "0x0"}) 
		end
	
	end
	if msg == "#start" and speaker == gamemaster then s = 0.5 _G.minetest.chat_send_all("# HIDE AND SEEK STARTS in " .. timeout .. " SECONDS!") end
	
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
			gamemaster = false; _G.minetest.chat_send_all("# HIDE AND SEEK only 1 player, aborting.") 
		else
			_G.minetest.chat_send_all(colorize("red","# HIDE AND SEEK STARTS NOW WITH " .. count .. " PLAYERS. You are out if: 1.your health changes, 2. leave spawn. If stay in same area for too long or you will be exposed."))
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
			local dist = math.max(math.abs(pos.x),math.abs(pos.y),math.abs(pos.z));
			if dist>50 or (not _G.minetest.get_player_by_name(name)) then 
				_G.minetest.chat_send_all("# HIDE AND SEEK: ".. name .. " is OUT! went too far away " )
				player:set_properties({nametag_color = "white"})
				player_list[name] = nil;
			end
			if data.hp ~= player:get_hp() then 
				_G.minetest.chat_send_all("# HIDE AND SEEK: ".. name .. " is OUT! his health changed!" )
				player:set_properties({nametag_color = "white"})
				player_list[name] = nil;
			end
			
			--expose campers
			local p = data.pos;
			dist = math.max(math.abs(pos.x-p.x),math.abs(pos.y-p.y),math.abs(pos.z-p.z));
			--say( name .. " dist " .. dist .. " t " .. data.t)
			if dist<8 then
				data.t = data.t+1;
				if not data.camp then
					if data.t>15 and not data.camp then 
						_G.minetest.chat_send_player(name, "# HIDE AND SEEK: move in 5s or be exposed")
						data.camp = true
					end
				elseif data.t>=20 then
						pos.x=math.ceil(pos.x);pos.y=math.ceil(pos.y);pos.z=math.ceil(pos.z);
						_G.minetest.chat_send_all("# HIDE AND SEEK: " .. name .. " is camping at " .. pos.x .. " " .. pos.z)
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
				player0=_G.minetest.get_player_by_name(name)
				_G.minetest.chat_send_all(colorize("red","****** HIDE AND SEEK: ".. name .. " wins ******"))
				player0:set_properties({nametag_color = "white"})
				gamemaster = false;
			end
		else 
			_G.minetest.chat_send_all("# HIDE AND SEEK: no players left")
			gamemaster = false;
		end
	end
	
end