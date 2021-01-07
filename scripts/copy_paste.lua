-- COPY PASTE ROBOT by rnd: c1 c2 r = markers, c = copy p = paste, rotz = rotate 90 deg cw z-axis, s = set
-- command parameters :
-- 		s nodename node_step
--		copy: 
--			c1,c2 set markers, r set reference, c = copy, 
--			p = paste at player position (reference is put there)
--		rotate: 
--			c1,c2 set area,  rotz = rotate 90 deg around z-axis

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
	data = {};
	
	display_marker = function(pos,label)
		minetest.add_particle(
		{
			pos = pos,
			expirationtime = 10,
			velocity = {x=0, y=0,z=0},
			size = 9,
			texture = label..".png",
			acceleration = {x=0,y=0,z=0},
		})
	
	end
	
	self.listen(1)
self.label("")
--	self.label("WorldEdit Bot\ncommands: c1 c2 r c p s rotz")
end


speaker, msg = self.listen_msg()

if speaker == "_" or speaker == "test" then
	local args = {}
	for word in string.gmatch(msg,"%S+") do args[#args+1]=word end
	
	local player = _G.minetest.get_player_by_name(speaker);
	local p = player:getpos(); p.x = round(p.x); p.y=round(p.y); p.z = round(p.z);
	if p.y<0 then p.y = p.y +1 end -- needed cause of minetest bug
	if args[1] == "c1" then
		paste.src1 = {x=p.x,y=p.y,z=p.z};say("marker 1 set at " .. p.x .. " " .. p.y .. " " .. p.z,speaker)
		display_marker(p,"099") -- c
	elseif args[1] == "c2" then
		paste.src2 = {x=p.x,y=p.y,z=p.z};say("marker 2 set at " .. p.x .. " " .. p.y .. " " .. p.z,speaker)
		display_marker(p,"099") -- c
	elseif args[1] == "r" then
		paste.ref = {x=p.x,y=p.y,z=p.z};say("reference set at " .. p.x .. " " .. p.y .. " " .. p.z,speaker)
		display_marker(p,"114") -- r
	elseif args[1] == "c" then -- copy
		local x1 = math.min(paste.src1.x,paste.src2.x);local y1 = math.min(paste.src1.y,paste.src2.y);local z1 = math.min(paste.src1.z,paste.src2.z);
		local x2 = math.max(paste.src1.x,paste.src2.x);local y2 = math.max(paste.src1.y,paste.src2.y);local z2 = math.max(paste.src1.z,paste.src2.z);
		local count = 0; data = {};
		for i = x1,x2 do
			for j = y1,y2 do
				for k = z1,z2 do
					local node = _G.minetest.get_node({x=i,y=j,z=k});
					if node.name ~= "air" then
						if not data[i] then data[i]= {} end
						if not data[i][j] then data[i][j]= {} end
						data[i][j][k] = {node, _G.minetest.get_meta({x=i,y=j,z=k}):to_table()}
						count = count +1;
					end
				end
			end
		end
		say(count .. " nodes copied ");
	elseif args[1] == "p" then -- paste
		local x1 = math.min(paste.src1.x,paste.src2.x);local y1 = math.min(paste.src1.y,paste.src2.y);local z1 = math.min(paste.src1.z,paste.src2.z);
		local x2 = math.max(paste.src1.x,paste.src2.x);local y2 = math.max(paste.src1.y,paste.src2.y);local z2 = math.max(paste.src1.z,paste.src2.z);
		local count = 0; p.x = p.x-paste.ref.x; p.y = p.y-paste.ref.y; p.z = p.z-paste.ref.z;
		for i = x1,x2 do
			for j = y1,y2 do
				for k = z1,z2 do
					local pdata;
					if data[i] and data[i][j] and data[i][j][k] then
						pdata = data[i][j][k]
					end
					if pdata then
						count = count + 1
						_G.minetest.set_node({x=i+p.x,y=j+p.y,z=k+p.z}, pdata[1]);
						_G.minetest.get_meta({x=i+p.x,y=j+p.y,z=k+p.z}):from_table(pdata[2])
					end
					
				end
			end
		end
		say(count .. " nodes pasted ",speaker);
	elseif args[1] == "s" then -- set node
		local nodename = args[2] or "air"
		local step = args[3] or 1;
		local x1 = math.min(paste.src1.x,paste.src2.x);local y1 = math.min(paste.src1.y,paste.src2.y);local z1 = math.min(paste.src1.z,paste.src2.z);
		local x2 = math.max(paste.src1.x,paste.src2.x);local y2 = math.max(paste.src1.y,paste.src2.y);local z2 = math.max(paste.src1.z,paste.src2.z);
		local count = 0; 
		for i = x1,x2,step do
			for j = y1,y2,step do
				for k = z1,z2,step do
					minetest.set_node({x=i,y=j,z=k}, {name = nodename});
				end
			end
		end
		say((x2-x1+1)*(y2-y1+1)*(z2-z1+1) .. " nodes set to " .. nodename,speaker)
	elseif args[1] == "rotz" then -- rotate around z axis, center of selection
		local x1 = math.min(paste.src1.x,paste.src2.x);local y1 = math.min(paste.src1.y,paste.src2.y);local z1 = math.min(paste.src1.z,paste.src2.z);
		local x2 = math.max(paste.src1.x,paste.src2.x);local y2 = math.max(paste.src1.y,paste.src2.y);local z2 = math.max(paste.src1.z,paste.src2.z);
		
		
		local d = x2-x1; if z2-z1<d then z2 = z1+d else d = z2-z1; x2 = x1+d end -- will be rotated as square in xz
		local rotzd = {
			[0]=1,[1]=2,[2]=3,[3]=0,
			[7]=12,[12]=9,[9]=18,[18]=7,
			[8]=17,[17]=6,[6]=15,[15]=8,
			[19]=4,[4]=13,[13]=10,[10]=19,
			[20]=23,[23]=22,[22]=21,[21]=20,
		}
		local count = 0; local step = 1

		local data = {}; -- copy first
		for i = x1,x2 do
			for j = y1,y2 do
				for k = z1,z2 do
					local node = _G.minetest.get_node({x=i,y=j,z=k});
					minetest.swap_node({x=i,y=j,z=k},{name = "air"})
					if node.name ~= "air" then
						if not data[i] then data[i]= {} end
						if not data[i][j] then data[i][j]= {} end
						data[i][j][k] = node
						count = count +1;
					end
				end
			end
		end
		
		-- (x,z)->(z,-x)
		-- square rotate around center: x,z -> x-dx/2, z-dz/2 ->z-dz/2,dx/2-x -> (z, dx-x)
		-- (x,z) -> (z,x1+x2-x)
		--[[
		           x1,z1 
		           *

        * x1,z1
		add offset to put middle of square into 0,0 and then back..
		
		x->x-x1-dx/2, z-z1-dz/2 -> z-z1-dz/2, x1-dx/2-x ->
		z-z1-dz/2+x1+dx/2,x1-dx/2-x+z1+dz/2 =
		z-z1+x1,z1+x1-x
		--]]
		
		for i = x1,x2,step do
			for j = y1,y2,step do
				for k = z1,z2,step do
					local pdata;
					if data[i] and data[i][j] and data[i][j][k] then
						pdata = data[i][j][k]
					end
					if pdata then -- correct position, rotated 90deg, TODO!
						local node = pdata
						node.param2 = rotzd[node.param2] or 0;
						minetest.swap_node({x=k+x1-z1,y=j,z=x1+z1-i}, node)
					end
				end
			end
		end
		say(count .. " nodes rotated around z-axis");
	end
end