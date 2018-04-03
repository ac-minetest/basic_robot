--COMMAND ROBOT by rnd, v2, adapted for skyblock
if not s then
	self.listen(1) 
	s=1;_G.minetest.forceload_block(self.pos(),true)
	self.spam(1)
	users = {["rnd"]=3,["rnd1"]=3,["Giorge"]=1,["quater"]=1,["UltimateNoob"]=1,["reandh3"]=1,["karo"]=1,["Fedon"]=1,["DS"]=2,
	["Arcelmi"]=1,["Gregorro"]=1,Mokk = 1, Evandro010 = 1}
	cmdlvl = {["kill"]=2,["tp"]=3,["heal"]=1, ["rename"]=1,["jump"]=1,["givediamond"]=3, ["msg"]=1,["calc"]=0, ["acalc"]=3,["run"]=3, ["shutdown"] = 3,["sayhi"]=0, ["day"] = 1};
	
	tpr = {};
	
	cmds = {
		help = 
		{
			level = 0,
			run = function(param)
				local arg = param[2];
				if not arg then 
					say(colorize("red","OPEN INVENTORY AND READ 'Quests'. YOU GET REWARD AND BETTER STUFF FOR COMPLETING QUESTS. Say /spawn to get to spawn area."))
					return
				end
				
				if arg and cmds[arg] then
					local text = cmds[arg]["docs"];
					if text then say(text) end
				else 
				--say(colorize("red","commands") .. colorize("LawnGreen",": 0 status, 2 kill $name, 3 tp $name1 $name2, 1 heal $name, 1 day, 1 rename $name $newname, 3 givediamond $name, 1 msg $name $message, 0 sayhi, 0 calc $formula, 3 acalc $formula, 3 run $expr"))
					local msg = ""
					for k,v in pairs(cmds) do
						msg = msg .. v.level .. " " .. k .. ", "
					end
					say(colorize("red","commands") .. " " .. colorize("LawnGreen", msg))
				end
			end,
			docs = "Displays available commands. 'help command' shows help about particular command"
		},
		
		status = 
		{
			level = 0,
			run = function(param)
				local usr = param[2] or speaker;
				local id = _G.skyblock.players[usr].id;
				local pos = _G.skyblock.get_island_pos(id)
				minetest.chat_send_all(minetest.colorize("yellow",
					usr .. " data : permission level  " .. (users[usr] or 0).. ", island " .. id .." (at " .. pos.x .. " " .. pos.z .. "), skyblock level " .. _G.skyblock.players[usr].level
				))
			end,
			docs = "status name, Show target(speaker if none) level, which determines access privilege."
		},
		
		kill = 
		{
			level = 2,
			run = function(param)
				local name = param[2]; if not name then return end
				local player = _G.minetest.get_player_by_name(name);
				if player then 
					if (users[name] or 0)<=(users[speaker] or 0) then player:set_hp(0) end 
				end
			end,
			docs = "kill name; kills target player",
		},
		
		tp = 
		{
			level = 2,
			run = function(param)
				local player1 = _G.minetest.get_player_by_name(param[2] or "");
				local player2 = _G.minetest.get_player_by_name(param[3] or "");
				if player1 and player2 then if (users[param[2]] or 0)<=(users[speaker] or 0) then player1:setpos(player2:getpos()) end end
			end,
			docs = "tp name1 name2; teleports player name2 to name2",
		},
		
		tpr = 
		{
			level = 0,
			run = function(param)
				local name = param[2] or "";
				local player1 = _G.minetest.get_player_by_name(name);
				if player1 then tpr = {speaker, name} else return end
				_G.minetest.chat_send_player(name,minetest.colorize("yellow","#TELEPORT REQUEST: say tpy to teleport "  .. speaker .. " to you."))
				
			end,
			docs = "tpr name; request teleport to target player",
		},
		
		tpy = 
		{
			level = 0,
			run = function(param)
				if speaker == tpr[2] then 
					local player1 = _G.minetest.get_player_by_name(tpr[1] or "");
					local player2 = _G.minetest.get_player_by_name(tpr[2] or "");
					if player1 and player2 then else return end
					player1:setpos(player2:getpos())
					_G.minetest.chat_send_player(tpr[2],minetest.colorize("yellow","#teleporting "  .. tpr[1] .. " to you."))
					tpr = {}
				end
				
			end,
			docs = "tpy; allow player who sent teleport request to teleport to you.",
		},
		
		calc = 
		{
			level = 0,
			run = function(param)

				local formula = param[2] or "";
				if not string.find(formula,"%a") then 
					result = 0;
					code.run("result = "..formula);
					result = tonumber(result)
					if result then say(result) else say("error in formula") end
				else
					say("dont use any letters in formula")
				end
			end,
			docs = "calculate expression",
		},
		
		day = 
		{
			level = 1,
			run = function() minetest.set_timeofday(0.25) end,
			docs = "set time to day"
		},
		
		sayhi = 
		{
			level = 0,
			run = function() 
				local players = _G.minetest.get_connected_players();local msg = "";
				for _,player in pairs(players) do 
					local name = player:get_player_name();
					local color = string.format("#%x",math.random(2^24)-1)
					if name~=speaker then msg = msg..colorize(color , " hi " .. name) .."," end
				end
				_G.minetest.chat_send_all("<"..speaker..">" .. string.sub(msg,1,-2))
			end,
			docs = "say hi to all the other players"
		},
		
		msg = {
			level = 2,
			run = function(param)
				local text = string.sub(msg, string.len(param[1] or "")+string.len(param[2] or "") + 3)
				local form = "size [8,2] textarea[0.,0;8.75,3.75;book;MESSAGE from " .. speaker .. ";" .. _G.minetest.formspec_escape(text or "") .. "]"
				_G.minetest.show_formspec(param[2], "robot_msg", form);
			end,
			docs = "msg name message, displays message to target player",
			
		},
		
		plist = {
			level = 0,
			run = function()
				local p = {};
				for k,v in pairs(minetest.get_connected_players()) do 
					local name = v:get_player_name()
					local pdata =  _G.skyblock.players[name]
					p[#p+1] = name..", level " .. pdata.level .. "+" .. pdata.completed .. "/" .. pdata.total
				end
				local text = table.concat(p,"\n")
				local form = "size [8,5] textarea[0.,0;8.75,6.75;book;PLAYERS;" .. _G.minetest.formspec_escape(text or "") .. "]"
				_G.minetest.show_formspec(speaker, "robot_msg", form);
			end,
			docs = "plist, displays player list and their levels",
			
		},
		
		run = {
			level = 3,
			run = function(param)
				local expr = string.sub(msg,5);
				--say("running " .. expr)
				code.run(expr);
			end,
			docs = "run lua code",
		},
	}
	
	self.label(colorize("red","\nCMD ROBOT"))
end
speaker, msg = self.listen_msg();

if msg then
	local words = {};
	for word in string.gmatch(msg,"%S+") do words[#words+1]=word end -- extract words
	
	local level = users[speaker] or 0;
	local cmd = words[1];
	
	cmdlevel = cmdlvl[cmd] or 0;
	if level < cmdlevel then
		say("You need to be level " .. cmdlevel .. " to use " .. words[1])
	else	
		if cmds[cmd] then
			cmds[cmd].run(words)
		elseif words[1]=="heal" and words[2] then
			local player = _G.minetest.get_player_by_name(words[2]);
			if player then player:set_hp(20) end
		elseif words[1]=="rename" then
			local player = _G.minetest.get_player_by_name(words[2]); 
			if player then if ((users[words[2]] or 0)<=level) and (level>=3 or words[2]~=speaker) then player:set_nametag_attributes({text = words[3] or words[2]}) end end
		elseif words[1]=="robot"then
			local player = _G.minetest.get_player_by_name(words[2])
			if player then
			player:set_properties({visual = "cube"});
			player:set_properties({textures={"arrow.png^[transformR90","basic_machine_side.png","basic_machine_side.png","basic_machine_side.png","face.png","basic_machine_side.png"}})
			player:set_properties({collisionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5}})
			end
		elseif words[1] == "mese" then
			local player = _G.minetest.get_player_by_name(words[2])
			if player then
			player:set_properties({visual = "mesh",textures = {"zmobs_mese_monster.png"},mesh = "zmobs_mese_monster.x",visual_size = {x=1,y=1}})
			end
		
		elseif words[1] == "givediamond" then
			local player = _G.minetest.get_player_by_name(words[2])
			local pos = player:getpos();
			_G.minetest.add_item(pos,_G.ItemStack("default:diamond"))
		elseif words[1] == "acalc" then
			local formula = words[2] or "";
			if not string.find(formula,"_G") then 
				result = 0;
				code.run("result = "..formula);
				result = tonumber(result)
				if result then say(result) else say("error in formula") end
			end
		elseif words[1] == "shutdown" then
			_G.minetest.request_shutdown("maintenance, come back",true)
		elseif words[1] == "web" then
			local text = string.sub(msg,5);
			local f = _G.io.open("H:\\sfk\\files\\index.html", "w")
			f:write(text);f:close()
		
		end
	end
end