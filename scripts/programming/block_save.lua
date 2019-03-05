-- subdivide rectangular area made from various node types into union of disjoint contigious boxes,
-- box count should be small, by rnd 2018

if not init then
	init = true -- map saver
	local dout = function(msg) minetest.chat_send_player("rnd", msg) end
	
	minidx = 1 -- minimal position index not yet in box collection

	blockdata = {}; --[1] = {p1,p2} [2] = list of nodenames, [3] = list [x][y][z] = nodename idx

	
	table_copy = function(tab)
		local out = {};
		for k,v in pairs(tab) do
			out[k] = v
		end
		return out
	end
	
	read_block = function(p1,p2,data)
		if p1.x>p2.x or p1.y>p2.y or p1.z>p2.z then return end -- p1 coords must be smaller than p2 coords
		
		data[1] = {{x=p1.x,y=p1.y,z=p1.z},{x=p2.x-p1.x+1,y=p2.y-p1.y+1,z=p2.z-p1.z+1}} -- startpos, dimensions

		local nodedb = {} -- [nodename] = node idx
		local nodelist = {} -- list of nodes: nodename1, nodename2,...
		local nodes = {} -- table containing nodes [x][y][z] = node idx
		local ncount = 0;
		local idx = 0
		for x = p1.x, p2.x do
			nodes[x-p1.x+1] = {}
			for y = p1.y, p2.y do
				nodes[x-p1.x+1][y-p1.y+1] = {}
				for z = p1.z, p2.z do
					idx=idx+1
					local nodename = minetest.get_node({x=x,y=y,z=z}).name
					local nidx = nodedb[nodename]
					if not nidx then
						ncount = ncount + 1
						nodedb[nodename] = ncount;
						nodelist[ncount] = nodename
						nidx = ncount
					end
					--nodes[idx] = nidx
					nodes[x-p1.x+1][y-p1.y+1][z-p1.z+1 ] = nidx
				end
			end
		end
		
		data[2] = nodelist
		data[3] = nodes
	end
	
	id2pos = function(idx,blockdata) -- idx starts with 0
		local dx = blockdata[1][2].x
		local dy = blockdata[1][2].y
		local dz = blockdata[1][2].z

		-- idx = z*dx*dy + y*dx + dx
		local x = idx % dx; 
		idx = (idx - x)/dx
		local y = idx % dy; -- y = y % (dy)
		local z = (idx - y)/dy
		return {x=x, y = y, z=z}
	end

	pos2id = function(pos,blockdata)
		local dx = blockdata[1][2].x
		local dy = blockdata[1][2].y
		local dz = blockdata[1][2].z
		
		local x = pos.x - blockdata[1][2].x;
		local y = pos.y - blockdata[1][2].y;
		local z = pos.z - blockdata[1][2].z;
		return z*dx*dy + y*dx + dx
	end
	
	get_box = function(pos, blockdata, boxdata) -- return p1,p2, nodeidx defining largest contiguos box containing pos (all relative coordinates)
	
		local nodeidx = blockdata[3][pos.x][pos.y][pos.z];
	
		local active_dir = {[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true}; -- which dirs to search: x-,x+   y-,y+   z-,z+
		local p1 = {x=pos.x,y=pos.y,z=pos.z} -- search limits
		local p2 = {x=pos.x,y=pos.y,z=pos.z}
		local stop =  false;
		
		local steps = 0
		while not stop and steps < 10000 do -- steps 'safety'
			steps = steps + 1
			--dout("step " .. steps .. " p1 " .. serialize(p1) .. " p2 " .. serialize(p2) .. " dirs " .. serialize(active_dir))
			stop = true
			for idx,_ in pairs(active_dir) do -- try expansion in different directions
				stop = false -- still something to do
				if idx<=2 then 
					local x
					if idx == 1 then x = p1.x-1 else x=p2.x+1 end
					if blockdata[3][x] then
						local bdata = blockdata[3][x];
						for y = p1.y,p2.y do
							for z = p1.z,p2.z do
								if bdata[y][z]~= nodeidx  or (boxdata and boxdata[x] and boxdata[x][y] and boxdata[x][y][z]) then
									active_dir[idx] = nil; goto ex; -- not contiguous anymore
								end
							end
						end
						::ex::
					else
						active_dir[idx] = nil -- out of bounds, remove direction
					end
					if active_dir[idx] then -- expansion succesful
						if idx == 1 then p1.x = p1.x -1 else p2.x = p2.x+1 end
					end
					
				elseif idx>=5 then 
					local z
					if idx == 5 then z = p1.z-1 else z=p2.z+1 end
					local bdata = blockdata[3]
					if bdata[1][1][z] then
						for x = p1.x,p2.x do
							for y = p1.y,p2.y do
								if bdata[x][y][z]~= nodeidx or (boxdata and boxdata[x] and boxdata[x][y] and boxdata[x][y][z]) then
									active_dir[idx] = nil;goto ex; -- lua only breaks out of 1 loop :(
								end
							end
						end
						::ex::
					else
						active_dir[idx] = nil -- out of bounds, remove direction
					end
					
					if active_dir[idx] then -- expansion succesful
						if idx == 5 then p1.z = p1.z -1 else p2.z = p2.z+1 end
					end
				else
					local y
					if idx == 3 then y = p1.y-1 else y=p2.y+1 end
					local bdata = blockdata[3]
					if bdata[1][y] then
						for x = p1.x,p2.x do
							for z = p1.z,p2.z do
								if bdata[x][y][z]~= nodeidx or (boxdata and boxdata[x] and boxdata[x][y] and boxdata[x][y][z]) then
									active_dir[idx] = nil; goto ex; -- not contiguous anymore
								end
							end
						end
						::ex::
					else
						active_dir[idx] = nil -- out of bounds, remove direction
					end
					
					if active_dir[idx] then -- expansion succesful
						if idx == 3 then p1.y = p1.y-1 else p2.y = p2.y+1 end
					end
				
				end
			
			end --try to expand: -x +x -y +y -z +z -x +x -y ... when not possible remove direction from list
		end
		
		return {p1,p2, nodeidx}		
	end
	
	get_boxes = function(blockdata,boxdata)
	
		local dx = blockdata[1][2].x
		local dy = blockdata[1][2].y
		local dz = blockdata[1][2].z
		
		for k,v in pairs(boxdata) do boxdata[k] = nil end
		local res = {}; -- list of boxes
		
		
		for x=1,dx do 
			boxdata[x] = {} 
			for y = 1,dy do
				boxdata[x][y] = {}
			end
		end
		
		
		local xc, yc,zc;
		xc = 1 ; yc = 1; zc = 1; -- current 'working' coordinates in block
		
		local steps = 0;
		local stop = false;
		
		while not stop and steps < 1000 do
			steps = steps + 1
			stop = true
			
			-- find 'next' coordinate thats not yet marked: todo - fix bugs here, skipping/unnecessary ...
			
			xc = 1; -- set 1st index ( inner loop) to start
			--dout("step " .. steps ..", search start xc yc zc ".. xc .. " " .. yc .. " " .. zc)
			
			local x,y,z;x= xc; y=yc; z = zc;
			while (z<=dz) do
				while (y<=dy) do
					while (x<=dx) do
						if not boxdata[x][y][z] then 
							--dout("step " .. steps .. ", next point:  " .. x .. " " .. y .. " " .. z)
							stop = false; xc = x; yc=y; zc = z; goto ex 
						end
						x=x+1
					end
					y=y+1; x=1; -- reset x-loop
				end
				z=z+1; y=1; -- reset y-loop
			end
			
			--dout("no unmarked point left, dim dx dy dz : " .. dx .. " " .. dy .. " " .. dz)
			
			::ex::
			if stop then break end
			
			--if box non air add it

			local box = get_box({x=xc,y=yc,z=zc},blockdata, boxdata);
			if blockdata[2][box[3]]~= "air" then 
				res[#res+1] = box
			end
			-- mark box area as done
			
			for x = box[1].x, box[2].x do
				for y = box[1].y, box[2].y do
					for z = box[1].z, box[2].z do
						boxdata[x][y][z] = true
					end
				end
			end
			
			--dout("boxdata " .. serialize(boxdata))
		end
		
		return res
	end
	
	render_boxes = function(blockdata,boxes)
		local dx = blockdata[1][2].x
		local dy = blockdata[1][2].y
		local dz = blockdata[1][2].z
		
		local x0 = blockdata[1][1].x
		local y0 = blockdata[1][1].y
		local z0 = blockdata[1][1].z
		
		
		local nodelist = {
			"wool:white","wool:red","wool:green","wool:blue","wool:yellow", "wool:cyan","wool:pink",
			"wool:brown","wool:magenta","wool:orange","wool:violet"
		}
		local nodelen = #nodelist
		
		for x = 1, dx do
			for y = 1, dy do
				for z = 1, dz do
					minetest.set_node({x = x0+x-1, y= y0+y-1+ (dy + 1), z = z0+z-1},{name = "air"})
				end
			end
		end
		
		
		for i = 1,#boxes do
			for x = boxes[i][1].x, boxes[i][2].x do
				for y = boxes[i][1].y, boxes[i][2].y do
					for z = boxes[i][1].z, boxes[i][2].z do
						--minetest.set_node({x = x0+x-1, y= y0+y-1+ (dy + 4), z = z0+z-1},{name = blockdata[2][boxes[i][3] ] })
						minetest.set_node({x = x0+x-1, y= y0+y-1+ (dy + 4), z = z0+z-1},{name = nodelist[1+((i-1) % nodelen)]})
					end
				end
			end
		end
	end
	
	
	--p1 = {x=-57,y=6,z=14};p2 = {x=-54,y=6,z=17}
	p1 = {x=-45,y=502,z=-45};p2 = {x=-30,y=504,z=-30}

	read_block(p1,p2,blockdata) -- careful, all p1 coords must be smaller than p2 coords coordinatewise
	--self.label(serialize(blockdata))
	
	-- 7 numbers per box: pos1, pos2, nodeidx. There are n^2 numbers for nxn grid, so for boxes to be efficient
	-- 7*boxcount<n^3 or boxcount< n^3/7
	
	--box = get_box({x=3,y=1,z=2},blockdata)
	--say(serialize(box))
	
	local boxdata = {};
	local boxes = get_boxes(blockdata,boxdata);
	self.label("dimensions " .. blockdata[1][2].x .. " " .. blockdata[1][2].y .. " " .. blockdata[1][2].z  .. ", n^3/7 = " .. blockdata[1][2].x*blockdata[1][2].y*blockdata[1][2].z/7 .. ", boxes " .. #boxes )
	--dout(serialize(boxes))
	
	render_boxes(blockdata,boxes)
	

end