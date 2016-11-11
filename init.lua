-- basic_robot by rnd, 2016
basic_robot = {};
basic_robot.call_limit = 32; -- how many function calls per script execution allowed

basic_robot.data = {}; 
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
		ram = basic_robot.data[name].ram, -- "ram" - used to store variables
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
			left = function() commands.dig(name,1) end,
			right = function() commands.dig(name,2) end,
			forward = function() commands.dig(name,3) end,
			backward = function() commands.dig(name,4) end,
			down = function() commands.dig(name,6) end,
			up = function() commands.dig(name,5) end,
		},
		
		place = {
			left = function(nodename) commands.place(name,nodename, 1) end,
			right = function(nodename) commands.place(name,nodename, 2) end,
			forward = function(nodename) commands.place(name,nodename, 3) end,
			backward = function(nodename) commands.place(name,nodename, 4) end,
			down = function(nodename) commands.place(name,nodename, 6) end,
			up = function(nodename) commands.place(name,nodename, 5) end,
		},
		
		insert = { -- insert item from inventory into another inventory TODO
			forward = function(item, inventory) robot_insert(name,item, inventory,1) end,
			backward = function(item, inventory) robot_insert(name,item, inventory,2) end,
			down = function(item, inventory) robot_insert(name,item, inventory,3) end,
			up = function(item, inventory) robot_insert(name,item, inventory,4) end,
		},
		
		take = {}, -- take item from inventory TODO

		selfpos = function() return basic_robot.data[name].obj:getpos() end,
		
		find_nodes = 
			function(nodename,r) 
				if r>8 then return false end
				return (minetest.find_node_near(basic_robot.data[name].obj:getpos(), r, nodename)~=nil)
			end, -- in radius around position
		
		
		read_node = { -- returns node name
			left = function() return commands.read_node(name,1) end,
			right = function() return commands.read_node(name,2) end,
			forward = function() return commands.read_node(name,3) end,
			backward = function() return commands.read_node(name,4) end,
			down = function() return commands.read_node(name,6) end,
			up = function() return commands.read_node(name,5) end,
		},
		
		read_text = { -- returns node name
			left = function() return commands.read_text(name,1) end,
			right = function() return commands.read_text(name,2) end,
			forward = function() return commands.read_text(name,3) end,
			backward = function() return commands.read_text(name,4) end,
			down = function() return commands.read_text(name,6) end,
			up = function() return commands.read_text(name,5) end,
		},
		
		say  = function(text)
			minetest.chat_send_all("<robot ".. name .. "> " .. text)
		end,

		
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
		error = error,
		debug = debug,
		
		_ccounter = basic_robot.data[name].ccounter, -- counts how many function calls per execution of script
		
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
  local bad_code = {"repeat ", "until ", "_ccounter"}
	
  for _, v in pairs(bad_code) do
    if string.find(code, v) then
      return v .. " is not allowed!";
    end
  end

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
	
	while (i2) do -- PROCESS SCRIPT AND INSERT COUNTER AT PROBLEMATIC SPOTS
		i2 = nil;
		i2=string.find (script, "function", i1) -- fix functions
		
		if i2 then
			i2=string.find(script, ")", i2);
			if i2 then 
				script = script.sub(script,1, i2) .. insert_code .. script.sub(script, i2+1); 
				i1=i2+string.len(insert_code);
			end
		
		end
		
		i2=string.find (script, "for ", i1) -- fix for OK
		if i2 then
			i2=string.find(script, "do", i2);
			if i2 then 
				script = script.sub(script,1, i2+1) .. insert_code .. script.sub(script, i2+2); 
				i1=i2+string.len(insert_code);
			end
		
		end
		
		i2=string.find (script, "while ", i1) -- fix while OK
		if i2 then
			i2=string.find(script, "do", i2);
			if i2 then 
				script = script.sub(script,1, i2+1) .. insert_code .. script.sub(script, i2+2); 
				i1=i2+string.len(insert_code);
			end
		end
		
		i2=string.find (script, "goto ", i1) -- fix goto OK
		
		if i2 then
			script = script.sub(script,1, i2-1) .. insert_code .. script.sub(script, i2); 
			i1=i2+string.len(insert_code)+5; -- insert + skip goto
		end
		
	end

	--minetest.chat_send_all("script " .. script)
	--if true then return nil end
	
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


local function runSandbox( name)
    
	local ScriptFunc = basic_robot.data[name].bytecode;
	if not ScriptFunc then 
		return "Bytecode missing."
	end	
	
	basic_robot.data[name].ccounter = 0;
	setfenv( ScriptFunc, basic_robot.data[name].sandbox )
	
		local Result, RuntimeError = pcall( ScriptFunc )
		if RuntimeError then
			return RuntimeError
		end
	
		--minetest.chat_send_all("ccounter " .. basic_robot.data[name].ccounter)
    
    return nil
end



-- note: to see memory used by lua in kbytes: collectgarbage("count")
-- /spawnentity basic_robot:robot

-- TODO.. display form when right click robot
local function update_formspec_robot(self)
	
end


