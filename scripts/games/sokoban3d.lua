-- sokoban 3D, rnd

if not init then
  spos = self.spawnpos(); spos.x = spos.x +5; spos.z = spos.z +5;
  
	for i = 1, 2 do
		for j = 1,2 do
			puzzle.set_node({x=spos.x+i,y=spos.y,z=spos.z+j}, {name = "basic_robot:buttonFFFFFF"})
		end
	end
  
  init = true
  players = find_player(5);
  if not players then say("no players nearby") self.remove() end
  
  puzzle.get_player(players[1]):set_physics_override({jump = 0.85}) -- just allow jump on 1 block up
  say("BOX PUSH demo. punch the white box to move it around ")

  self.label(
  "SOKOBAN 3D. RULES:\n1. pushable blocks: white,gray,yellow. you can not push block if another block is on top of it,\n2. elevator block: yellow - can push other blocks on top of it,"..
  "\n3. if block falls it breaks, unless it falls less than 1 deep onto green block\n"..
  "4. if you push block into blue it dissapears\n"..
  "5. you can only push block by standing close in front of it, not too low below it or too high above it\n"..
  "LEVEL 1: push white block on top of red block")
  
  pushables = {[1] = true,[2] = true,[6] = true} -- button types: white,gray, yellow
  canpushnodes = {-- you can push into these nodes, 1 push node, 2 absorb node, 3 = elevator
	["air"] = 1, 
	["basic_robot:button8080FF"] = 2,
	["basic_robot:buttonFFFF80"] = 3,
	} 
end

event = keyboard.get()
if event then
	local boxtype = event.type
	if pushables[boxtype] then
		player = puzzle.get_player(event.puncher)
		local pos = player:getpos();
		local boxpos = {x = event.x, y = event.y, z = event.z};
		local diff = { pos.x-boxpos.x, pos.z-boxpos.z, pos.y - boxpos.y}; -- x,z,y
			
		local newx,newy,newz
		newy = boxpos.y
		local allowpush = true
		
		--self.label(diff[3])
		if diff[3]<-1.5  or diff[3]>0.5 then allowpush = false end -- dont allow to push if height difference to large
		
		if math.abs(diff[1])>math.abs(diff[2]) then -- punch in x-direction
			newx = boxpos.x - (diff[1]>0 and 1 or -1)
			newz = boxpos.z
			if math.abs(diff[1])<0.7 or math.abs(diff[1])>1 then allowpush = false end -- dont allow push if too close
			if math.abs(diff[2]) > 0.25 then allowpush = false end -- must stand in front to push, not from side
		else
			newx = boxpos.x
			newz = boxpos.z - (diff[2]>0 and 1 or -1)
			if math.abs(diff[2])<0.7 or math.abs(diff[2])>1 then allowpush = false end -- dont allow push if too close
			if math.abs(diff[1]) > 0.25 then allowpush = false end -- must stand in front to push, not from side
		end
		
		--self.label(diff[1] .. " " .. diff[2] .. " " .. diff[3])
		
		local newnode = puzzle.get_node({x=newx, y= boxpos.y, z= newz}).name
		
		
		local canpush = canpushnodes[newnode]
		if allowpush and canpush then
			local oldnode = puzzle.get_node(boxpos).name
			
			if canpush == 1 then -- simply move the box
				newnode = oldnode
			elseif canpush == 2 then -- absorb the box
				newnode = newnode
			elseif canpush == 3 then
				newnode = oldnode
				newy = newy+1
			end
			
			
			
			local nodeabove = puzzle.get_node({x=boxpos.x, y=boxpos.y+1, z= boxpos.z}).name 
			if nodeabove ~="air" then allowpush = false end -- no floating nodes allowed
			
			local nodebelow = puzzle.get_node({x=newx, y=newy-1, z= newz}).name 
			if nodebelow == "air" then 
				if puzzle.get_node({x=newx, y=newy-2, z= newz}).name ~= "basic_robot:button80FF80" then
					newnode = "air" 
				else
					newy=newy-1
				end
			end -- fall down
			
			
			
			if allowpush then 
				puzzle.set_node(boxpos,{name= "air"}) -- remove node
				puzzle.set_node({x=newx, y= newy, z= newz}, {name = newnode}) 
			end
		end
	end
	--say(serialize(event))
end