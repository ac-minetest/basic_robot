-- basic_robot by rnd, 2016


basic_robot = {};
basic_robot.call_limit = 32; -- how many execution calls per script execution allowed
basic_robot.bad_inventory_blocks = {
	["craft_guide:sign_wall"] = true,
}
basic_robot.maxdig = 1; -- how many digs allowed per execution,  0 = unlimited



basic_robot.version = "11/26a";


basic_robot.data = {}; 
basic_robot.data.listening = {}; -- which robots listen to chat

--[[
[name] = {sandbox= .., bytecode = ..., ram = ..., obj = robot object,spawnpos=...} 
robot object = object of entity, used to manipulate movements and more
--]]



dofile(minetest.get_modpath("basic_robot").."/commands.lua")

-- SANDBOX for running lua code isolated and safely

function getSandboxEnv (name)
	local commands = basic_robot.commands;
	local env = 
	{
		pcall=pcall,
		move = { -- changes position of robot
			left = function() return commands.move(name,1) end,
			right = function() return commands.move(name,2) end,
			forward = function() return commands.move(name,3) end,
			backward = function() return commands.move(name,4) end,
			up = function() return commands.move(name,5) end,
			down = function() return commands.move(name,6) end,
		},
		
		turn = {
			left = function() commands.turn(name,math.pi/2) end,
			right = function() commands.turn(name,-math.pi/2) end,
			angle = function(angle) commands.turn(name,angle*math.pi/180) end,
		},
		
		dig = {
			left = function() return commands.dig(name,1) end,
			right = function() return commands.dig(name,2) end,
			forward = function() return commands.dig(name,3) end,
			backward = function() return commands.dig(name,4) end,
			down = function() return commands.dig(name,6) end,
			up = function() return commands.dig(name,5) end,
			forward_down = function() return commands.dig(name,7) end,
		},
		
		place = {
			left = function(nodename) return commands.place(name,nodename, 1) end,
			right = function(nodename) return commands.place(name,nodename, 2) end,
			forward = function(nodename) return commands.place(name,nodename, 3) end,
			backward = function(nodename) return commands.place(name,nodename, 4) end,
			down = function(nodename) return commands.place(name,nodename, 6) end,
			up = function(nodename) return commands.place(name,nodename, 5) end,
			forward_down = function(nodename) return commands.place(name,nodename, 7) end,
		},
		
		insert = { -- insert item from robot inventory into another inventory
			left = function(item, inventory) commands.insert_item(name,item, inventory,1) end,
			right = function(item, inventory) commands.insert_item(name,item, inventory,2) end,
			forward = function(item, inventory) commands.insert_item(name,item, inventory,3) end,
			backward = function(item, inventory) commands.insert_item(name,item, inventory,4) end,
			down = function(item, inventory) commands.insert_item(name,item, inventory,6) end,
			up = function(item, inventory) commands.insert_item(name,item, inventory,5) end,
		},
		
		take = { -- takes item from inventory and puts it in robot inventory
			left = function(item, inventory) commands.take_item(name,item, inventory,1) end,
			right = function(item, inventory) commands.take_item(name,item, inventory,2) end,
			forward = function(item, inventory) commands.take_item(name,item, inventory,3) end,
			backward = function(item, inventory) commands.take_item(name,item, inventory,4) end,
			down = function(item, inventory) commands.take_item(name,item, inventory,6) end,
			up = function(item, inventory) commands.take_item(name,item, inventory,5) end,
		
		}, -- take item from inventory TODO

		self = {
			pos = function() return basic_robot.data[name].obj:getpos() end,
			spawnpos = function() return basic_robot.data[name].spawnpos end,
			viewdir = function() local yaw = basic_robot.data[name].obj:getyaw(); return {x=math.cos(yaw), y = 0, z=math.sin(yaw)} end,
			
			listen = function (mode)
				if mode == 1 then 
					basic_robot.data.listening[name] = true
				else
					basic_robot.data.listening[name] = nil
				end
			end,
			
			listen_msg = function() 
				local msg = basic_robot.data[name].listen_msg;
				local speaker = basic_robot.data[name].listen_speaker;
				basic_robot.data[name].listen_msg = nil; 
				basic_robot.data[name].listen_speaker = nil; 
				return speaker,msg
			end,

			read_mail = function()
				local mail = basic_robot.data[name].listen_mail;
				local sender = basic_robot.data[name].listen_sender;
				basic_robot.data[name].listen_mail = nil; 
				basic_robot.data[name].listen_sender = nil; 
				return sender,mail
			end,
			
			send_mail = function(target,mail)
				if not basic_robot.data[target] then return false end
				basic_robot.data[target].listen_mail = mail; 
				basic_robot.data[target].listen_sender = name; 
			end,			
			
			remove = function()
				basic_robot.data[name].obj:remove();
				basic_robot.data[name].obj=nil;
			end,
			
			spam = function (mode) -- allow more than one msg per "say"
				if mode == 1 then 
					basic_robot.data[name].allow_spam = true
				else
					basic_robot.data[name].allow_spam = nil
				end
			end,
			
			fire = function(speed, pitch,gravity) -- experimental: fires an projectile
				local obj = basic_robot.data[name].obj;
				local pos = obj:getpos();
				local yaw = obj:getyaw();
				pitch = pitch*math.pi/180
				local velocity = {x=speed*math.cos(yaw)*math.cos(pitch), y=speed*math.sin(pitch),z=speed*math.sin(yaw)*math.cos(pitch)};
				-- fire particle
				-- minetest.add_particle(
				-- {
					-- pos = pos,
					-- expirationtime = 10,
					-- velocity = {x=speed*math.cos(yaw)*math.cos(pitch), y=speed*math.sin(pitch),z=speed*math.sin(yaw)*math.cos(pitch)},
					-- size = 5,
					-- texture = "default_apple.png",
					-- acceleration = {x=0,y=-gravity,z=0},
					-- collisiondetection = true,
					-- collision_removal = true,			
				-- }
				--);
				
				local obj = minetest.add_entity(pos, "basic_robot:projectile");
				if not obj then return end
				obj:setvelocity(velocity);
				obj:setacceleration({x=0,y=-gravity,z=0});
				local luaent = obj:get_luaentity();
				luaent.owner = name;
		
			end,
			
			fire_pos = function() 
				local fire_pos = basic_robot.data[name].fire_pos;
				basic_robot.data[name].fire_pos = nil; 
				return fire_pos
			end,
		},
		
		find_nodes = 
			function(nodename,r) 
				if r>8 then return false end
				return (minetest.find_node_near(basic_robot.data[name].obj:getpos(), r, nodename)~=nil)
			end, -- in radius around position
		
		find_player = 
			function(r) 
				if r>8 then return false end
				local objects =  minetest.get_objects_inside_radius(basic_robot.data[name].obj:getpos(), r);
				for _,obj in pairs(objects) do
					if obj:is_player() then return obj:get_player_name() end
				end
				return false
			end, -- in radius around position
		
		player = {
			getpos = function(name) 
				local player = minetest.get_player_by_name(name); 
				if player then return player:getpos() else return nil end 
			end,
			
		},
		
		attack = function(target) return basic_robot.commands.attack(name,target) end, -- attack player if nearby
		
		read_node = { -- returns node name
			left = function() return commands.read_node(name,1) end,
			right = function() return commands.read_node(name,2) end,
			forward = function() return commands.read_node(name,3) end,
			backward = function() return commands.read_node(name,4) end,
			down = function() return commands.read_node(name,6) end,
			up = function() return commands.read_node(name,5) end,
			forward_down = function() return commands.read_node(name,7) end,
		},
		
		read_text = { -- returns node name
			left = function(stringname) return commands.read_text(name,1,stringname	) end,
			right = function(stringname) return commands.read_text(name,2,stringname) end,
			forward = function(stringname) return commands.read_text(name,3,stringname) end,
			backward = function(stringname) return commands.read_text(name,4,stringname) end,
			down = function(stringname) return commands.read_text(name,6,stringname) end,
			up = function(stringname) return commands.read_text(name,5,stringname) end,
		},
		
		say = function(text)
			if not basic_robot.data[name].quiet_mode then
				minetest.chat_send_all("<robot ".. name .. "> " .. text)
				if not basic_robot.data[name].allow_spam then 
					basic_robot.data[name].quiet_mode=true
				end
			else
				minetest.chat_send_player(name,"<robot ".. name .. "> " .. text)
			end
		end,
		
		
		book = {
			read = function(i) 
				if i<=0 or i > 32 then return nil end
				local inv = minetest.get_meta(basic_robot.data[name].spawnpos):get_inventory();
				local itemstack = inv:get_stack("library", i);
				if itemstack then
					return commands.read_book(itemstack);
				else 
					return nil
				end
			end,
			
			write = function(i,text)
				if i<=0 or i > 32 then return nil end
				local inv = minetest.get_meta(basic_robot.data[name].spawnpos):get_inventory();
				local stack = basic_robot.commands.write_book(name,text);
				if stack then inv:set_stack("library", i, stack) end
			end
		},
		
		code = {
			set = function(text) -- replace bytecode in sandbox with this
				local err = commands.setCode( name, text ); -- compile code
				if err then
					minetest.chat_send_player(name,"#ROBOT CODE COMPILATION ERROR : " .. err) 
					local obj = basic_robot.data[name].obj;
					obj:remove();
					basic_robot.data[name].obj = nil;
					return
				end
			end,
			
			run = function(script)
				local ScriptFunc, CompileError = loadstring( script )
				if CompileError then
					minetest.chat_send_player(name, "#code.run: compile error " .. CompileError )
					return false
				end
			
				setfenv( ScriptFunc, basic_robot.data[name].sandbox )
			
				local Result, RuntimeError = pcall( ScriptFunc );
				if RuntimeError then
					minetest.chat_send_player(name, "#code.run: run error " .. RuntimeError )
					return false
				end
				return true
			end
		},
		
		string = {
			byte = string.byte,	char = string.char,
			find = string.find,
			format = string.format,	gsub = string.gsub,
			len = string.len, lower = string.lower,
			upper = string.upper, rep = string.rep,
			reverse = string.reverse, sub = string.sub,
		},
		math = {
			abs = math.abs,	acos = math.acos,
			asin = math.asin, atan = math.atan,
			atan2 = math.atan2,	ceil = math.ceil,
			cos = math.cos,	cosh = math.cosh,
			deg = math.deg,	exp = math.exp,
			floor = math.floor,	fmod = math.fmod,
			frexp = math.frexp,	huge = math.huge,
			ldexp = math.ldexp,	log = math.log,
			log10 = math.log10,	max = math.max,
			min = math.min,	modf = math.modf,
			pi = math.pi, pow = math.pow,
			rad = math.rad,	random = math.random,
			sin = math.sin,	sinh = math.sinh,
			sqrt = math.sqrt, tan = math.tan,
			tanh = math.tanh,
			},
		table = {
			concat = table.concat,
			insert = table.insert,
			maxn = table.maxn,
			remove = table.remove,
			sort = table.sort,
		},
		os = {
			clock = os.clock,
			difftime = os.difftime,
			time = os.time,
			
		},
		
		tonumber = tonumber,
		pairs = pairs,
		ipairs = ipairs,
		error = error,
		debug = debug,
		
		_ccounter = basic_robot.data[name].ccounter, -- counts how many executions of critical spots in script
		
		increase_ccounter = 
		function() 
			local _ccounter = basic_robot.data[name].ccounter;
			if _ccounter > basic_robot.call_limit then
				error("Execution limit " .. basic_robot.call_limit .. " exceeded");
			end
			basic_robot.data[name].ccounter = _ccounter + 1;
		end,
	};
	env._G = env;
	return env	
