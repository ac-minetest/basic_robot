	-- SOKOBAN GAME, by rnd, robots port
	if not sokoban then
		sokoban = {};
		local players = find_player(5);
		if not players then error("sokoban: no player near") end
		name = players[1];
		
		self.show_form(name,
		"size[2,1.25]"..
		"label[0,0;SELECT LEVEL 1-90]"..
		"field[0.25,1;1,1;LVL;LEVEL;1]"..
		"button_exit[1.25,0.75;1,1;OK;OK]"
		)
		state = 1 -- will wait for form receive otherwise game play

		player_ = puzzle.get_player(name); -- get player entity - player must be present in area
		player_:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0});player_:set_physics_override({jump=1})	-- reset player
		
		
		self.spam(1)
		sokoban.push_time = 0
		sokoban.blocks = 0;sokoban.level = 0; sokoban.moves=0;
		imax = 0; jmax = 0
		
		sokoban.load=0;sokoban.playername =""; sokoban.pos = {};
		SOKOBAN_WALL = "default:brick"
		SOKOBAN_FLOOR = "default:stonebrick"
		SOKOBAN_GOAL = "default:diamondblock"
		SOKOBAN_BOX = "basic_robot:button8080FF"
		
		load_level = function(lvl)
			
			local pos = self.spawnpos(); pos.x=pos.x+1;pos.y=pos.y+1;
			sokoban.pos = pos;
			sokoban.playername = name
			
			if lvl == nil then return end
			if lvl <0 or lvl >89 then return end
			
			local file = _G.io.open(minetest.get_modpath("basic_robot").."\\scripts\\sokoban.txt","r")
			if not file then return end
			local str = ""; local s; local p = {x=pos.x,y=pos.y,z=pos.z}; local i,j;i=0;
			local lvl_found = false
			while str~= nil do
				str = file:read("*line"); 
				if str~=nil and str =="; "..lvl then lvl_found=true break end
			end
			if not lvl_found then file:close();return end
			
			sokoban.blocks = 0;sokoban.level = lvl+1; sokoban.moves=0;
			imax=0; jmax = 0;
			while str~= nil do
				str = file:read("*line"); 
				if str~=nil then 
					if string.sub(str,1,1)==";" then
						imax=i;
						file:close(); 
						player_:set_physics_override({jump=0})
						player_:set_eye_offset({x=0,y=20,z=0},{x=0,y=0,z=0})
						say("games: sokoban level "..sokoban.level .." loaded by ".. name .. ". It has " .. sokoban.blocks  .. " boxes to push. "); return 
					end
					i=i+1;
					if string.len(str)>jmax then jmax = string.len(str) end -- determine max dimensions
					for j = 1,string.len(str) do
						p.x=pos.x+i;p.y=pos.y; p.z=pos.z+j; s=string.sub(str,j,j);
						p.y=p.y-1; 
						if puzzle.get_node(p).name~=SOKOBAN_FLOOR then puzzle.set_node(p,{name=SOKOBAN_FLOOR}); end -- clear floor
						p.y=p.y+1;
						if s==" " and puzzle.get_node(p).name~="air" then puzzle.set_node(p,{name="air"}) end
						if s=="#" and puzzle.get_node(p).name~=SOKOBAN_WALL then puzzle.set_node(p,{name=SOKOBAN_WALL}) end
						if s=="$" then puzzle.set_node(p,{name=SOKOBAN_BOX});sokoban.blocks=sokoban.blocks+1 end
						if s=="." then p.y=p.y-1;puzzle.set_node(p,{name=SOKOBAN_GOAL}); p.y=p.y+1;puzzle.set_node(p,{name="air"}) end
						--starting position
						if s=="@" then 
							player_:setpos({x=p.x,y=p.y+1,z=p.z}); -- move player to start position
							--p.y=p.y-1;puzzle.set_node(p,{name="default:glass"}); 
							puzzle.set_node(p,{name="air"}) 
							p.y=p.y+1;puzzle.set_node(p,{name="air"}) 
							--p.y=p.y+2;puzzle.set_node(p,{name="default:ladder"}) 
						end
						if s~="@" then p.y = pos.y+2;puzzle.set_node(p,{name="air"}); -- ceiling default:obsidian_glass
							else --p.y=pos.y+2;puzzle.set_node(p,{name="default:ladder"})
						end -- roof above to block jumps
						
					end
				end
			end
			
			file:close();		
		end
		
	
	end

	
if state == 1 then
	sender,fields = self.read_form(); -- get fields from form submittal
	if sender then
		--say(serialize(fields))
		
		if fields.LVL then
			load_level((tonumber(fields.LVL) or 1)-1)
			state = 0
			self.label("stand close to blue box and punch it one time to push it. you can only push 1 box\nand cant pull. goal is to get all boxes pushed on diamond blocks")
		end
	end
else
	
	local ppos = player_:getpos()
	if math.abs(ppos.y-sokoban.pos.y)~= 0.5 then say(colorize("red", "SOKOBAN: " .. name ..  " CHEATS ! ")); self.remove() end
	
	event = keyboard.get();

	if event then
	
			local pname = event.puncher
			if pname ~= name then goto quit end
			local pos = {x=event.x, y = event.y, z = event.z};
			local p=player.getpos(pname);local q={x=pos.x,y=pos.y,z=pos.z}
			p.x=p.x-q.x;p.y=p.y-q.y;p.z=p.z-q.z
			if math.abs(p.y+0.5)>0 then goto quit end
			if math.abs(p.x)>math.abs(p.z) then -- determine push direction
				if p.z<-0.5 or p.z>0.5 or math.abs(p.x)>1.5 then goto quit end
				if p.x+q.x>q.x then q.x= q.x-1 
					else q.x = q.x+1
				end
			else
				if p.x<-0.5 or p.x>0.5 or math.abs(p.z)>1.5 then goto quit end
				if p.z+q.z>q.z then q.z= q.z-1 
					else q.z = q.z+1
				end
			end
			
			
			if minetest.get_node(q).name=="air" then -- push crate
				sokoban.moves = sokoban.moves+1
				local old_infotext = minetest.get_meta(pos):get_string("infotext");
				minetest.set_node(pos,{name="air"})
				minetest.set_node(q,{name=SOKOBAN_BOX})
				minetest.sound_play("default_dig_dig_immediate", {pos=q,gain=1.0,max_hear_distance = 24,}) -- sound of pushing
				local meta = minetest.get_meta(q);
				q.y=q.y-1; 
				if minetest.get_node(q).name==SOKOBAN_GOAL then  
					if old_infotext~="GOAL REACHED" then
						sokoban.blocks = sokoban.blocks -1;
					end
					meta:set_string("infotext", "GOAL REACHED") 
				else 
					if old_infotext=="GOAL REACHED" then
						sokoban.blocks = sokoban.blocks +1
					end
					--meta:set_string("infotext", "push crate on top of goal block") 
				end
			end

			if sokoban.blocks~=0 then -- how many blocks left
				--say("move " .. sokoban.moves .. " : " ..sokoban.blocks .. " crates left ");
				else 
					say("games: ".. name .. " just solved sokoban level ".. sokoban.level .. " in " .. sokoban.moves .. " moves.");
					player_:set_physics_override({jump=1})
					player_:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
					
					local i,j;
					for i = 1,imax do
						for j=1,jmax do
							minetest.set_node({x= sokoban.pos.x+i,y=sokoban.pos.y,z=sokoban.pos.z+j}, {name = "air"}); -- clear level
						end
					end
					
					sokoban.playername = ""; sokoban.level = 1
			end
			::quit::
	end
end