-- 3d printer bot, made by rnd in 30 mins
if not init then
	
	nx = 5; ny = 5; nz = 5
	data = {}; -- [nx][nz][ny]
	
	rndseed = 1;
	random = function(n)
		rndseed = (48271*rndseed)% 2147483647;
		return rndseed % n
	end
	
	for i = 1,nx do 
		data[i]={}
		for j = 1,nz do
			data[i][j] = {}
			for k = 1,ny do
				if random(2) == 1 then data[i][j][k] = true end -- make random structure
			end
		end
	end
	
	local spos = self.spawnpos(); spos.y = spos.y+1; spos.z = spos.z+1
	state = 1; -- walk in x way, state = 1: build up
	x=1; z = 1; y = 1; angle = -90
	zc = 1; worky = 1;	
	
	get_worky = function()
		worky = 0
		local dataxz = data[x][zc]
		if not dataxz then return end
		for k = ny,1,-1 do if dataxz[k] then worky = k  break end end
	end
	get_worky()
	
	move.forward(); move.right()
	init = true
end



if state == 0 then -- walk around
	if z>=nz then 
		x = x+1; z=0; 
		turn.angle(angle); move.forward(); turn.angle(angle)
		angle = -angle;
		if x>nx then self.remove() end 
	else
		move.forward()
	end
	z=z+1
	if angle<0 then zc = z else zc = nz-z+1 end
	get_worky() -- is there anything to print at x,z?
	if worky>0 then state = 1 y = 1 end
	
	self.label("walking at " .. x .. " " .. zc .. ", worky =  " .. worky)
elseif state == 1 then -- make coloumn
	
	if y>=worky+1 then
		state = 2 -- go down ladder
	else
		place.down("default:ladder")
		y=y+1; move.up()
	end
	self.label("going up " .. x .. " " .. zc .. ", y = " .. (y-1))
elseif state == 2 then  -- go down and build
	dig.down();move.down(); 
	
	if data[x][zc][y-1] then place.up("default:dirt") end
	y=y-1
	self.label("going down at " .. x .. " " .. zc .. ", y = " .. (y-1))
	if y<2 then state = 0; y = 1 end
end