end


local function check_code(code)
  
  --"while ", "for ", "do ","goto ", 
  local bad_code = {"repeat ", "until ", "_ccounter", "_G", "while%(", "while{", "pcall","\\\""}
	
  for _, v in pairs(bad_code) do
    if string.find(code, v) then
      return v .. " is not allowed!";
    end
  end

end


local function is_inside_string(pos,script)
	local i1=string.find (script, "\"", 1);
	if not i1 then 
		return false 
	end
	local i2=0;
	local par = 1;

	if pos<i1 then 
		return false 
	end
	while i1 do
		i2=string.find(script,"\"",i1+1);
		if i2 then
			par = 1 - par;
		end
		if par == 0 then
			if i1<pos and pos<i2 then 
				return true 
			end
		end
		i1=i2;  
	end
	return false;
end


local function CompileCode ( script )
   
	--[[ idea: in each local a = function (args) ... end insert counter like:
	local a = function (args) counter() ... end 
	when counter exceeds limit exit with error
	--]]
	
	
	script="_ccounter = 0; " .. script;
	
	local i1 -- process script to insert call counter in every function
	local insert_code = " increase_ccounter(); ";

	local i1=0; local i2 = 0; 
	local found = true;
	
	while (found) do -- PROCESS SCRIPT AND INSERT COUNTER AT PROBLEMATIC SPOTS
		
		found = false;
		i2 = nil;

		i2=string.find (script, "while ", i1) -- fix while OK
		if i2 then
			--minetest.chat_send_all("while0");
			if not is_inside_string(i2,script) then
				local i21 = i2;
				i2=string.find(script, "do ", i2);
				if i2 then 
					script = script.sub(script,1, i2+1) .. insert_code .. script.sub(script, i2+2); 
					i1=i21+6; -- after while
					found = true;
				end
			end
		end
		
		i2=string.find (script, "function", i1) -- fix functions
		if i2 then
			--minetest.chat_send_all("func0")
			if not is_inside_string(i2,script) then
				i2=string.find(script, ")", i2);
				if i2 then 
					script = script.sub(script,1, i2) .. insert_code .. script.sub(script, i2+1); 
					i1=i2+string.len(insert_code);
					found = true;
				end
			end
		
		end
		
		i2=string.find (script, "for ", i1) -- fix for OK
		if i2 then
			if not is_inside_string(i2,script) then
				i2=string.find(script, "do ", i2);
				if i2 then 
					script = script.sub(script,1, i2+1) .. insert_code .. script.sub(script, i2+2); 
					i1=i2+string.len(insert_code);
					found = true;
				end
			end
		end
		
		
		i2=string.find (script, "goto ", i1) -- fix goto OK
		if i2 then
			if not is_inside_string(i2,script) then
				script = script.sub(script,1, i2-1) .. insert_code .. script.sub(script, i2); 
				i1=i2+string.len(insert_code)+5; -- insert + skip goto
				found = true;
			end
		end
		--minetest.chat_send_all("code rem " .. string.sub(script,i1))
		
	end
	
	--minetest.chat_send_all(script)
	--if true then return nil, "" end
	
	local ScriptFunc, CompileError = loadstring( script )
	if CompileError then
        return nil, CompileError
    end
	return ScriptFunc, nil
