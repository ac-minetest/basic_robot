if not s then
-- init
bots = {[4] = {}, [5] = {}}; -- [type] = {{1,1,10}, {3,2,10}}; -- {x,y,hp}
arena = {};  --[x][z] = {type, idx}
for i = -10,10 do arena[i] = {} for j=-10,10 do arena[i][j] = {0,0} end end
centerpos = self.spawnpos(); centerpos.y = centerpos.y+2
TYPE = 4; -- 4,5 defines which bots are on the move/attack
DIR = 1
s=0
t=0
--  load user progs
_,script1 = book.read(1);_,script2 = book.read(2);
prog1, _ = _G.loadstring( script1 ); prog2, _ = _G.loadstring( script2 );

	spawn_bot = function (x,z,type)
		if arena[x] and arena[x][z] and arena[x][z][1] == 0 then 
			keyboard.set({x=centerpos.x+x,y=centerpos.y,z=centerpos.z+z},type)
			table.insert(bots[type],{x,z,10})
			arena[x][z] = {type,#bots[type]}
		else 
			return false
		end
	end

	move_bot = function (i,dx,dz)
		local bot = bots[TYPE][i];if not bot then return false end
		if math.abs(dx)>1 or math.abs(dz)>1 then return false end
		local x1=bot[1]+dx; local z1=bot[2]+dz;
		if math.abs(x1)>10 or math.abs(z1)>10 then return false end
		if arena[x1] and arena[x1][z1] and arena[x1][z1][1] == 0 then else return false end
		
		keyboard.set({x=centerpos.x+bot[1],y=centerpos.y,z=centerpos.z+bot[2]},0);
		keyboard.set({x=centerpos.x+x1,y=centerpos.y,z=centerpos.z+z1},TYPE);
		arena[bot[1]][bot[2]] = {0,0}
		arena[x1][z1] = {TYPE,i}
		
		bot[1]=x1;bot[2]=z1;
	end

	attack_bot = function(i,dx,dz)
		local bot = bots[TYPE][i];if not bot then return false end
		if math.abs(dx)>1 or math.abs(dz)>1 then return false end
		local x1=bot[1]+dx; local z1=bot[2]+dz;
		if math.abs(x1)>10 or math.abs(z1)>10 then return false end
		if arena[x1] and arena[x1][z1] and arena[x1][z1][1] == 0 then return false end
		local type  = arena[x1][z1][1]; local idx = arena[x1][z1][2];
		local tbot = bots[type][idx];
		if not tbot then return false end
		tbot[3]=tbot[3]-5;
		if tbot[3]<=0 then
			keyboard.set({x=centerpos.x+tbot[1],y=centerpos.y,z=centerpos.z+tbot[2]},0);
			table.remove(bots[type],idx);
			arena[x1][z1] = {0,0}
		end
	end

	read_arena = function(x,z)
		local data = arena[x][z];
		if not data then return end
		return {data[1],data[2]};
	end

	read_bots = function (type, idx)
		local data = bots[type][idx];
		if not data then return end
		return {data[1],data[2],data[3]}
	end
end

if t%10 == 0 then
	spawn_bot(0,-10,4)
	spawn_bot(0,10,5)
end
t=t+1
self.label(#bots[4] .. " " .. #bots[5])

-- PROGRAM RULES: 
-- not allowed to modify api code: TYPE, bots,t,s, spawn_bot, move_bot, attack_bot, read_arena, read_bots
-- only allowed to move bot or attack, but not to dig/place

TYPE = 4+(t%2);
DIR = - DIR

if TYPE == 5 then 
	_G.setfenv(prog1, _G.basic_robot.data[self.name()].sandbox )
	_,err = pcall(prog1) 
else 
	_G.setfenv(prog2, _G.basic_robot.data[self.name()].sandbox )
	_,err = pcall(prog2) 
end
if err then say(err) self.remove() end