-- rnd 2017
if not pos then 
	pos = self.spawnpos();
	n = 6; -- width
	m = 4; -- height
	door = math.floor(n/2)+1; -- door place
	
	plan = {};
	build_cube = function(x,y,z)
		plan[#plan+1] = {c= math.random(10)+6, pos={x=pos.x+x,y=pos.y+y,z=pos.z+z}};	
	end
	
	--floor
	y=0;for z=1,n do for x=1,n do build_cube(x,y,z) end	end --bottom
	
	z=1;for y=1,m do for x=1,n do build_cube(x,y,z) end end --wall 1
	z=n;for y=1,m do for x=1,n do build_cube(x,y,z) end end --wall2
	
	x=n;for y=1,m do for z=2,n-1 do build_cube(x,y,z) end end -- wall3
	x=1;for y=1,m do for z=2,n-1 do if z~=door then build_cube(x,y,z) end end end -- wall4
	x=1;z=door;for y=3,m do build_cube(x,y,z) end -- door hole
	
	
	y=m;for x = 2,n-1 do for z = 2,n-1 do build_cube(x,y,z) end end -- ceiling
	s=0
	--self.remove()
end

s=s+1;
if plan[s] then
	keyboard.set(plan[s].pos,plan[s].c)
else 
	self.remove()
end