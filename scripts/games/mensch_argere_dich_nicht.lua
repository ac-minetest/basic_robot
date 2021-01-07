-- 'Mensch argere Dich nicht'. modified by rnd
if not init then	
	msg = 
	"Sorry!/Mensch argere Dich nicht, modified by rnd\n\n" ..
	"1. goal of game is put all 4 of your pieces in your home area by moving clockwise around on white path\n"..
	"2. start of game is player trying to move his piece out to start spot next to home by trying 3x to get 6 from dice.\n"..
	"3. after that player uses dice at start of turn. he moves his playing pieces ( those\n"..
	"on board) so many positions as dice said. negative number means moving back.\n"..
	"4. if player can move his piece he must. if his piece goes backward all the way to start\n"..
	"he must put it back out.If piece lands on opponent piece then opponent piece is put out to initial start.\n"..
	"5. if dice shows 6 he can move 6 or put another piece out if possible. player can move\n"..
	"pieces within home area if possible.\n"..
	"6. if dice shows 0 you play as one of your opponents for a turn."
	self.label(msg)
	
	init = true;
	state = 1; --  game on
	step = 0;
	punchstate = 1; -- first punch
	punchpos = {} 
	pos = self.spawnpos()
	dice =  0
	spawns  = {
		{2,2,1,2,2,"basic_robot:buttonFF8080"}, -- xstart,zstart,ystart, dimx, dimz, nodename
		{2,11,1,2,2,"basic_robot:button8080FF"},
		{11,11,1,2,2,"basic_robot:button80FF80"},
		{11,2,1,2,2,"basic_robot:buttonFFFF80"}, --4 bases
	
		{7,3,0,1,4,"basic_robot:buttonFF8080"}, -- red final
		{3,7,0,4,1,"basic_robot:button8080FF"}, -- blue final
		{7,8,0,1,4,"basic_robot:button80FF80"}, -- green final
		{8,7,0,4,1,"basic_robot:buttonFFFF80"}, -- yellow final
		
		{1,1,0,5,5,"basic_robot:button808080"},{6,1,0,3,1,"basic_robot:button808080"},
		{9,1,0,5,5,"basic_robot:button808080"},{13,6,0,1,3,"basic_robot:button808080"},
		{1,9,0,5,5,"basic_robot:button808080"},{1,6,0,1,3,"basic_robot:button808080"},
		{9,9,0,5,5,"basic_robot:button808080"},{6,13,0,3,1,"basic_robot:button808080"},	
		
		{2,2,0,2,2,"basic_robot:buttonFFFFFF"},
		{2,11,0,2,2,"basic_robot:buttonFFFFFF"},
		{11,11,0,2,2,"basic_robot:buttonFFFFFF"},
		{11,2,0,2,2,"basic_robot:buttonFFFFFF"},
	}
	
	-- build board
	for i = 1,12 do	for j = 1,12 do
		minetest.swap_node({x=pos.x+i,y=pos.y,z=pos.z+j},{name = "basic_robot:buttonFFFFFF"})
		minetest.swap_node({x=pos.x+i,y=pos.y+1,z=pos.z+j},{name = "air"})
	end end
	
	for k = 1,#spawns do
		for i = 0,spawns[k][4]-1 do for j = 0,spawns[k][5]-1 do
			minetest.swap_node({x=pos.x+i+spawns[k][1],y=pos.y+spawns[k][3],z=pos.z+j+spawns[k][2]},{name = spawns[k][6]})
		end end
	end
	
	keyboard.set({x=pos.x+7,y=pos.y+1,z=pos.z+7},7)
	
	msgs = {1} --{idx, msg1, msg2,msg3, msg4, msg5}; -- up to 5 ingame messages displayed
	add_msg = function(text)
		local idx = msgs[1] or 1; 
		msgs[idx+1] = text;idx = idx+1; if idx>5 then idx = 1 end msgs[1] = idx
	end
	show_msgs =  function() -- last message on top
		local out = {}; local idx = msgs[1] or 1;
		for i = idx,2,-1 do out[#out+1] = msgs[i] or "" end 
		for i = 6, idx+1,-1 do out[#out+1] = msgs[i] or "" end 
		self.label(table.concat(out,"\n")) 
	end
	
end

if state == 0 then
elseif state == 1 then
	event = keyboard.get();
	if event then
		x = event.x-pos.x; y = event.y-pos.y; z = event.z-pos.z
		--say("type " .. event.type .. " pos " .. x .. " " .. y .. " " .. z) 
		if x == 7 and y == 1 and z == 7 then
			_G.math.randomseed(os.time())
			dice = -3+math.random(9);
			keyboard.set({x=pos.x+7,y=pos.y+1,z=pos.z+7},7+math.abs(dice))
			if dice<0 then
				keyboard.set({x=pos.x+7,y=pos.y+2,z=pos.z+7},7+11)
			else
				keyboard.set({x=pos.x+7,y=pos.y+2,z=pos.z+7},0)
			end
			step = step + 1;
			msg = minetest.colorize("red","STEP ".. step) .. ": " ..event.puncher .. " threw dice = " .. dice;
			add_msg(msg); show_msgs()
			
			
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
					msg = event.puncher .. " moved.";
					add_msg(msg); show_msgs()
				end
			end
		
		
		end
	end


end