end

local function initSandbox ( name )
	basic_robot.data[name].sandbox = getSandboxEnv (name);
end

local function setCode( name, script ) -- to run script: 1. initSandbox 2. setCode 3. runSandbox
	local err;
	err = check_code(script);
	if err then return err end

	local bytecode, err = CompileCode ( script );
	if err then return err end
	basic_robot.data[name].bytecode = bytecode;
	return nil
end

basic_robot.commands.setCode=setCode; -- so we can use it

local function runSandbox( name)
    
	local ScriptFunc = basic_robot.data[name].bytecode;
	if not ScriptFunc then 
		return "Bytecode missing."
	end	
	
	basic_robot.data[name].ccounter = 0;
	basic_robot.data[name].digcount = 1;
	
	setfenv( ScriptFunc, basic_robot.data[name].sandbox )
	
		local Result, RuntimeError = pcall( ScriptFunc )
		if RuntimeError then
			return RuntimeError
		end
    
    return nil
end

-- note: to see memory used by lua in kbytes: collectgarbage("count")


local robot_spawner_update_form = function (pos, mode)
	
	if not pos then return end
	local meta = minetest.get_meta(pos);
	if not meta then return end
	local x0,y0,z0;
	x0=meta:get_int("x0");y0=meta:get_int("y0");z0=meta:get_int("z0"); -- direction of velocity
	local code = minetest.formspec_escape(meta:get_string("code"));
	local form;
	
	if mode ~= 1 then 
		form  = 
		"size[9.5,6]" ..  -- width, height
		"textarea[1.25,-0.25;8.75,7.6;code;;".. code.."]"..
		"button_exit[-0.25,-0.25;1.25,1;OK;SAVE]"..
		"button_exit[-0.25, 0.75;1.25,1;spawn;START]"..
		     "button[-0.25, 1.75;1.25,1;despawn;STOP]"..
			 "button[-0.25, 3.6;1.25,1;inventory;storage]"..
		     "button[-0.25, 4.6;1.25,1;library;library]"..
		     "button[-0.25, 5.6;1.25,1;help;help]";
	else
		form  = 
		"size[9.5,6]" ..  -- width, height
		"textarea[1.25,-0.25;8.75,7.6;code;;".. code.."]"..
		"button_exit[-0.25,-0.25;1.25,1;OK;SAVE]"..
		     "button[-0.25, 1.75;1.25,1;despawn;STOP]"..
			 "button[-0.25, 3.6;1.25,1;inventory;storage]"..
		     "button[-0.25, 4.6;1.25,1;library;library]"..
		     "button[-0.25, 5.6;1.25,1;help;help]";
	end
		
	if mode ==1 then return form end
	meta:set_string("formspec",form)

