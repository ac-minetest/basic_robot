if not data then
	m=50;n=50; minescount = m*n/10;
	
	t0 = _G.minetest.get_gametime();
	data = {}; spawnpos = self.spawnpos();
	for i = 1, minescount do local i = math.random(m); local j = math.random(n); if not data[i] then data[i] = {} end; data[i][j] = 1; end

	get_mine_count = function(i,j)
		if i<0 or i>m+1 or j<0 or j>n+1 then return 0 end; count = 0
		for k = -1,1 do	for l = -1,1 do
				if data[i+k] and data[i+k][j+l] == 1 then count = count +1 end
		end	end
		return count
	end
	
	for i = 1,m do for j = 1,n do
		if get_mine_count(i,j) > 0 or (data[i] and data[i][j] == 1) then
			_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j}, {name = "basic_robot:buttonFFFFFF"})
		else
			_G.minetest.swap_node({x=spawnpos.x+i,y=spawnpos.y,z=spawnpos.z+j}, {name = "default:dirt"})
		end
	end	end
end
self.remove()