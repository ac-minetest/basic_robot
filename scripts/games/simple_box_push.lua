-- simple box pushing game, rnd

if not init then
  spos = self.spawnpos(); spos.x = spos.x +5; spos.z = spos.z +5;
  
	for i = 1, 2 do -- set up 4 boxes
		for j = 1,2 do
			puzzle.set_node({x=spos.x+i,y=spos.y,z=spos.z+j}, {name = "basic_robot:buttonwhite"})
		end
	end
  
  init = true
  players = find_player(5);
  if not players then say("no players nearby") self.remove() end
  self.label("BOX PUSH demo. punch the white box to move it around.\npush it into blue block to make it disappear.")
  
  pushables = {[1] = true} -- button types
  canpushnodes = {["air"] = 1, ["basic_robot:buttonblue"] = 2} -- 1 push node, 2 absorb node
  
  self.listen_punch(self.pos()) -- robot will now read punch button events in 32x32 box area
end

event = keyboard.get()

if event then -- there was punch event
	local boxtype = event.type
	if pushables[boxtype] then
		player = puzzle.get_player(event.puncher)
		local pos = player:getpos();
		local boxpos = {x = event.x, y = event.y, z = event.z};
		local diff = { pos.x-boxpos.x, pos.z-boxpos.z};
			
		local newx,newz
		if math.abs(diff[1])>math.abs(diff[2]) then -- punch in x-direction
			newx = boxpos.x - (diff[1]>0 and 1 or -1)
			newz = boxpos.z
		else
			newx = boxpos.x
			newz = boxpos.z - (diff[2]>0 and 1 or -1)
		end
		
		local newnode = puzzle.get_node({x=newx, y= boxpos.y, z= newz}).name
		
		
		local canpush = canpushnodes[newnode]
		if canpush then
			local oldnode = puzzle.get_node(boxpos).name
			puzzle.set_node(boxpos,{name= "air"}) -- remove node
			if canpush == 1 then -- simply move the box
				newnode = oldnode
			elseif canpush == 2 then -- absorb the box
				newnode = newnode
			end
			
			puzzle.set_node({x=newx, y= boxpos.y, z= newz}, {name = newnode})
		end
	end
	--say(serialize(event))
end