end

local function init_robot(self)
	
	
	basic_robot.data[self.owner].obj = self.object; -- BUG: some problems with functions using object later??
	basic_robot.data.listening[self.owner] = nil -- dont listen at beginning
	basic_robot.data[self.owner].quiet_mode = false;
	
	self.object:set_properties({infotext = "robot " .. self.owner});
	self.object:set_properties({nametag = "robot " .. self.owner,nametag_color = "LawnGreen"});
	self.object:set_armor_groups({fleshy=0})
	
	initSandbox ( self.owner )
end

minetest.register_entity("basic_robot:robot",{
	energy = 1, 
	owner = "",
	hp_max = 10,
	code = "",
	timer = 0,
	timestep = 1, -- run every 1 second
	spawnpos = nil,
	--visual="mesh",
	--mesh = "char.obj", --this is good: aligned and rotated in blender - but how to move nametag up? now is stuck in head
	--textures={"character.png"},
	
	visual="cube",
	textures={"arrow.png","basic_machine_side.png","face.png","basic_machine_side.png","basic_machine_side.png","basic_machine_side.png"},
	
	visual_size={x=1,y=1},
	running = 0, -- does it run code or is it idle?	
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	physical=true,
		
	on_activate = function(self, staticdata)

		
		-- reactivate robot
		if staticdata~="" then 
			
			self.owner = staticdata; -- remember its owner
			if not basic_robot.data[self.owner] then
				minetest.chat_send_player(self.owner, "#ROBOT INIT:  error. spawn robot again.")
				self.object:remove(); 
				return;
			end
			
			self.spawnpos = {x=basic_robot.data[self.owner].spawnpos.x,y=basic_robot.data[self.owner].spawnpos.y,z=basic_robot.data[self.owner].spawnpos.z};
			init_robot(self);
			self.running = 1;
			
			local pos =  basic_robot.data[self.owner].spawnpos;
			local meta =  minetest.get_meta(pos);
			if meta then self.code = meta:get_string("code") end -- remember code
			if not self.code or self.code == "" then
				minetest.chat_send_player(self.owner, "#ROBOT INIT:  no code found")
				self.object:remove(); 
			end
			
			return
		end
		
		-- init robot TODO: rewrite for less buggy
		minetest.after(0, -- so that stuff with spawner is initialized before
		function() 
			
			if not self.spawnpos then self.object:remove() return end
			
			if not basic_robot.data[self.owner] then
				basic_robot.data[self.owner] = {};
			end
			
			basic_robot.data[self.owner].spawnpos  = {x=self.spawnpos.x,y=self.spawnpos.y,z=self.spawnpos.z};
			init_robot(self); -- set properties, init sandbox
			
			local err = setCode( self.owner, self.code ); -- compile code
			if err then
				minetest.chat_send_player(self.owner,"#ROBOT CODE COMPILATION ERROR : " .. err) 
				self.running = 0; -- stop execution
			
				self.object:remove();
				basic_robot.data[self.owner].obj = nil;
				return
			end
			
			self.running = 1
			
		end
		)
		
	end,
	
	get_staticdata = function(self)
		return self.owner;
	end,
	
	on_punch = function (self, puncher, time_from_last_punch, tool_capabilities, dir)
		
	end,
	
	on_step = function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer>self.timestep and self.running == 1 then 
			self.timer = 0;
			local err = runSandbox(self.owner);
			if err then 
				minetest.chat_send_player(self.owner,"#ROBOT ERROR : " .. err) 
				self.running = 0; -- stop execution
				
				if string.find(err,"stack overflow") then -- remove stupid player privs and spawner, ban player ip
					local owner = self.owner;
					local pos = basic_robot.data[owner].spawnpos;
					minetest.set_node(pos, {name = "air"});
				
					local privs = core.get_player_privs(owner);privs.interact = false; 
					
					core.set_player_privs(owner, privs); minetest.auth_reload()
					minetest.ban_player(owner)
					
				end
				
				local owner = self.owner;
				local pos = basic_robot.data[owner].spawnpos;
			
				if not basic_robot.data[owner] then return end
				if basic_robot.data[owner].obj then
					basic_robot.data[owner].obj = nil;
				end
				
				self.object:remove();
			end
			return 
		end
		
		return
	end,
	
	 on_rightclick = function(self, clicker)
		local text = minetest.formspec_escape(self.code);
		local form = robot_spawner_update_form(self.spawnpos,1);
		
		minetest.show_formspec(clicker:get_player_name(), "robot_worker_" .. self.owner, form);
	 end,
})


