--checkers by rnd, 1.5 hr
if not init then init=true
	spos = self.spawnpos()
	sizex = 8; sizez= 8
	
	gamepieces = {
		{ -- player1: regular piece, queen
			"basic_robot:buttonFFFF80","basic_robot:buttonFF8080"
		},
		{ -- player2
			"basic_robot:button80FF80","basic_robot:button8080FF"
		}
	}
	show_mark = function(pos)
		minetest.add_particle(
		{
			pos = pos,
			expirationtime = 5,
			velocity = {x=0, y=0,z=0},
			size = 18,
			texture = "default_apple.png",
			acceleration = {x=0,y=0,z=0},
			collisiondetection = true,
			collision_removal = true,			
		}
		)
	end
		
	build_game = function()
		for i = 1,sizez do
			for j = 1,2 do
				minetest.swap_node({x=spos.x+j,y=spos.y,z=spos.z+i},{name = "basic_robot:button_131"})
				minetest.swap_node({x=spos.x+j,y=spos.y+1,z=spos.z+i},{name = "air"})
			end
			minetest.swap_node({x=spos.x+3,y=spos.y,z=spos.z+i},{name = "basic_robot:button_".. (48+i), param2 = 3})
		end
		for i = 1,sizex do
			minetest.swap_node({x=spos.x+3+i,y=spos.y,z=spos.z},{name = "basic_robot:button_".. (64+i)})
			minetest.swap_node({x=spos.x+3+i,y=spos.y,z=spos.z+sizez+1},{name = "basic_robot:button_".. (64+i), param2 = 2})
		end
		local white = true;
		for i = 1,sizex do
			for j = 1,sizez do
				if white then
					minetest.swap_node({x=spos.x+3+i,y=spos.y,z=spos.z+j},{name = "basic_robot:button_0"})
				else
					minetest.swap_node({x=spos.x+3+i,y=spos.y,z=spos.z+j},{name = "basic_robot:button808080"})
				end
				white = not white
				minetest.swap_node({x=spos.x+3+i,y=spos.y+1,z=spos.z+j},{name = "air"})
			end
			white = not white
		end
		minetest.swap_node({x=spos.x+1,y=spos.y+1,z=spos.z+1},{name = gamepieces[1][1]})
		minetest.swap_node({x=spos.x+1,y=spos.y+2,z=spos.z+1},{name = gamepieces[1][2]})
		
		minetest.swap_node({x=spos.x+1,y=spos.y+1,z=spos.z+sizez},{name = gamepieces[2][1]})
		minetest.swap_node({x=spos.x+1,y=spos.y+2,z=spos.z+sizez},{name = gamepieces[2][2]})
		
		for i=1,sizex,2 do
			minetest.swap_node({x=spos.x+4+i,y=spos.y+1,z=spos.z+1},{name = gamepieces[1][1]})
			minetest.swap_node({x=spos.x+3+i,y=spos.y+1,z=spos.z+2},{name = gamepieces[1][1]})
			
			minetest.swap_node({x=spos.x+4+i,y=spos.y+1,z=spos.z+sizez-1},{name = gamepieces[2][1]})
			minetest.swap_node({x=spos.x+3+i,y=spos.y+1,z=spos.z+sizez},{name = gamepieces[2][1]})
		end
	end
	
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
	
	build_game()
	punchpos = nil; -- pos of last punched piece
	step = 0;
	self.label("checkers\npunch piece then punch board to move")
end

event = keyboard.get()


if event then
	--self.label(serialize(event))
	if event.y==spos.y+1 then -- piece was punched to be moved
		punchpos = {x=event.x,y=event.y,z=event.z}
	elseif event.y==spos.y and event.x~=spos.x+3 then -- board was punched
		if not punchpos then return end
		
		step = step+1
		local x1 = punchpos.x-spos.x-3; local z1 = punchpos.z-spos.z
		local x2 = event.x-spos.x-3; local z2 = event.z-spos.z
		add_msg(minetest.colorize("red","MOVE " .. step) .. ": " .. event.puncher .. " " .. string.char(64+x1) .. z1 .. " to " .. string.char(64+x2) .. z2); show_msgs()
		
		local nodename = minetest.get_node(punchpos).name
		minetest.swap_node(punchpos,{name = "air"})
		show_mark(punchpos)
		
		-- promotion of pieces to queen when reaching the opposite side
		if nodename == gamepieces[1][1] and event.z==spos.z+sizez and event.x>spos.x+3 then 
			nodename = gamepieces[1][2]
		elseif nodename == gamepieces[2][1] and event.z==spos.z+1 and event.x>spos.x+3 then 
			nodename = gamepieces[2][2]
		end
		
		minetest.swap_node({x=event.x,y=event.y+1,z=event.z},{name = nodename})
		show_mark({x=event.x,y=event.y+2,z=event.z})
		punchpos = nil
	end
end