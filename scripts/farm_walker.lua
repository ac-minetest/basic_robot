if not init then 
	init = true
	angle = 90
	walk = {["default:dirt"] = 1}
	stop = {["wool:white"] = 1}
end

node = read_node.forward_down()
if walk[node] then 
	move.forward() 
elseif stop[node] then
	self.reset(); angle = 90
else
	turn.angle(angle);move.forward(); turn.angle(angle); angle = - angle
end