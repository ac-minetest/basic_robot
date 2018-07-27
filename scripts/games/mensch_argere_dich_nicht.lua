
if not init then
	
	msg = 
	"'Mensch argere Dich nicht' is a German board game (but not a German-style board game), developed by Josef Friedrich Schmidt in 1907/1908.\n"..
    " The players throw a die in turn and can advance any of their pieces in the game by the thrown number of dots on the dice.\n" ..
    "Throwing a six means bringing a piece into the game (by placing one from the 'out' area onto the 'start' field) and throwing the dice again. If\n" .. 
	"a piece is on the 'start' field and there are still pieces in the 'out' area, it must be moved as soon as possible. If a piece cannot be\n".. "brought into the game then any other piece in the game must be moved by the thrown number, if that is possible. Pay attention that throwing\n".." dice continuously without moving is forbidden and by each dice throw you have to make a move.\n" ..
    "Pieces can jump over other pieces, and throw out pieces from other players (into that player's 'out' area) if they land on them. A player\n".. "cannot throw out his own pieces though, he can advance further than the last field in the 'home' row. A player can be thrown out if he is on\n"..
	"his 'start' field.\n" ..
    "Variation which is played by most players: A player who has no pieces in the game has 3 tries to throw a six"
	self.label(msg)
	
	init = true;
	state = 1; --  game on
	step = 0;
	punchstate = 1; -- first punch
	punchpos = {} 
	pos = self.spawnpos()
	dice =  0
	spawns  = {{2,2,"basic_robot:buttonFF8080"},{2,11,"basic_robot:button8080FF"},{11,11,"basic_robot:button80FF80"},{11,2,"basic_robot:buttonFFFF80"}}
	
	for i = 1,12 do	for j = 1,12 do
		minetest.swap_node({x=pos.x+i,y=pos.y+1,z=pos.z+j},{name = "air"})
	end end
	
	for k = 1,#spawns do
		for i = 0,1 do for j = 0,1 do
			minetest.swap_node({x=pos.x+i+spawns[k][1],y=pos.y+1,z=pos.z+j+spawns[k][2]},{name = spawns[k][3]})
		end end
	end
	
	keyboard.set({x=pos.x+7,y=pos.y+1,z=pos.z+7},7)
	
end

if state == 0 then
elseif state == 1 then
	event = keyboard.get();
	if event then
		x = event.x-pos.x; y = event.y-pos.y; z = event.z-pos.z
		--say("type " .. event.type .. " pos " .. x .. " " .. y .. " " .. z) 
		if x == 7 and y == 1 and z == 7 then
			_G.math.randomseed(os.time())
			dice = math.random(6);
			keyboard.set({x=pos.x+7,y=pos.y+1,z=pos.z+7},7+dice)
			step = step + 1;
			msg = colorize("red","<Mensch argere dich nicht>") .. " STEP " .. step .. ": " ..event.puncher .. " threw dice = " .. dice;
			minetest.chat_send_all(msg)
			self.label(msg)
			punchstate = 1
		elseif punchstate == 1 then
			if y == 1 and event.type ~= 2 and event.type<7 then
				punchpos = 2; minetest.chat_send_player(event.puncher,colorize("red","<Mensch argere dich nicht>") .. " punch place on board where to move ")
				punchpos = {x=event.x,y=event.y,z=event.z}
				punchstate = 2
			end
		elseif punchstate == 2 then
			if y == 0 and event.type ~= 2 then
				if x<2 or x>12 or z<2 or z>12 then
					else
					local nodename = minetest.get_node(punchpos).name;
					minetest.swap_node({x=event.x, y = event.y+1, z=event.z},{name = nodename})
					minetest.swap_node(punchpos,{name = "air"})
					punchstate = 1; dice = 0
					minetest.add_particle(
					{
						pos = punchpos,
						expirationtime = 15,
						velocity = {x=0, y=0,z=0},
						size = 18,
						texture = "default_apple.png",
						acceleration = {x=0,y=0,z=0},
						collisiondetection = true,
						collision_removal = true,			
					}
					)
					msg = colorize("red","<Mensch argere dich nicht>") .. " " .. event.puncher .. " moved.";
					minetest.chat_send_all(msg)
					self.label(msg)
				end
			end
		
		
		end
	end


end