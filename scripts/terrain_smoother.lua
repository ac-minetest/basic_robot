--smoothie robot: smooths selected terrain with slopes: define region with chat c1,c2, smooth with s

if not paste then
  _G.minetest.forceload_block(self.pos(),true)
	paste = {};
	round = function(x)
		if x>0 then 
			return math.floor(x+0.5)
		else
			return -math.floor(-x+0.5)
		end
	end
	
	is_solid = function(i,j,k, is_return)
		local dat = data[i]
		if not is_return then
			if not dat then return false end
			dat = dat[j];
			if not dat then return false end
			dat = dat[k];
			if not dat then return false end
			return true
		else
			if not dat then return 0 end
			dat = dat[j];
			if not dat then return 0 end
			dat = dat[k];
			if not dat then return 0 end
			return dat
		end
	end
	
	solidnodes = {
		["default:stone"] = 1,
		["default:dirt"] = 2,
		["default:stone_with_coal"] = 0,
		["default:dirt_with_dry_grass"] = 2,
		["default:silver_sand"] = 0,
		["default:sand"] = 0,
	}
	
	solidtypes = 
	{ 
		[1] = "stone",
		[2] = "dirt"
	};
	
	data = {};
	self.listen(1)
	self.label("mr. smoothie")
end


speaker, msg = self.listen_msg()

