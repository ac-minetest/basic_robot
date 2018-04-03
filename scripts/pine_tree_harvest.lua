-- PINE TREE HARVEST by rnd1
if not harvest then
	harvest = {};
	harvest.s = -1 -- -1 idle, 0 expect tree
	harvest.tree = "default:pine_tree";harvest.wood = "default:wood";harvest.sapling = "default:pine_sapling";
	harvest.step = function()
		local s=harvest.s;
		if s == 0 then -- did we bump into tree
			local node = read_node.forward();
			if node == harvest.tree then 
				dig.forward(); move.forward(); harvest.s = 1 -- found tree, moving in
				self.label("im digging up tree ")
			end
		elseif s == 1 then -- climbing up
			dig.up(); move.up(); place.down(harvest.wood);
			local node = read_node.up();
			if node ~= harvest.tree then
				harvest.s = 2 -- top
				self.label("i reached top of tree")
			end
		elseif s == 2 then -- going down
			local node = read_node.down();
			if node == harvest.wood then 
				dig.down(); move.down()
				self.label("im going back down")
			else
				pickup(8);
				move.backward();place.forward(harvest.sapling);move.forward();
				harvest.s = -1 -- idle
				self.label("i finished cutting tree")
			end
		end
	end
end

--harvest walk init
if not angle then
	sender,mail = self.read_mail();	if sender == "rnd1" then harvest.s = tonumber(mail) or 0 end
	wall = "default:cobble";
	angle = 90
end

if harvest.s~=-1 then
	harvest.step()
elseif harvest.s==-1 then
	node = read_node.forward();
	if node==harvest.tree then
		harvest.s = 0;
		self.label("i found tree")
	else
		self.label("im walking")
		if not move.forward() then
			if node == wall then 
				self.label("i hit wall")
				turn.angle(angle);
				if move.forward() then
					move.forward();move.forward();turn.angle(angle); angle = -angle
				else
					turn.angle(-angle);angle = - angle
				end
			end
		end
	end
end
self.send_mail("rnd1",harvest.s) -- remember state in case of reactivation