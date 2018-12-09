--[[
SWITCHING GAME by rnd, 2018

lights:
0110

switches, each one toggles certain lights like: s1 1001 (toggles light with 1)

PROBLEM:
hit switches in correct order to turn on all lights

GENERATE RANDOM CHALLENGE: 
start with all lights on and apply random sequence of switches

TODO: instead of simply 0/1 switches have ones that advance +1 mod p (p can be say 3 or more)


REMARKS: application of 2 different switches is commutative ( obvious, since just x->x+1 mod p)
--]]
if not init then

init = true 
numlights = 2;
numswitches = 2;
states = 10;

lights = {};  -- states of lights, initialy 1,1,...,1
for i = 1, numlights do lights[i] = 0 end 
switches = {}

--switches = {{1,0,0,1},{1,1,1,1}};
make_random_switches = function(lights, switches,count)
	for i = 1, count do
		switches[i] = {};
		local switch =  switches[i];
		for j = 1, #lights do switch[j] = math.random(states)-1 end
	end
end
make_random_switches(lights,switches, numswitches)


pos = self.spawnpos(); pos.x = pos.x + 1;-- pos.z = pos.z + 1

apply_switch = function(switches,lights,idx)
	local switch = switches[idx];
	for i = 1, #switch do
		local state = lights[i] + switch[i];
		if state >= states then state = state - states end
		lights[i] = state
	end
end

randomize = function(switches, lights, steps) -- randomize lights
	for i = 1, steps do
		local idx = math.random(#switches);
		apply_switch(switches,lights,idx);
	end
end

render_lights = function() for i = 1, #lights do keyboard.set({x=pos.x+i-1,y=pos.y+1, z=pos.z}, 7+lights[i]) end end
render_switches = function(mode) 
	if mode then 
		for i = 1, #switches do keyboard.set({x=pos.x+i-1,y=pos.y, z=pos.z}, 1+i) end 
	else
		for i = 1, #switches do keyboard.set({x=pos.x+i-1,y=pos.y, z=pos.z}, 0) end 
	end
end

check_lights = function()
	for i = 1, #lights do if lights[i] ~= 0 then return false end end
	return true
end
step = 0

randomize(switches,lights, math.min((#switches)^states,10000))
if check_lights() then randomize(switches,lights, #switches + states) end

render_lights(); render_switches(true)


self.label("GOAL OF GAME: punch buttons with numbers in correct order to turn all blocks to 0")

--self.label(serialize(switches))
end


event = keyboard.get()
if event then
	local idx = event.x-pos.x+1;
	if event.y==pos.y and idx>=1 and idx <= #switches then
		apply_switch(switches, lights, idx)
		render_lights()
		step = step + 1
		if check_lights() then 
			self.label("DONE IN " .. step .. " STEPS !") 
			render_switches(false)
		else 
			self.label("STEP " .. step) 
		end
	end
end