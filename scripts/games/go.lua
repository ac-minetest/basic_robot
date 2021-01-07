--go by rnd
if not init then init=true
	spos = self.spawnpos()
	sizex = 9; sizez = 9
	
	gamepieces = {
		{ -- player black
			"basic_robot:buttonFF8080"
		},
		{ -- player white - blue
			"basic_robot:button8080FF"
		}
	}
	show_mark = function(pos)
		minetest.add_particle(
		{
			pos = pos,
			expirationtime = 10,
			velocity = {x=0, y=0,z=0},
			size = 5,
			texture = "default_apple.png",
			acceleration = {x=0,y=0,z=0},
			collisiondetection = true,
			collision_removal = true,			
		}
		)
	end
		
	build_game = function()
		for i = 1,sizex do
			minetest.swap_node({x=spos.x+i,y=spos.y,z=spos.z+sizez+1},{name = "basic_robot:button_"..(64+i), param2=2})
			minetest.swap_node({x=spos.x+i,y=spos.y,z=spos.z},{name = "basic_robot:button_"..(64+i)})
			for j = 1,sizez do
				minetest.swap_node({x=spos.x+i,y=spos.y,z=spos.z+j},{name = "basic_robot:button808080"})
				minetest.swap_node({x=spos.x+i,y=spos.y+1,z=spos.z+j},{name = "air"})
			end
		end
		for j = 1,sizez do
			minetest.swap_node({x=spos.x,y=spos.y,z=spos.z+j},{name = "basic_robot:button_".. (48+j), param2=3})
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
	punchnode = nil; -- name of piece to place
	step = 0;
	turn = 0;
	self.label("go\n\n" ..
	"RULES:\n\n"..
	"1. liberty of block is free position next to block (not diagonally). block\n"..
	"is alive if it has liberties left. group of connected (not diagonally) blocks\n"..
	"is alive if at least one block in group is alive.\n"..
	"2. dead blocks are immediately removed from game.\n"..
	"3.to get score count how much territory your blocks occupy, including blocks\n"..
	"themselves. If not clear which blocks are dead, continue game until it is clear\n\n"..
	"punch board to place your red/blue piece. blue starts first.")
end

event = keyboard.get()


if event then
	--self.label(serialize(event))
	local x = event.x-spos.x; local z = event.z-spos.z;
	if event.y~= spos.y then return end
	if x<1 or x>sizex or z<1 or z>sizez then return end
	
	turn = 1- turn
	step = step+1
	local x2 = event.x-spos.x; local z2 = event.z-spos.z
	if turn == 0 then
		add_msg(minetest.colorize("red",step) .. ": " .. event.puncher .. " " .. string.char(64+x2) .. z2); 
	else
		add_msg(minetest.colorize("blue",step) .. ": " .. event.puncher .. " " .. string.char(64+x2) .. z2); 
	end	
		
	show_msgs()

	minetest.swap_node({x=event.x,y=event.y+1,z=event.z},{name = gamepieces[turn+1][1]})
	punchnode = nil
	show_mark({x=event.x,y=event.y+2,z=event.z})
end