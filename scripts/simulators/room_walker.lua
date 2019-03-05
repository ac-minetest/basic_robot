--TODO: unfinished
if not init then
	state = 0
	init = true
	walkdb = {};
	spos = self.spawnpos();
	step = 0
	startstep = 0; -- mark the step when next walk around begins
	
	local get_dir = function()
		local dir = self.viewdir()
	end
	
	rot_left = function(dir) local tmp = dir.x;dir.x = -dir.z; dir.z = tmp end
	
	rot_right = function(dir) local tmp = dir.x;dir.x = dir.z; dir.z = -tmp end
	
end

if state == 0 then
	if not move.forward() then state = 1; turn.right(); startstep = 1 end
elseif state == 1 then
	step  = step + 1
	local pos = self.pos();
	local x = pos.x-spos.x; local z = pos.z-spos.z;
	if not walkdb[x] then walkdb[x] = {} end walkdb[x][z] = step; -- add position
	local dir = self.viewdir();	
	
	local node = read_node.left();
	
	

	rot_left(dir) -- rotate left
	local xr = x + dir.x; local zr = z + dir.z
	
	if node == "air" and (not dir[xr] or not dir[xr][zr]) then turn.left() end
	if not move.forward() and (not dir[xn] or not dir[xn][zn]) then turn.right() move.forward() end
end

self.label(state)