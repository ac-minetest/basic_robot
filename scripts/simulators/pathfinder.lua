-- pathfinder robot

if not init then
	max_jump = 1
	max_drop = 1
	searchdistance = 10
	move.forward(); move.down()
	pos1 = self.pos()
	pos2 = {x = -70 , y = -1, z = -123 }
	path = minetest.find_path(pos1,pos2,searchdistance,max_jump,max_drop,"Dijkstra")
	if not path then say("i dont know how to get there :(") self.remove() end

	say("im going to " .. pos2.x .. " " .. pos2.y .. " " .. pos2.z .. ", will be there in " .. #path .. " seconds")
	--	self.label(serialize(path))
	step = 0
	obj = _G.basic_robot.data[self.name()].obj
	init = true
end

if step<#path then
step = step + 1
pos = path[step]
obj:setpos(pos)
if  step == #path then say("arrived at destination.") end
end