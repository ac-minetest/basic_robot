-- Rubik Cube

if not init then init = true
	self.listen_punch(self.pos())
	pname = find_player(5);	if not pname then say("no players!");self.remove() end;	pname = pname[1];
	player = minetest.get_player_by_name(pname)
	say("rubik cube. rotation is indicated by your view direction")

	n=3;
	-- top left first

	yz1 = { --  size n^2, side looking toward x-
	7,1,8,
	1,1,1,
	9,1,1
	}

	yz2 = { -- size n^2, side looking toward x+
	7,2,8,
	2,2,2,
	9,2,2
	}
	
	xy1 = { -- size n^2, side looking toward z-
	7,3,8,
	3,3,3,
	9,3,3
	}
	
	xy2 = { -- size n^2, side looking toward z+
	7,4,8,
	4,4,4,
	9,4,4,
	}
	
	xz1 = { -- size n^2, side looking toward y-
	7,5,8,
	5,5,5,
	9,5,5,
	}
	
	xz2 = { -- size n^2, side looking toward y+
	7,6,8,
	6,6,6,
	9,6,6,
	}
	
	surfdata = {
		["yz1"]={
			rotations = {
				[0] = "face cw",
				[1] = "face ccw",
				[2] = "horizontal +",
				[3] = "horizontal -",
				[4] = "vertical +",
				[5] = "vertical -",
			}
		}
	
	}


	blocks = {
		"basic_robot:button808080",
		"basic_robot:buttonFF8080",
		"basic_robot:button80FF80",
		"basic_robot:button8080FF",
		"basic_robot:buttonFFFF80",
		"basic_robot:buttonFFFFFF",
		"basic_robot:button_48", --7
		"basic_robot:button_49", --8
		"basic_robot:button_50", --9
	}

	render_cube = function()
		local p = self.pos();
		for y=1,n do
			for z=1,n do
				minetest.swap_node({x=p.x+1,y=p.y+y+1,z=p.z+z},{name = blocks[yz1[n*(y-1)+z]]})
			end
		end
		for y=1,n do
			for z=1,n do
				minetest.swap_node({x=p.x+n+2,y=p.y+y+1,z=p.z+z},{name = blocks[yz2[n*(y-1)+z]]})
			end
		end
		
		for x=1,n do
			for y=1,n do
				minetest.swap_node({x=p.x+x+1,y=p.y+y+1,z=p.z},{name = blocks[xy1[n*(x-1)+y]]})
			end
		end
		
		for x=1,n do
			for y=1,n do
				minetest.swap_node({x=p.x+x+1,y=p.y+y+1,z=p.z+n+1},{name = blocks[xy2[n*(x-1)+y]]})
			end
		end
		
		for x=1,n do
			for z=1,n do
				minetest.swap_node({x=p.x+x+1,y=p.y+1,z=p.z+z},{name = blocks[xz1[n*(x-1)+z]]})
			end
		end
		
		for x=1,n do
			for z=1,n do
				minetest.swap_node({x=p.x+x+1,y=p.y+n+2,z=p.z+z},{name = blocks[xz2[n*(x-1)+z]]})
			end
		end
		
	end
	
	rotccw = function(tab)
		local newtab = {}
		local n = (#tab)^0.5
		for i = 1,n do
			for j = 1,n do
				newtab[(i-1)*n+j] = tab[(j-1)*n+n-i+1]
			end
		end
		return newtab
	end
	
	rotcw = function(tab)
		local newtab = {}
		local n = (#tab)^0.5
		for i = 1,n do
			for j = 1,n do
				newtab[(j-1)*n+n-i+1] = tab[(i-1)*n+j]
			end
		end
		return newtab
	end

	viewlim = 0.9; --how close to perpendicular need to look to rotate face
	p = self.pos();
	render_cube()
end

event = keyboard.get()
if event then 
	-- rotate depending where player looks, if he looks close to normal to surface rotate cw or ccw
	local view = player:get_look_dir()
	-- which way? face or horizontal or vertical?
	local rot = 0; -- rotation mode
	local face = "";
	local x=1;local y=1;
	
	if event.x == p.x+1 then 
		face= "yz1"
		if math.abs(view.x)>viewlim then	
			rot = 0; -- face cw
			yz1 = rotcw(yz1); -- face cw rotate
			--slice x=1 rotate:
			--[[{
				xz2,row 1,rev
				xy1,row 1,rev
				xz1,row 1,ord
				xy2,col 3,ord
			
			}
			note this same rotation can be reused for faces xz1,xy1,xz1,xy2
			
			maybe:
			
			rotslice(
				{xz2,1=row mode, 1 = row index, -1 = reverse},
				{xy1,1, 1, -1},
				{xz1,1, 1, 1 = ordinary},
				{xy2,2=col mode,3 = col index, 1}
			)
			
			--]]
		elseif math.abs(view.y)<math.abs(view.z) then -- horizontal
			if view.z>0 then rot = 2 else rot = 3 end
		else
			if view.y>0 then rot = 4 else rot = 5 end
		end
		
		self.label("face: " .. face ..", rotation: " .. surfdata[face].rotations[rot])
		
		render_cube()
	elseif event.x == p.x+n+2 then
		self.label("yz2")
		if math.abs(view.x)>viewlim then	
			yz2 = rotccw(yz2);
		end
		render_cube()
	elseif event.z == p.z then
		self.label("xy1")
		if math.abs(view.z)>viewlim then	
			xy1 = rotcw(xy1);
		end
		render_cube()
	elseif event.z == p.z+n+1 then
		self.label("xy2")
		if math.abs(view.z)>viewlim then	
			xy2 = rotccw(xy2);
		end
		render_cube()
	elseif event.y == p.y+1 then
		if math.abs(view.y)>viewlim then	
			xz1 = rotccw(xz1); 
		end
		render_cube()
		self.label("xz1")
	elseif event.y == p.y+n+2 then
		self.label("xz2")
		if math.abs(view.y)>viewlim then	
			xz2 = rotcw(xz2); 
		end
		render_cube()
	end
	--self.label(serialize(event)) 
end

-- ideas:
-- use whole full cube : array with n^3 elements, only border rendered. 
-- PROS: easy to get slices then and rotate them! CONS: much more memory used for larger cubes
-- 