local spawn_robot = function(pos,node,ttl)
	if ttl<0 then return end
	
	local meta = minetest.get_meta(pos);
	local t0 = meta:get_int("t");
	local t1 = minetest.get_gametime(); 
	local T = meta:get_int("T"); -- temperature
	
	if t0>t1-2 then -- activated before natural time
		T=T+1;
	else
		if T>0 then 
			T=T-1 
			if t1-t0>5 then T = 0 end
		end
	end
	meta:set_int("T",T);
	meta:set_int("t",t1); -- update last activation time
	
	if T > 2 then -- overheat
			minetest.sound_play("default_cool_lava",{pos = pos, max_hear_distance = 16, gain = 0.25})
			meta:set_string("infotext","overheat: temperature ".. T)
			return
	end

	-- spawn robot on top
	pos.y=pos.y+1;
	local owner = meta:get_string("owner")
	
	-- if robot already exists do nothing
	if basic_robot.data[owner] and basic_robot.data[owner].obj then
		minetest.chat_send_player(owner,"#ROBOT: robot already active, removing")
		basic_robot.data[owner].obj:remove();
		basic_robot.data[owner].obj = nil;
	end
	
	local obj = minetest.add_entity(pos,"basic_robot:robot");
	local luaent = obj:get_luaentity();
	luaent.owner = meta:get_string("owner");
	luaent.code = meta:get_string("code");
    luaent.spawnpos = {x=pos.x,y=pos.y-1,z=pos.z};
	-- note: 
	
