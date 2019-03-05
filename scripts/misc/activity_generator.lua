-- ACTIVITY GENERATOR + modified /status
-- makes server appear more active: virtual players join/leave, talk

if not init then
	minetest.forceload_block(self.pos(),true)
	self.label("activity generator")
	local chatc = _G.core.registered_chatcommands["status"];
	if chatc then 

	if not rom.chatc then rom.chatc = chatc end
	--self.label(serialize(chatc)) 
	hidden_players = {
		rnd = false,
	}
	
	extra_players = {
	"Piojoblanco","Bryan0911","EmmaBTS","atmaca","pausc05","bobo","marquez","Maike-008","odiseu","jere700182","_z","erick07","elvergalarga01","follow","Mantano10","AW","0987654321","lavraimeriem","formless","kanekii","cuchita","X_Pro_X","Tron","MGPe","Budrow42","lahina","shaahin18","dolphin","Stickman301","Galves58","Appelbaum747jdjxi","agy","E23","Utsler26","Rafael_Aaron_PROOO","cloe","Athans82","Love_Girl","jklu","Marne485hv","xXNicoXx","Dootson22","squad","fatima","Cucuzza62"
	}
	extra_joined = {};
	
	greetings = {"hi","hello","pls help","help","how to play?", "i have only 2 blocks?","cool",":(","someone help","HI"}
	
	_G.core.registered_chatcommands["status"] = 
	{
		description = "Print server status",
		func = function(name, param)
			local connected = minetest.get_connected_players();
			local ret = {};
			for i = 1,#connected do
				local pname = connected[i]:get_player_name();
				if not hidden_players[pname] then ret[#ret+1] = pname end
			end
			local clients = table.concat(ret,", ");
			local extras = {};
			for name,_ in pairs(extra_joined) do extras[#extras+1] = name end
			if #extras>0 then clients = clients ..", " .. table.concat(extras, ", ") end
			return true, "# Server: version=0.4.17.1, uptime = ".. math.floor(minetest.get_server_uptime()*10)/10 ..", max_lag = 0.1, clients = {".. clients .. "}"  
			
		end,
	}

	--_G.core.registered_chatcommands["status"] = rom.chatc -- uncomment this to restore

	end
	t=0
	init = true
end
t=t+1;

if t%5 == 0 then
	local r = math.random(10)
	if r <= 2 then -- add random new player
		--say(t)
		local idx = math.random(#extra_players)
		local pname = extra_players[idx];
		if pname and not extra_joined[pname] then 
			extra_joined[pname] = true 
			minetest.chat_send_all("*** " .. pname .. " joined the game.")
		end
	elseif r<=4 then -- disconnect random extra
		local count = 0;
		for pname,_ in pairs(extra_joined) do count = count + 1 end
		local idx = math.random(count)
		count = 0;
		for pname,_ in pairs(extra_joined) do 
			count = count + 1
			if count == idx then 
				minetest.chat_send_all("*** " .. pname .. " left the game.")
				extra_joined[pname] = nil
				break
			end 
		end
	elseif r<=6 then -- chat
		if math.random(5) == 1 then
			local count = 0
			for pname,_ in pairs(extra_joined) do count = count + 1 end
			local idx = math.random(count)
			count = 0;
			for pname,_ in pairs(extra_joined) do 
				count = count + 1
				if count == idx then 
					r = math.random(#greetings);
					minetest.chat_send_all("<" .. pname .. "> " ..greetings[r])
					break
				end 
			end
		end
	end
end

--self.remove()