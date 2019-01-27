if not data then
	m=10;n=10;
	players = {};
	paused = true
	
	turn = 2;
	turntimeout = 5
	shorttimeout = 1
	shortround = false
	turnmessage = ""
	t = 0;
	SIGNUP = 0; GAME = 1; INTERMISSION = 2
	state = SIGNUP
	
	t0 = _G.minetest.get_gametime();spawnpos = self.spawnpos() -- place mines
	data = {}; 
	
	init_game = function()
		abilitypoints = {0,0}; -- points to use ability, step outside ring to use them in following round
		shortround = false
		data = {}; minescount = 32
		for i = 1, minescount do local i = math.random(m); local j = math.random(n); if not data[i] then data[i] = {} end; data[i][j] = 1; end
		if not data[1] then data[1] = {} end if not data[2] then data[2] = {} end -- create 2x2 safe area
		data[1][1] = 0;data[1][2] = 0;data[2][1] = 0;data[2][2] = 0;
		
		minescount = 0; 
		for i = 1,m do for j = 1,n do  -- render game
			if data[i] and data[i][j] == 1 then minescount = minescount + 1 end
			if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j})~="basic_robot:button808080" then
				keyboard.set({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j},2)
			end
		end	end
		keyboard.set({x=spawnpos.x+1,y=spawnpos.y,z=spawnpos.z+1},4) -- safe start spot
	end
	
	get_mine_count = function(i,j)
		if i<0 or i>m+1 or j<0 or j>n+1 then return 0 end; count = 0
		for k = -1,1 do	for l = -1,1 do
				if data[i+k] and data[i+k][j+l] == 1 then count = count +1 end
		end	end
		return count
	end
	chk_mines = function()
		local count = minescount;
		for i=1,m do for j=1,n do 
		if keyboard.read({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j})=="basic_robot:buttonFF8080" and data[i] and data[i][j]==1 then
			count=count-1
		end
		end end
		return count
	end
	
	near_chat = function(msg)
	
	end
	
	greeting = function()
		_G.minetest.chat_send_all(colorize("red",
		"#BATTLE MINESWEEPER : two player battle in minesweeper. say join to play.\nRules: "..
		"1. each player has 5 second turn to make a move 2. if you dont make move you lose\n"..
		"3. if you make move in other player turn you lose. 4. if you hit bomb or mark bomb falsely you lose\n"..
		"5. by playing fast you get ability charge. when you collect 10 you can step out of ring when your round ends and opponent will only have 2s to play his turn."
		))
	end
	
	player_lost = function ()
		for i=1,#players do
			local player = _G.minetest.get_player_by_name(players[i]);
			if player then player:setpos({x=spawnpos.x,y=spawnpos.y+10,z=spawnpos.z}) end
		end
		_G.minetest.sound_play("electric_zap",{pos=spawnpos, max_hear_distance = 100})
		state = INTERMISSION; t = 0
	end
	
	function change_turn()
		shortround = false -- reset ability if activated
		if turn == 1 then 
			_G.minetest.sound_play("default_break_glass",{pos=spawnpos, max_hear_distance = 100})
		else
			_G.minetest.sound_play("default_cool_lava",{pos=spawnpos, max_hear_distance = 100})
		end
		
		if paused == false then 
			say(players[turn] .. " lost : didn't make a move fast enough ");
			player_lost()
		else
			local player =  minetest.get_player_by_name(players[turn])
			local ppos = player:getpos()
			local x = ppos.x - spawnpos.x;local y = ppos.y - spawnpos.y;local z = ppos.z - spawnpos.z;
			local points = abilitypoints[turn]
			if x<1 or x>m or z<1 or z>n then -- outside area
				local points = abilitypoints[turn]
				if points>=10 then -- do we have enough points?
					shortround = true -- next round will be shorter, 2s
					_G.minetest.sound_play("grinder",{pos=spawnpos, max_hear_distance = 100})
					abilitypoints[turn] = abilitypoints[turn]-10
				end
			end
			
			if turn == 1 then turn = 2 else turn = 1 end
			turnmessage = "turn " .. turn .. " " .. players[turn] .. ",charge " .. abilitypoints[turn] .. "\n"
			self.label(turnmessage)
			t=0
			paused = false
		end
	end
	
	init_game()
	greeting()
	self.listen(1)
end

if state == SIGNUP then
	speaker,msg = self.listen_msg()
	if speaker then
		if msg == "join" then
			players[#players+1] = speaker;
			local plist = ""; for i=1,#players do plist = plist .. players[i] .. ", " end
			_G.minetest.chat_send_all("BATTLE MINESWEEPER, current players : " .. plist)
			
			if #players >= 2 then 
				state = GAME
				change_turn();
				keyboard.get(); t=0; 
				for i = 1, #players do
					local player = _G.minetest.get_player_by_name(players[i]);
					if player then player:setpos({x=spawnpos.x,y=spawnpos.y+1,z=spawnpos.z}) end
				end
				_G.minetest.chat_send_all(colorize("red","BATTLE MINESWEEPER " .. m .. "x" ..n .. " with " .. minescount .. " mines.\n" .. players[turn] .. " its your move!"))
				init_game()
			end	
				
		end
	end

elseif state == GAME then

	t = t + 1;
	if (t>turntimeout) or (shortround and t>shorttimeout) then -- change of turn
		change_turn()
	else
		self.label(turnmessage .. " " .. (turntimeout-t+1))
	end

	event = keyboard.get();
	if event and event.type == 2 and not paused then
		if event.puncher == players[turn] then
			local x = event.x - spawnpos.x;local y = event.y - spawnpos.y;local z = event.z - spawnpos.z;
			local points = abilitypoints[turn]
			if x<1 or x>m or z<1 or z>n then -- outside area
			else
				local ppos = player.getpos(event.puncher)
				
				 points =  points + math.max(turntimeout-t-2,0); if points>40 then points = 40 end
				 abilitypoints[turn] = points
				
				if ppos and math.abs(ppos.x-event.x)<0.5 and math.abs(ppos.z-event.z)<0.5 then -- just mark mine
					if data[x] and data[x][z] == 1 then 
						if keyboard.read({x=event.x,y=event.y,z=event.z})~="basic_robot:button808080" then
							keyboard.set({x=event.x,y=event.y,z=event.z},2) 
						else
							keyboard.set({x=event.x,y=event.y,z=event.z},3)
						end
					else
						say(event.puncher .. " lost : marked a bomb where it was none! ");
						player_lost()
					end
				else
					if data[x] and data[x][z]==1 then
							_G.minetest.sound_play("tnt_boom",{pos=spawnpos, max_hear_distance = 100})
							keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},3)
							say(event.puncher .. " lost : punched a bomb! ");
							player_lost()
					else
						local count = get_mine_count(x,z);
						if count == 0 then keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},4)
						else keyboard.set({x=spawnpos.x+x,y=spawnpos.y,z=spawnpos.z+z},7+count) end
					end
				end
			end
			paused = true
		else
			say(event.puncher .. " lost : played out of his/her turn"); player_lost()
		end
	end

elseif state == INTERMISSION then
	t=t+1; if t> 15 then state = SIGNUP;players = {}; paused = true; greeting() end
end