	-- simple ctf robot, rnd
	--instructions: build game arena and place blue/red buttons as flags. edit flag positions below
	--you must register 'keyboard' events by placing robot with same 'id' as robot running this code at 'event register' positions - default (32*i,64*j+1, 32*k)

	if not ctf then
		_G.minetest.forceload_block(self.pos(),true)
		ctf = {
		  [1] = {state = 1, flagnode = "basic_robot:button8080FF", pos = {x=-18,y=502,z=110}, name = "blue", owner = "", score = 0}, -- team[1]
		  [2] = {state = 1, flagnode = "basic_robot:buttonFF8080", pos = {x=-18,y=502,z=80}, name = "red", owner = "", score = 0}, -- team[2]
		}
		
		teams = {} -- example : {["rnd"] = {1,0, player, health points at start}}; -- team, ownership of flag
		maxscore = 3;
		t = 0	
		teamid = 1; -- team selector when joining
		
		gamestate = 0;
		self.listen(1)
		self.spam(1)
		
		get_id = function(pos)
			local range = 1000;
			return pos.x + range*pos.y+range^2*pos.z
		end
		
		flag_id = {}; for i = 1,#ctf do flag_id[get_id(ctf[i].pos)] = i end
		
		render_flags = function()
			for i = 1,#ctf do minetest.set_node(ctf[i].pos, {name = ctf[i].flagnode}) end
		end

	end

	if gamestate == 0 then -- welcome
		say(colorize("red","#CAPTURE THE FLAG GAME. say '\\join' to join game. to start game one of joined players says '\\start'"))
		gamestate = 1
	elseif gamestate == 1 then
		speaker,msg = self.listen_msg()
		if msg == "join" then
			local pl = minetest.get_player_by_name(speaker);
			teams[speaker] = {teamid, 0, pl,20};pl:set_hp(20)
			local msg1 = ""; local msg2 = ""
			for k,v in pairs(teams) do
				if v[1] == 1 then msg1 = msg1 .. k .. " " elseif v[1] == 2 then msg2 = msg2 .. k .. " " end
			end
			
			say(colorize("yellow","#CTF : " .. speaker .. " joined team " .. ctf[teamid].name .. ". TEAM " .. ctf[1].name .. ": " .. msg1 .. ", TEAM " .. ctf[2].name .. ": " .. msg2))
			teamid = 3-teamid; -- 1,2
		elseif msg == "start" then -- game start
			if teams[speaker] then
				gamestate = 2
				keyboard.get() -- clear keyboard buffer
				say(colorize("red","#CTF GAME STARTED. GET ENEMY FLAG AND BRING IT BACK TO YOUR FLAG. DONT LET YOUR HEALTH GO BELOW 3 HEARTS OR YOU ARE OUT."))
				for k,_ in pairs(teams) do -- teleport players
					local data = teams[k];data[3]:setpos( ctf[data[1]].pos )
				end
				render_flags()
			end
		end

	elseif gamestate == 2 then
		speaker,msg = self.listen_msg()
		if msg == "score" then 
			local msg1 = ""; local msg2 = ""
			for k,v in pairs(teams) do
				if v[1] == 1 then msg1 = msg1 .. k .. " " elseif v[1] == 2 then msg2 = msg2 .. k .. " " end
			end
			say(colorize("yellow","SCORE " .. ctf[1].score .. "/" .. ctf[2].score) .."\n" .. colorize("yellow","TEAM " .. ctf[1].name .. ": " .. msg1 .. ", TEAM " .. ctf[2].name .. ": " .. msg2))
		end
		
		-- check player health
		for k,v in pairs(teams) do
			local hp = teams[k][3]:get_hp();
			if not hp or hp<6 then -- teams[k][4]

				local cflag = teams[k][2];
				if cflag>0 then -- drop flag
					ctf[cflag].state = 1
					ctf[cflag].owner = ""
					minetest.set_node(ctf[cflag].pos, {name = ctf[cflag].flagnode})
					say(colorize("red", "#CTF " .. k .. " dropped " .. ctf[cflag].name .. " flag!"))
				end
				if not hp then -- player left
					say(colorize("yellow", "#CTF " .. k .. " left the game!"))
					teams[k] =  nil
				else -- reset player
					say(colorize("yellow", "#CTF " .. k .. " resetted!"))
					v[2] = 0 -- player has no flag
					v[3]:set_hp(20)
					v[3]:setpos( ctf[v[1]].pos )
				end
			
				
							
			end
		end
		
		
		event = keyboard.get()
		if event and teams[event.puncher] then
			--say(serialize(event))
			local punch_id = get_id({x=event.x,y=event.y,z=event.z});
			local flag = flag_id[punch_id];
			if flag then 
				local state = ctf[flag].state
				local puncher = event.puncher;
				if state == 1 then -- flag is here, ready to be taken or capture of enemy flag
					if teams[puncher][1] ~= flag then  -- take
						say(colorize("red","#CTF " .. puncher .. " has taken " .. ctf[flag].name .. " flag !"))
						ctf[flag].state = 2;
						ctf[flag].owner = puncher;
						teams[puncher][2] = flag;
						minetest.set_node(ctf[flag].pos, {name = "basic_robot:buttonFFFF80"})
					else -- capture?
						if teams[puncher][2] > 0 then
							local cflag = teams[puncher][2] -- puncher has this flag
							local data  = ctf[cflag];
							
							local team = teams[puncher][1];
							ctf[team].score = ctf[team].score + 1
							ctf[team].owner = ""
							ctf[cflag].state = 1; -- reset captured flag state
							minetest.set_node(ctf[cflag].pos, {name = ctf[cflag].flagnode})
							teams[puncher][2] = 0
							say(colorize("orange","#CTF " .. puncher .. " has captured " .. data.name .. " flag! Team " .. ctf[team].name .. " has score " .. ctf[team].score ))
							if ctf[team].score == maxscore then
								say(colorize("yellow","#CTF: TEAM " .. ctf[team].name .. " WINS! "))
								gamestate = 3;t=5; -- intermission, duration 5
								
								--reset
								teams = {}
								for i=1,#ctf do ctf[i].state = 1 ctf[i].score = 0 ctf[i].owner = "" end
							end
							
						end
					
					end
				
				
				end
			end
			--say(serialize(event)) 
		end
	elseif gamestate == 3 then -- intermission
		if t>0 then t=t-1 else gamestate = 0 end
	end