local robot_spawner_update_form = function (pos, mode)
	
	local meta = minetest.get_meta(pos);
	if not meta then return end
	local x0,y0,z0;
	x0=meta:get_int("x0");y0=meta:get_int("y0");z0=meta:get_int("z0"); -- direction of velocity
	local code = minetest.formspec_escape(meta:get_string("code"));
	
	local form  = 
	"size[8,6]" ..  -- width, height
	"textarea[0.1,0.75;8.4,6.5;code;code;".. code.."]"..
	"button_exit[-0.25,-0.25;1.5,1;spawn;START]"..
	"button[1.25,-0.25;1.5,1;despawn;STOP]"..
	"button[2.75,-0.25;1.5,1;inventory;inventory]"..
	"button[5.25,-0.25;1,1;help;help]"..
	"button_exit[6.25,-0.25;1,1;reset;clear]"..
	"button_exit[7.25,-0.25;1,1;OK;OK]";
	
	if mode ==1 then return form end
	meta:set_string("formspec",form)

end

local function init_robot(self)
	basic_robot.data[self.owner].obj = self.object; -- BUG: some problems with functions using object later??
	self.object:set_properties({infotext = "robot " .. self.owner});
	self.object:set_properties({nametag = "robot " .. self.owner,nametag_color = "LawnGreen"});
	initSandbox ( self.owner )
end

minetest.register_entity("basic_robot:robot",{
	energy = 1, 
	owner = "",
	hp_max = 10,
	code = "",
	timer = 0,
	timestep = 1, -- run every 1 second
	spawnpos = "",
	--visual="mesh",
	--mesh = "character.b3d",
	--textures={"character.png"},
	visual="cube",
	textures={"arrow.png","basic_machine_side.png","face.png","basic_machine_side.png","basic_machine_side.png","basic_machine_side.png"},
	
	visual_size={x=1,y=1},
	running = 0, -- does it run code or is it idle?	
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	physical=true,
		
	on_activate = function(self, staticdata)
		
		-- how to make it remember owner when it reactivates ?? staticdata seems to be empty
		
		self.object:set_armor_groups({fleshy=0})
		if staticdata~="" then -- reactivate robot
			
			self.owner = staticdata; -- remember its owner
			if not basic_robot.data[self.owner] then
				self.object:remove(); 
				minetest.chat_send_player(self.owner, "#ROBOT INIT:  error. spawn robot again.")
				return;
			end
			
			self.spawnpos = basic_robot.data[self.owner].spawnpos;
			init_robot(self);
			self.running = 1;
			
			local pos =  basic_robot.data[self.owner].spawnpos;
			local meta =  minetest.get_meta(pos);
			if meta then self.code = meta:get_string("code") end -- remember code
			
			return
		end
		
		-- init robot TODO: rewrite for less buggy
		minetest.after(0, 
		function() 
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
				self.object:remove();
			end
			
			return 
		end
		
		return
	end,
	
	 on_rightclick = function(self, clicker)
		local text = minetest.formspec_escape(self.code);
		local form = robot_spawner_update_form(self.spawnpos,1);
		
		minetest.show_formspec(clicker:get_player_name(), "robot_code", form);
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
		minetest.chat_send_player(owner,"#ROBOT ERROR : robot already active")
		return 
	end
	
	local obj = minetest.add_entity(pos,"basic_robot:robot");
	local luaent = obj:get_luaentity();
	luaent.owner = meta:get_string("owner");
	luaent.code = meta:get_string("code");
    luaent.spawnpos = {x=pos.x,y=pos.y-1,z=pos.z};
	-- note: 
	
end

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
	end,

	mesecons = {effector = {
		action_on = spawn_robot 
		}
	},
	
	on_receive_fields = function(pos, formname, fields, sender)
		
		local name = sender:get_player_name();
		if minetest.is_protected(pos,name) then return end
		
		if fields.reset then
			local meta = minetest.get_meta(pos);
			meta:set_string("code","");
			robot_spawner_update_form(pos);
			return
		end
		
		if fields.OK then
			local privs = minetest.get_player_privs(sender:get_player_name());
			local meta = minetest.get_meta(pos);
			--minetest.chat_send_all("form at " .. dump(pos) .. " fields " .. dump(fields))
			
			if fields.code then 
				local code = fields.code or "";
				meta:set_string("code", code)
			end
	
			robot_spawner_update_form(pos);
			return
		end
		
		if fields.help then 
			
			local text =  "BASIC LUA SYNTAX\n \nif CONDITION then BLOCK1 else BLOCK2 end \nmyTable1 = {1,2,3},  myTable2 = {[\"entry1\"]=5, [\"entry2\"]=1}\n"..
			"access table entries with myTable1[1] or myTable2.entry1 or myTable2[\"entry1\"]\n"..
			"\nROBOT COMMANDS\n\n"..
			"move.direction(), where direction is forward, backward, left,right, up, down\n"..
			"turn.left(), turn.right(), turn.angle(45)\n"..
			"dig.direction(), place.direction(\"default:dirt\")\nread_node.direction() tells you names of nodes\n"..
			"read_text.direction() reads text of signs, chests and other blocks\n"..
			"find_nodes(\"default:dirt\",3) is true if node can be found at radius 3 around robot, otherwise false\n"..
			"selfpos() returns table {x=pos.x,y=pos.y,z=pos.z}\n"..
			"say(\"hello\") will speak";
			
		
			text = minetest.formspec_escape(text);
			
			local form = "size [8,7] textarea[0,0;8.5,8.5;help;HELP;".. text.."]"
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
		
	end,
	
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
		if not meta:get_inventory():is_empty("main") then return false end
		return true
	end
	
})


minetest.register_craft({
	output = "basic_robot:spawner",
	recipe = {
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:stone", "default:steel_ingot", "default:stone"}
	}
})