if msg and (true or speaker == "rnd") then
	local player = _G.minetest.get_player_by_name(speaker);
	local p = player:getpos(); p.x = round(p.x); p.y=round(p.y); p.z = round(p.z);
	if msg == "c1" then
		paste.src1 = {x=p.x,y=p.y,z=p.z};say("marker 1 set at " .. p.x .. " " .. p.y .. " " .. p.z)
	elseif msg == "c2" then
		paste.src2 = {x=p.x,y=p.y,z=p.z};say("marker 2 set at " .. p.x .. " " .. p.y .. " " .. p.z)

		elseif msg == "c" then -- LOAD geometry in memory
		local x1 = math.min(paste.src1.x,paste.src2.x);local y1 = math.min(paste.src1.y,paste.src2.y);local z1 = math.min(paste.src1.z,paste.src2.z);
		local x2 = math.max(paste.src1.x,paste.src2.x);local y2 = math.max(paste.src1.y,paste.src2.y);local z2 = math.max(paste.src1.z,paste.src2.z);
		x1=x1-1;y1=y1-1;z1=z1-1;x2=x2+1;y2=y2+1;z2=z2+1;
		local count = 0; data = {};
		for i = x1,x2 do
			for j = y1,y2 do
				for k = z1,z2 do
					local node = _G.minetest.get_node({x=i,y=j,z=k});
					local typ = solidnodes[node.name];
					if not typ then if string.sub(node.name,1,4) == "more" then typ = 1 end end
					if typ  then
						if not data[i] then data[i]= {} end
						if not data[i][j] then data[i][j]= {} end
						data[i][j][k] = -typ
						count = count +1;
					end
				end
			end
		end
		say(count .. " nodes copied ");
	elseif msg == "s" then -- SMOOTHING PROCESS
		local x1 = math.min(paste.src1.x,paste.src2.x);local y1 = math.min(paste.src1.y,paste.src2.y);local z1 = math.min(paste.src1.z,paste.src2.z);
		local x2 = math.max(paste.src1.x,paste.src2.x);local y2 = math.max(paste.src1.y,paste.src2.y);local z2 = math.max(paste.src1.z,paste.src2.z);
		local count = 0; local newnode = {};
		for i = x1,x2 do
			for j = y1,y2 do
				for k = z1,z2 do
					local x = i;local y = j; local z = k;
						--say(x .. " " .. y .. " " .. z)
						if is_solid(x,y,z) and not is_solid(x,y+1,z) then -- floor node
							local xs1,xs2,zs1,zs2
							if is_solid(x-1,y,z) then if is_solid(x-1,y+1,z) then xs1 = 1 else xs1 = 0 end else xs1 = -1 end
							if is_solid(x+1,y,z) then if is_solid(x+1,y+1,z) then xs2 = 1 else xs2 = 0 end else xs2 = -1 end
							
							if is_solid(x,y,z-1) then if is_solid(x,y+1,z-1) then zs1 = 1 else zs1 = 0 end else zs1 = -1 end
							if is_solid(x,y,z+1) then if is_solid(x,y+1,z+1) then zs2 = 1 else zs2 = 0 end else zs2 = -1 end
							
							local dx = xs2 - xs1; local dz = zs2 - zs1; ch = 0;
							if dx > 0 and dz == 0 then 
								if xs1<0 then
									newnode[1] = "moreblocks:slope_stone"; newnode[2] = 1; ch = 1
									data[x][y][z] = 2;
								end
							elseif  dx<0 and dz == 0 then
								if xs2<0 then
									newnode[1] = "moreblocks:slope_stone"; newnode[2] = 3; ch = 1
									data[x][y][z] = 2;
								end
							elseif dx == 0 and dz < 0 then
								if zs2<0 then
									newnode[1] = "moreblocks:slope_stone"; newnode[2] = 2; ch = 1
									data[x][y][z] = 2;
								end
							elseif dx == 0 and dz > 0 then
								if zs1<0 then
									newnode[1] = "moreblocks:slope_stone"; newnode[2] = 0; ch = 1
									data[x][y][z] = 2;
								end

							elseif dx<0 and dz>0 then
								newnode[2] = 0; ch = 1
								if xs2 == 0 and zs1 == 0 then
									newnode[1] = "moreblocks:slope_stone_inner"; 
									data[x][y][z] = 5;
								else
									newnode[1] = "moreblocks:slope_stone_outer_cut"
									data[x][y][z] = 3;
								end
							elseif dx>0 and dz>0 then
								newnode[2] = 1; ch = 1
								if xs1 == 0 and zs1 == 0 then
									newnode[1] = "moreblocks:slope_stone_inner"
									data[x][y][z] = 5;
								else
									newnode[1] = "moreblocks:slope_stone_outer_cut"
									data[x][y][z] = 3;
								end
							elseif dx>0 and dz<0 then
								newnode[2] = 2; ch = 1
								if xs1==0 and zs2 == 0 then
									newnode[1] = "moreblocks:slope_stone_inner"
									data[x][y][z] = 5;
								else
									newnode[1] = "moreblocks:slope_stone_outer_cut"
									data[x][y][z] = 3;
								end
							elseif dx<0 and dz<0 then
								newnode[2] = 3; ch = 1
								if xs2 == 0 and zs2 == 0 then
									newnode[1] = "moreblocks:slope_stone_inner"
									data[x][y][z] = 5;
								else
									newnode[1] = "moreblocks:slope_stone_outer_cut"
									data[x][y][z] = 3;
								end
							end
							if ch == 1 then _G.minetest.swap_node({x=x,y=y,z=z},{name = newnode[1], param2 = newnode[2]}) end
							
						end
				end
			end
		end
		
		--2nd pass
		-- smooth stones below slope_stone_outer_cut if there is at least one air in neighbor 4 diag. positions
		-- and set same param2 as above outer_cut
		-- slope = 2, outer cut = 3, inner cut =  4, inner = 5
		
		for i = x1,x2 do
			for j = y1,y2 do
				for k = z1,z2 do
					local x = i;local y = j; local z = k;
					
					if is_solid(x,y,z) and is_solid(x,y+1,z,true) == 3 then -- fix stone below outer cut
						if not is_solid(x-1,y,z-1) or not is_solid(x+1,y,z-1) or not is_solid(x-1,y,z+1)
						or not is_solid(x+1,y,z+1) then
							-- replace with inner cut to smooth diag. ramps
							local param2 = _G.minetest.get_node({x=x,y=y+1,z=z}).param2;
							_G.minetest.swap_node({x=x,y=y,z=z},{name = "moreblocks:slope_stone_inner_cut", param2 = param2})
						end
					
					--fix possible holes
					elseif is_solid(x,y,z,true) == 5 and not is_solid(x,y+1,z) then --hole fix: inner 
						if is_solid(x-1,y,z-1) and is_solid(x+1,y,z-1) and is_solid(x-1,y,z+1)
						and is_solid(x+1,y,z+1) then
							_G.minetest.swap_node({x=x,y=y,z=z},{name = "default:stone"})
						end
					elseif is_solid(x,y,z,true) == 4 and not is_solid(x,y+1,z) then -- hole fix: inner cut
						if is_solid(x-1,y,z-1) and is_solid(x+1,y,z-1) and is_solid(x-1,y,z+1)
						and is_solid(x+1,y,z+1) then
							_G.minetest.swap_node({x=x,y=y,z=z},{name = "default:stone"})
						end
					
					elseif is_solid(x,y,z,true)<0 and not is_solid(x,y+1,z) then -- attempt to smooth blocky stones near outer cuts
						local x0,z0;
						if is_solid(x-1,y,z,true) == 3 -- outer cut
							then x0 = x-1; z0 = z;
						elseif is_solid(x+1,y,z,true) == 3
							then x0 = x+1; z0 = z;
						elseif is_solid(x-1,y,z-1,true) == 3
							then x0 = x-1; z0 = z-1;
						elseif is_solid(x+1,y,z+1,true) == 3
							then x0 = x+1; z0 = z+1;
						end
						if x0 then
							local param2 = _G.minetest.get_node({x=x0,y=y,z=z0}).param2;
							_G.minetest.swap_node({x=x,y=y,z=z},{name = "moreblocks:slope_stone_inner_cut", param2 = param2})
						end
					end
				
				end
			end
		end	
		
		

	
	end
end