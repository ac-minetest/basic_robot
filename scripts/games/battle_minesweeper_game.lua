if not data then
	m=10;n=10;
	players = {};
	paused = true
	
	turn = 2;
	t = 0;
	SIGNUP = 0; GAME = 1; INTERMISSION = 2
	state = SIGNUP
	
	t0 = _G.minetest.get_gametime();spawnpos = self.spawnpos() -- place mines
	data = {}; 
	
	init_game = function()
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
	
	greeting = function()
		_G.minetest.chat_send_all(colorize("red","#BATTLE MINESWEEPER : two player battle in minesweeper. say join to play.\nRules: 1. each player has 5 second turn to make a move 2. if you dont make move you lose\n3. if you make move in other player turn you lose. 4. if you hit bomb or mark bomb falsely you lose"))
	end
	
	player_lost = function ()
		for i=1,#players do
			local player = _G.minetest.get_player_by_name(players[i]);
			if player then player:setpos({x=spawnpos.x,y=spawnpos.y+10,z=spawnpos.z}) end
		end
		state = INTERMISSION; t = 0
	end
	
	function change_turn()
		if turn == 1 then 
			_G.minetest.sound_play("default_break_glass",{pos=spawnpos, max_hear_distance = 100})
		else
			_G.minetest.sound_play("note_a",{pos=spawnpos, max_hear_distance = 100})
		end
		
		if paused == false then 
			say(players[turn] .. " lost : didn't make a move");
			player_lost()
		else
			if turn == 1 then turn = 2 else turn = 1 end
			self.label("turn " .. turn .. " " .. players[turn])
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
			end	
				
		end
	end

elseif state == GAME then

	t = t + 1;
	if t>5 then -- change of turn
		change_turn()
	end

	event = keyboard.get();
	if event and event.type == 2 and not paused then
		if event.puncher == players[turn] then
			local x = event.x - spawnpos.x;local y = event.y - spawnpos.y;local z = event.z - spawnpos.z;
			if x<1 or x>m or z<1 or z>n then
			else
				local ppos = player.getpos(event.puncher)
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
	t=t+1; if t> 15 then state = SIGNUP;players = {}; paused = true; init_game(); greeting() end
end