end


local on_receive_robot_form = function(pos, formname, fields, sender)
		
		local name = sender:get_player_name();
		if minetest.is_protected(pos,name) then return end
		
		if fields.reset then
			local meta = minetest.get_meta(pos);
			meta:set_string("code","");
			robot_spawner_update_form(pos);
			return
		end
		
		if fields.OK then
			
			local meta = minetest.get_meta(pos);
			
			if fields.code then 
				local code = fields.code or "";
				meta:set_string("code", code)
			end
	
			robot_spawner_update_form(pos);
			return
		end
		
		if fields.help then 
			
			local text =  "BASIC LUA SYNTAX\n \nif x==1 then do_something else do_something_else end"..
			"\nfor i = 1, 5 do something end \nwhile i<6 do something; i=i+1; end\n"..
			"\narrays: myTable1 = {1,2,3},  myTable2 = {[\"entry1\"]=5, [\"entry2\"]=1}\n"..
			"access table entries with myTable1[1] or myTable2.entry1 or myTable2[\"entry1\"]\n \n"..
			"ROBOT COMMANDS\n \n"..
			"**MOVEMENT,DIGGING, PLACING, INVENTORY TAKE/INSERT\nmove.direction(), where direction is forward, backward, left,right, up, down)\n"..
			"forward_down direction only works with dig, place and read_node\n"..
			"turn.left(), turn.right(), turn.angle(45)\n"..
			"dig.direction()\n place.direction(\"default:dirt\")\nread_node.direction() tells you names of nodes\n"..
			"insert.direction(item, inventory) inserts item from robot inventory to target inventory\n"..
			"take.direction(item, inventory) takes item from target inventory into robot inventory\n"..
			"read_text.direction(stringname) reads text of signs, chests and other blocks, optional stringname for other meta\n"..
			"**BOOKS/CODE\nbook.read(i) returns contents of book at i-th position in library \nbook.write(i,text) writes book at i-th position\n"..
			"code.run(text) compiles and runs the code in sandbox\n"..
			"code.set(text) replaces current bytecode of robot\n"..
			"find_nodes(\"default:dirt\",3) is true if node can be found at radius 3 around robot, otherwise false\n"..
			"**PLAYERS\n"..
			"find_player(3) finds player and returns his name in radius 3 around robot, if not returns false\n"..
			"attack(target) attempts to attack target player if nearby \n"..
			"player.getpos(name) return position of player, player.connected() returns list of players\n"..
			"**ROBOT\n"..
			"say(\"hello\") will speak\n"..
			"self.listen(0/1) (de)attaches chat listener to robot\n"..
			"speaker, msg = self.listen_msg() retrieves last chat message if robot listens\n"..
			"self.send_mail(target,mail) sends mail to target robot\n"..
			"sender,mail = read_mail() reads mail, if any\n" ..
			"self.pos() returns table {x=pos.x,y=pos.y,z=pos.z}\n"..
			"self.spam(0/1) (dis)enable message repeat to all\n"..
			"self.remove() removes robot\n"..
			"self.spawnpos() returns position of spawner block\n"..
			"self.viewdir() returns vector of view for robot\n"..
			"self.fire(speed, pitch,gravity) fires a projectile from robot\n"..
			"self.fire_pos() returns last hit position\n ";
		
			text = minetest.formspec_escape(text);
			
			--local form = "size [8,7] textarea[0,0;8.5,8.5;help;HELP;".. text.."]"
			
			--textlist[X,Y;W,H;name;listelem 1,listelem 2,...,listelem n]
			local list = "";
			for word in string.gmatch(text, "(.-)\r?\n+") do list = list .. word .. ", " end
			local form = "size [8,8] textlist[-0.25,-0.25;8.25,8.5;help;" .. list .. "]"
			minetest.show_formspec(sender:get_player_name(), "robot_help", form);
			
			return
		end
		
		if fields.spawn then
			spawn_robot(pos,0,0);
			return
		end
		
		if fields.despawn then
			
			local meta = minetest.get_meta(pos);
			local owner = meta:get_string("owner");
			
			if not basic_robot.data[owner] then return end
			if basic_robot.data[owner].obj then
				basic_robot.data[owner].obj:remove();
				basic_robot.data[owner].obj = nil;
			end
			return
		end
		
		if fields.inventory then
			local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z ;
			local form  = 
			"size[8,8]" ..  -- width, height
			"list["..list_name..";main;0.,0;8,4;]"..
			"list[current_player;main;0,4.25;8,4;]";
			minetest.show_formspec(sender:get_player_name(), "robot_inventory", form);
		end
		
		if fields.library then
			local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z ;
			local form  = 
			"size[8,8]" ..  -- width, height
			"list["..list_name..";library;0.,0;8,4;]"..
			"list[current_player;main;0,4.25;8,4;]";
			minetest.show_formspec(sender:get_player_name(), "robot_inventory", form);
		end
		
	end

