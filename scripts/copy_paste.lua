-- COPY PASTE ROBOT by rnd: c1 c2 r = markers, c = copy p = paste

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
			size = 18,
			texture = label..".png",
			acceleration = {x=0,y=0,z=0},
			collisiondetection = true,
			collision_removal = true,			
		})
	
	end
	
	self.listen(1)
	self.label("COPY-PASTE MASTER v1.2 gold edition. commands: c1 c2 r c p")
end


speaker, msg = self.listen_msg()

if speaker == "rnd" then
	local player = _G.minetest.get_player_by_name(speaker);
	local p = player:getpos(); p.x = round(p.x); p.y=round(p.y); p.z = round(p.z);
	if p.y<0 then p.y = p.y +1 end -- needed cause of minetest bug
	if msg == "c1" then
		paste.src1 = {x=p.x,y=p.y,z=p.z};say("marker 1 set at " .. p.x .. " " .. p.y .. " " .. p.z)
		display_marker(p,"099") -- c
	elseif msg == "c2" then
		paste.src2 = {x=p.x,y=p.y,z=p.z};say("marker 2 set at " .. p.x .. " " .. p.y .. " " .. p.z)
		display_marker(p,"099") -- c
	elseif msg == "r" then
		paste.ref = {x=p.x,y=p.y,z=p.z};say("reference set at " .. p.x .. " " .. p.y .. " " .. p.z)
		display_marker(p,"114") -- r
	elseif msg == "c" then -- copy
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
	elseif msg == "p" then -- paste
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
		say(count .. " nodes pasted ");
	end
end