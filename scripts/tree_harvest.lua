-- rnd, 2017
if not tree then 
	tree = {};
	wood = "default:tree";
	support  = "default:tree";
	leaves = "default:leaves";
	sapling = "default:sapling";
	
	tree.s = 0 -- searching
	tree.st = 0
end

tree_step = function()

	if tree.s == 0 then -- search
		node = read_node.forward()
		if node == wood then tree.s = 1 end
	elseif tree.s==1 then -- found
		dig.forward();
		move.forward();
		tree.s=2
	elseif tree.s==2 then -- dig up
		node = read_node.up()
		dig.up()
		move.up()
		place.down(support)
		if node ~= wood then
			tree.s=3 tree.st = 0
		end
	elseif tree.s==3 then -- on top
		if tree.st == 0 then
			move.up();
			turn.right();place.forward_down(support);
			dig.forward()
			turn.angle(180); place.forward_down(support);
			tree.st=1
		elseif tree.st == 1 then
			dig.forward(); move.forward();
			tree.st=2
		elseif tree.st == 2 then
			turn.left(); dig.forward(); turn.angle(180)
			tree.st=3
		elseif tree.st == 3 then
			dig.forward(); turn.right(); tree.st = 4
		elseif tree.st == 4 then
			dig.down();move.forward(); move.forward(); tree.st = 5
		elseif tree.st == 5 then
			turn.left(); dig.forward(); turn.angle(180)
			tree.st=6
		elseif tree.st == 6 then
			dig.forward(); turn.right(); tree.st = 7
		elseif tree.st == 7 then
			dig.down();move.forward(); 
			turn.right();
			tree.st = 0; tree.s = 4
		end
	elseif tree.s == 4 then -- going down
		node = read_node.down()
		if node == wood then
			dig.down();
			move.down();
		else 
			pickup(8); move.forward();
			place.backward(sapling)
			tree.s=5
		end
	end

end




-- walk around
if not s then 
wall = "basic_robot:buttonFFFFFF";
s=0
if rom.tree and rom.s then 
		tree.s = rom.tree.s; tree.st = rom.tree.st
		s = rom.s;
		rom.s = nil;
	else 
		rom.tree = {}
	end;

angle = 90 
end

if s==0 then -- walk
	
	if not move.forward() then
		node = read_node.forward();
		if node == wood then 
			s = 1 
		else
			turn.angle(angle); node = read_node.forward()
			if node == wall then 
				turn.angle(180);move.forward();turn.angle(-angle)
			else 
				move.forward(); turn.angle(angle)angle=-angle;
			end
		end
	end
elseif s==1 then
	tree_step();
	if tree.s == 5 then s = 0; tree.s = 0 end
end

rom.s = s;rom.tree.s = tree.s; rom.tree.st = tree.st -- remember whats it doing


--self.label(s .. " " .. tree.s .. " " .. tree.st)