-- handle form when rightclicking robot entity
minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		
		local robot_formname = "robot_worker_";
		if string.find(formname,robot_formname) then
			local name = string.sub(formname, string.len(robot_formname)+1);
			local sender = minetest.get_player_by_name(name);
			
			if basic_robot.data[name] and basic_robot.data[name].spawnpos then
				local pos = basic_robot.data[name].spawnpos;
				
				local privs = minetest.get_player_privs(player:get_player_name());
				local is_protected = minetest.is_protected(pos, player:get_player_name());
				if is_protected and not privs.privs then return 0 end 
				
				if not sender then 
					on_receive_robot_form(pos,formname, fields, player)
				else
					on_receive_robot_form(pos,formname, fields, sender)
				end
				
				return
			end
		end
		
		local robot_formname = "robot_control_";
		if string.find(formname,robot_formname) then
			local name = string.sub(formname, string.len(robot_formname)+1);
			local sender = minetest.get_player_by_name(name); if not sender then return end
			if fields.OK and fields.code then
				local item = sender:get_wielded_item(); --set_wielded_item(item)
				item:set_metadata(fields.code);
				sender:set_wielded_item(item);
			end
			return
		end
		
		local robot_formname = "robot_manual_control_";
		if string.find(formname,robot_formname) then
			local name = string.sub(formname, string.len(robot_formname)+1);
			local sender = minetest.get_player_by_name(name); if not sender then return end
			local commands = basic_robot.commands;
			
			if fields.turnleft then
				pcall(function () commands.turn(name,math.pi/2) end)
			elseif fields.turnright then
				pcall(function () commands.turn(name,-math.pi/2) end)
			elseif fields.forward then
				pcall(function () commands.move(name,3) end)
			elseif fields.back then
				pcall(function () commands.move(name,4) end)
			elseif fields.left then
				pcall(function () commands.move(name,1) end)
			elseif fields.right then
				pcall(function () commands.move(name,2) end)
			elseif fields.dig then
				pcall(function () basic_robot.data[name].digcount = 1; commands.dig(name,3) end)
			elseif fields.up then
				pcall(function () commands.move(name,5) end)
			elseif fields.down then
				pcall(function () commands.move(name,6) end)
			elseif fields.digdown then
				pcall(function () basic_robot.data[name].digcount = 1; commands.dig(name,6) end)
			elseif fields.digup then
				pcall(function () basic_robot.data[name].digcount = 1; commands.dig(name,5) end)
			end
			return
		end
		
	end
)

-- handle chats
minetest.register_on_chat_message(
function(name, message)
	local listeners = basic_robot.data.listening;
	for pname,_ in pairs(listeners) do
		basic_robot.data[pname].listen_msg = message;
		basic_robot.data[pname].listen_speaker = name;
	end
end
)


minetest.register_node("basic_robot:spawner", {
	description = "Spawns robot",
	tiles = {"cpu.png"},
	groups = {oddly_breakable_by_hand=2,mesecon_effector_on = 1},
	drawtype = "allfaces",
	paramtype = "light",
	param1=1,
	walkable = true,
	alpha = 150,
	after_place_node = function(pos, placer)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("owner", placer:get_player_name()); 
		local privs = minetest.get_player_privs(placer:get_player_name()); if privs.privs then meta:set_int("admin",1) end
	
		meta:set_string("code","");
		meta:set_string("infotext", "robot spawner (owned by ".. placer:get_player_name() .. ")")
		robot_spawner_update_form(pos);

		local inv = meta:get_inventory(); -- spawner inventory
		inv:set_size("main",32);
		inv:set_size("library",32);
	end,

	mesecons = {effector = {
		action_on = spawn_robot 
		}
	},
	
	on_receive_fields = on_receive_robot_form,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return 0 end 
		return stack:get_count();
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return 0 end 
		return stack:get_count();
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0;
	end,
	
	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then return false end 
		local meta = minetest.get_meta(pos);
		if not meta:get_inventory():is_empty("main") or not meta:get_inventory():is_empty("library") then return false end
		return true
	end
	
})


local get_manual_control_form = function(name)
	local form = 
			"size[2.5,3]" ..  -- width, height
			"button[-0.25,-0.25;1.,1;turnleft;TLeft]"..
			"button[0.75,-0.25;1.,1;forward;GO]"..
			"button[1.75,-0.25;1.,1;turnright;TRight]"..
			"button[-0.25,0.75;1.,1;left;LEFT]"..
			"button[0.75,0.75;1.,1;dig;DIG]"..
			"button[1.75,0.75;1.,1;right;RIGHT]"..
			
			"button[-0.25,1.75;1.,1;down;DOWN]"..
			"button[0.75,1.75;1.,1;back;BACK]"..
			"button[1.75,1.75;1.,1;up;UP]"..
			
			"button[-0.25,2.65;1.,1;digdown;DDown]"..
			"button[1.75,2.65;1.,1;digup;DUp]";
			
	return form;
end


-- remote control
minetest.register_craftitem("basic_robot:control", {
	description = "Robot remote control",
	inventory_image = "control.png",
	groups = {book = 1, not_in_creative_inventory = 1},
	stack_max = 1,
	
	on_secondary_use = function(itemstack, user, pointed_thing)
		
			local name = user:get_player_name();
			local code = minetest.formspec_escape(itemstack:get_metadata());
			local form = 
			"size[9.5,1]" ..  -- width, height
			"textarea[1.25,-0.25;8.75,3;code;;".. code.."]"..
			"button_exit[-0.25,-0.25;1.25,1;OK;SAVE]";
			minetest.show_formspec(name, "robot_control_" .. name, form);
			return
	end,
	
	on_use = function(itemstack, user, pointed_thing)
		
		local name = user:get_player_name();
		
		if basic_robot.data[name] and basic_robot.data[name].sandbox then
			
		else
			minetest.chat_send_player(name, "#remote control: your robot must be running");
			return
		end
		
		local t0 = basic_robot.data[name].remoteuse or 0; -- prevent too fast remote use
		local t1 = minetest.get_gametime();
		if t1-t0<1 then return end
		basic_robot.data[name].remoteuse = t1;
		
		
		script = itemstack:get_metadata();
		if script == "" then
			--display control form
			minetest.show_formspec(name, "robot_manual_control_" .. name, get_manual_control_form(name));
			return
		end
		
		
		local ScriptFunc, CompileError = loadstring( script )
		if CompileError then
			minetest.chat_send_player(name, "#remote control: compile error " .. CompileError )
			return
		end
		
		setfenv( ScriptFunc, basic_robot.data[name].sandbox )
		
		local Result, RuntimeError = pcall( ScriptFunc );
		if RuntimeError then
			minetest.chat_send_player(name, "#remote control: run error " .. RuntimeError )
			return
		end
	end,
})


minetest.register_entity(
	"basic_robot:projectile",
	{
		hp_max = 1,
		physical = true,
		collide_with_objects = true,
		weight = 5,
		collisionbox = {-0.15,-0.15,-0.15, 0.15,0.15,0.15},
		visual ="sprite",	
		visual_size = {x=0.5, y=0.5},
		textures = {"default_diamond_block.png"},
		is_visible = true,
		oldvel = {x=0,y=0,z=0},
		owner = "",

		--on_activate = function(self, staticdata)
		--		self.object:remove()
		--end,

		--get_staticdata = function(self)
		--	return nil
		--end,

		on_step = function(self, dtime)
			local vel = self.object:getvelocity();
			if (self.oldvel.x~=0 and vel.x==0) or (self.oldvel.y~=0 and vel.y==0) or (self.oldvel.z~=0 and vel.z==0) then
				if basic_robot.data[self.owner] then
					basic_robot.data[self.owner].fire_pos = self.object:getpos();
				end
				self.object:remove()
				return
			end
			self.oldvel = vel;
			
			end
})

minetest.register_craft({
	output = "basic_robot:control",
	recipe = {
		{"default:stick"},
		{"default:mese_crystal"}
	}
})

minetest.register_craft({
	output = "basic_robot:spawner",
	recipe = {
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:stone", "default:steel_ingot", "default:stone"}
	}
})