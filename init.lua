-- basic_robot by rnd, 2016


basic_robot = {};
----  SETTINGS  ------
basic_robot.call_limit = 48; -- how many execution calls per script run allowed

basic_robot.bad_inventory_blocks = { -- disallow taking from these nodes inventories
	["craft_guide:sign_wall"] = true,
}
basic_robot.maxoperations = 1; -- how many operations (dig, generate energy,..) available per run,  0 = unlimited
basic_robot.dig_require_energy = true; -- does robot require energy to dig?
----------------------



basic_robot.version = "06/18a";

basic_robot.data = {}; -- stores all robot data
--[[
[name] = { sandbox= .., bytecode = ..., ram = ..., obj = robot object,spawnpos=...} 
robot object = object of entity, used to manipulate movements and more
--]]
basic_robot.ids = {}; -- stores maxid for all players 
--[name] = {id = .., maxid = .. }, current id, how many robot ids player can use

basic_robot.data.listening = {}; -- which robots listen to chat
dofile(minetest.get_modpath("basic_robot").."/commands.lua")

local check_code, preprocess_code,is_inside_string;



-- SANDBOX for running lua code isolated and safely

function getSandboxEnv (name)
	
	local commands = basic_robot.commands;
	local env = 
	{
		pcall=pcall,
		robot_version = function() return basic_robot.version end,
		
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
			left = function(nodename, param2) return commands.place(name,nodename, param2, 1) end,
			right = function(nodename, param2) return commands.place(name,nodename, param2, 2) end,
			forward = function(nodename, param2) return commands.place(name,nodename, param2, 3) end,
			backward = function(nodename, param2) return commands.place(name,nodename, param2, 4) end,
			down = function(nodename, param2) return commands.place(name,nodename, param2, 6) end,
			up = function(nodename, param2) return commands.place(name,nodename, param2, 5) end,
			forward_down = function(nodename, param2) return commands.place(name,nodename, param2, 7) end,
		},
		
		insert = { -- insert item from robot inventory into another inventory
			left = function(item, inventory) return commands.insert_item(name,item, inventory,1) end,
			right = function(item, inventory) return commands.insert_item(name,item, inventory,2) end,
			forward = function(item, inventory) return commands.insert_item(name,item, inventory,3) end,
			backward = function(item, inventory) return commands.insert_item(name,item, inventory,4) end,
			down = function(item, inventory) return commands.insert_item(name,item, inventory,6) end,
			up = function(item, inventory) return commands.insert_item(name,item, inventory,5) end,
			forward_down = function(item, inventory) return commands.insert_item(name,item, inventory,7) end,
		},
		
		take = { -- takes item from inventory and puts it in robot inventory
			left = function(item, inventory) return commands.take_item(name,item, inventory,1) end,
			right = function(item, inventory) return commands.take_item(name,item, inventory,2) end,
			forward = function(item, inventory) return commands.take_item(name,item, inventory,3) end,
			backward = function(item, inventory) return commands.take_item(name,item, inventory,4) end,
			down = function(item, inventory) return commands.take_item(name,item, inventory,6) end,
			up = function(item, inventory) return commands.take_item(name,item, inventory,5) end,
			forward_down = function(item, inventory) return commands.take_item(name,item, inventory,7) end,
		
		},
		check_inventory = {
			left = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,1) end,
			right = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,2) end,
			forward = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,3) end,
			backward = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,4) end,
			down = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,6) end,
			up = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,5) end,
			forward_down = function(item, inventory,i) return commands.check_inventory(name,itemname, inventory,i,7) end,
			self = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,0) end,
		},
		
		activate = {
			left = function(mode) return commands.activate(name,mode, 1) end,
			right = function(mode) return commands.activate(name,mode, 2) end,
			forward = function(mode) return commands.activate(name,mode, 3) end,
			backward = function(mode) return commands.activate(name,mode, 4) end,
			down = function(mode) return commands.activate(name,mode, 6) end,
			up = function(mode) return commands.activate(name,mode, 5) end,
			forward_down = function(mode) return commands.activate(name,mode, 7) end,
		},
		
		pickup = function(r) -- pick up items around robot
			return commands.pickup(r, name);
		end,
		
		craft = function(item, mode)
			return commands.craft(item, mode, name)
		end,
		
		self = {
			pos = function() return basic_robot.data[name].obj:getpos() end,
			spawnpos = function() local pos = basic_robot.data[name].spawnpos; return {x=pos.x,y=pos.y,z=pos.z} end,
			name = function() return name end,
			viewdir = function() local yaw = basic_robot.data[name].obj:getyaw(); return {x=math.cos(yaw), y = 0, z=math.sin(yaw)} end,
			
			skin = function(textures) 
				local obj = basic_robot.data[name].obj;
				obj:set_properties({textures=textures});
			end,
			
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
			
			read_form = function()
				local fields = basic_robot.data[name].read_form;
				local sender = basic_robot.data[name].form_sender;
				basic_robot.data[name].read_form = nil; 
				basic_robot.data[name].form_sender = nil; 
				return sender,fields
			end,
			
			show_form = function(playername, form)
				commands.show_form(name, playername, form)
			end,
			
			send_mail = function(target,mail)
				if not basic_robot.data[target] then return false end
				basic_robot.data[target].listen_mail = mail; 
				basic_robot.data[target].listen_sender = name; 
			end,			
			
			remove = function()
				error("abort")
				basic_robot.data[name].obj:remove();
				basic_robot.data[name].obj=nil;
			end,
			
			reset = function()
				local pos = basic_robot.data[name].spawnpos; 
				local obj = basic_robot.data[name].obj;
				obj:setpos({x=pos.x,y=pos.y+1,z=pos.z}); obj:setyaw(0);
			end,
			
			set_libpos = function(pos)
				local pos = basic_robot.data[name].spawnpos; local meta = minetest.get_meta(pos);
				meta:set_string("libpos",pos.x .. " " .. pos.y .. " " .. pos.z)
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
				luaent.name = name;
				luaent.spawnpos = pos;
		
			end,
			
			fire_pos = function() 
				local fire_pos = basic_robot.data[name].fire_pos;
				basic_robot.data[name].fire_pos = nil; 
				return fire_pos
			end,
			
			label = function(text)
				local obj = basic_robot.data[name].obj;
				obj:set_properties({nametag = text}); -- "[" .. name .. "] " .. 
			end,
			
			display_text = function(text,linesize,size)
				local obj = basic_robot.data[name].obj;
				commands.display_text(obj,text,linesize,size)
			end,
			
			sound = function(sample,volume)
				local obj = basic_robot.data[name].obj;
				return minetest.sound_play( sample,
				{
					object = obj,
					gain = volume or 1, 
					max_hear_distance = 32, -- default, uses an euclidean metric
				})
			end,
			
			sound_stop = function(handle)
				minetest.sound_stop(handle)
			end,
			
		},

		machine = {-- adds technic like functionality to robots: power generation, smelting, grinding, compressing
			energy = function() return basic_robot.data[name].menergy or 0 end,
			generate_power =  function(input,amount) return commands.machine.generate_power(name,input, amount) end,
			smelt =  function(input,amount) return commands.machine.smelt(name,input, amount) end,
			grind =  function(input) return commands.machine.grind(name,input) end,
			compress =  function(input) return commands.machine.compress(name,input) end,
			transfer_power = function(amount,target) return commands.machine.transfer_power(name,amount,target) end,
		},
		
		keyboard = {
			get = function() return commands.keyboard.get(name) end,
			set = function(pos,type) return commands.keyboard.set(basic_robot.data[name],pos,type) end,
			read = function(pos) return minetest.get_node(pos).name end,
		},
		
		find_nodes = 
			function(nodename,r) 
				if r>8 then return false end
				local q = minetest.find_node_near(basic_robot.data[name].obj:getpos(), r, nodename);
				if q==nil then return false end
				local p = basic_robot.data[name].obj:getpos()
				return math.sqrt((p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2)
			end, -- in radius around position
		
		find_player = 
			function(r) 
				if r>8 then return false end
				local objects =  minetest.get_objects_inside_radius(basic_robot.data[name].obj:getpos(), r);
				local plist = {};
				for _,obj in pairs(objects) do
					if obj:is_player() then 
						plist[#plist+1]=obj:get_player_name();
					end
				end
				if not plist[1] then return nil end
				return plist
			end, -- in radius around position
		
		player = {
			getpos = function(name) 
				local player = minetest.get_player_by_name(name); 
				if player then return player:getpos() else return nil end 
			end,
			
			connected = function()
				local players =  minetest.get_connected_players();
				local plist = {}
				for _,player in pairs(players) do
					plist[#plist+1]=player:get_player_name()
				end
				if not plist[1] then return nil else return plist end
			end
		},
		
		attack = function(target) return basic_robot.commands.attack(name,target) end, -- attack player if nearby
		
		grab = function(target) return basic_robot.commands.grab(name,target) end,
		
		read_node = { -- returns node name
			left = function() return commands.read_node(name,1) end,
			right = function() return commands.read_node(name,2) end,
			forward = function() return commands.read_node(name,3) end,
			backward = function() return commands.read_node(name,4) end,
			down = function() return commands.read_node(name,6) end,
			up = function() return commands.read_node(name,5) end,
			forward_down = function() return commands.read_node(name,7) end,
		},
		
		read_text = { -- returns text
			left = function(stringname,mode) return commands.read_text(name,mode,1,stringname	) end,
			right = function(stringname,mode) return commands.read_text(name,mode,2,stringname) end,
			forward = function(stringname,mode) return commands.read_text(name,mode,3,stringname) end,
			backward = function(stringname,mode) return commands.read_text(name,mode,4,stringname) end,
			down = function(stringname,mode) return commands.read_text(name,mode,6,stringname) end,
			up = function(stringname,mode) return commands.read_text(name,mode,5,stringname) end,
			forward_down = function(stringname,mode) return commands.read_text(name,mode,7,stringname) end,
		},
		
		write_text = { -- returns text
			left = function(text) return commands.write_text(name,1,text) end,
			right = function(text) return commands.write_text(name,2,text) end,
			forward = function(text) return commands.write_text(name,3,text) end,
			backward = function(text) return commands.write_text(name,4,text) end,
			down = function(text) return commands.write_text(name,6,text) end,
			up = function(text) return commands.write_text(name,5,text) end,
			forward_down = function(text) return commands.write_text(name,7,text) end,
			
		},
		
		say = function(text, owneronly)
			if not basic_robot.data[name].quiet_mode and not owneronly then
				minetest.chat_send_all("<robot ".. name .. "> " .. text)
				if not basic_robot.data[name].allow_spam then 
					basic_robot.data[name].quiet_mode=true
				end
			else
				minetest.chat_send_player(basic_robot.data[name].owner,"<robot ".. name .. "> " .. text)
			end
		end,
		
		
		book = {
			read = function(i) 
				if i<=0 or i > 32 then return nil end
				local pos = basic_robot.data[name].spawnpos; local meta = minetest.get_meta(pos);
				local libposstring = meta:get_string("libpos");
				local words = {}; for word in string.gmatch(libposstring,"%S+") do words[#words+1]=word end
				local libpos = {x=tonumber(words[1] or pos.x),y=tonumber(words[2] or pos.y),z=tonumber(words[3] or pos.z)};
				local inv = minetest.get_meta(libpos):get_inventory();local itemstack = inv:get_stack("library", i);
				if itemstack then
					return commands.read_book(itemstack);
				else 
					return nil
				end
			end,
			
			write = function(i,title,text)
				if i<=0 or i > 32 then return nil end
				local inv = minetest.get_meta(basic_robot.data[name].spawnpos):get_inventory();
				local stack = basic_robot.commands.write_book(name,title,text);
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
				if basic_robot.data[name].isadmin ~= 1 then
					local err = check_code(script);
					script = preprocess_code(script);
					if err then 
						minetest.chat_send_player(name,"#ROBOT CODE CHECK ERROR : " .. err) 
						return 
					end
				end
				
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
		
		rom = basic_robot.data[name].rom,
		
		string = {
			byte = string.byte,	char = string.char,
			find = string.find,
			format = string.format,	gsub = string.gsub,
			gmatch = string.gmatch,
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
			date = os.date,			
		},
		
		colorize = core.colorize,
		tonumber = tonumber, pairs = pairs,
		ipairs = ipairs, error = error, type=type,
		
		--_ccounter = basic_robot.data[name].ccounter, -- counts how many executions of critical spots in script
		
		increase_ccounter = 
		function() 
			local _ccounter = basic_robot.data[name].ccounter;
			if _ccounter > basic_robot.call_limit then
				error("Execution limit " .. basic_robot.call_limit .. " exceeded");
			end
			basic_robot.data[name].ccounter = _ccounter + 1;
		end,
	};

	--special sandbox for admin
	local isadmin=basic_robot.data[name].isadmin

	if isadmin~=1 then
		env._G = env;
	else
		env._G=_G;
		debug = debug;
	end
	
	return env	
end

-- code checker

check_code = function(code)
  --"while ", "for ", "do ","goto ", 
  local bad_code = {"repeat", "until", "_ccounter", "_G", "while%(", "while{", "pcall","\\\""}
	
  for _, v in pairs(bad_code) do
    if string.find(code, v) then
      return v .. " is not allowed!";
    end
  end

end


is_inside_string = function(pos,script)
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
		else
			return false
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

-- COMPILATION

preprocess_code = function(script)
	--[[ idea: in each local a = function (args) ... end insert counter like:
	local a = function (args) counter() ... end 
	when counter exceeds limit exit with error
	--]]
	
	script="_ccounter = 0; " .. script;
	
	local i1 -- process script to insert call counter in every function
	local _increase_ccounter = " if _ccounter > " .. basic_robot.call_limit .. 
	" then error(\"Execution count \".. _ccounter .. \" exceeded ".. basic_robot.call_limit .. "\") end _ccounter = _ccounter + 1; "
	
	
	local i1=0; local i2 = 0; 
	local found = true;
	
	while (found) do -- PROCESS SCRIPT AND INSERT COUNTER AT PROBLEMATIC SPOTS
		
		found = false;
		i2 = nil;

		-- i1 = where its looking
		
		i2=string.find (script, "while ", i1) -- fix while OK
		if i2 then
			if not is_inside_string(i2,script) then
				local i21 = i2;
				i2=string.find(script, "do", i2);
				if i2 then 
					script = script.sub(script,1, i2+1) .. _increase_ccounter .. script.sub(script, i2+2); 
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
					script = script.sub(script,1, i2) .. _increase_ccounter .. script.sub(script, i2+1); 
					i1=i2+string.len(_increase_ccounter);
					found = true;
				end
			end
		
		end
		
		i2=string.find (script, "for ", i1) -- fix for OK
		if i2 then
			if not is_inside_string(i2,script) then
				i2=string.find(script, "do", i2);
				if i2 then 
					script = script.sub(script,1, i2+1) .. _increase_ccounter .. script.sub(script, i2+2); 
					i1=i2+string.len(_increase_ccounter);
					found = true;
				end
			end
		end
		
		i2=string.find (script, "goto ", i1) -- fix goto OK
		if i2 then
			if not is_inside_string(i2,script) then
				script = script.sub(script,1, i2-1) .. _increase_ccounter .. script.sub(script, i2); 
				i1=i2+string.len(_increase_ccounter)+5; -- insert + skip goto
				found = true;
			end
		end
		--minetest.chat_send_all("code rem " .. string.sub(script,i1))
		
	end
	
	return script
end


local function CompileCode ( script )

	--minetest.chat_send_all(script)
	--if true then return nil, "" end
	
	local ScriptFunc, CompileError = loadstring( script )
	if CompileError then
        return nil, CompileError
    end
	return ScriptFunc, nil
end

local function initSandbox (name) 
	basic_robot.data[name].sandbox = getSandboxEnv (name);
end

local function setCode( name, script ) -- to run script: 1. initSandbox 2. setCode 3. runSandbox
	
	local err;
	if basic_robot.data[name].isadmin~=1 then
		err = check_code(script);
		script = preprocess_code(script);
	end
	if err then return err end
	
	local bytecode, err = CompileCode ( script );
	if err then return err end
	basic_robot.data[name].bytecode = bytecode;
	return nil
end

basic_robot.commands.setCode=setCode; -- so we can use it

local function runSandbox( name)
    
	local data = basic_robot.data[name]
	local ScriptFunc = data.bytecode;
	if not ScriptFunc then 
		return "Bytecode missing."
	end	
	
	data.ccounter = 0;
	data.operations = 1;
	
	setfenv( ScriptFunc, data.sandbox )
	
	local Result, RuntimeError = pcall( ScriptFunc )
	if RuntimeError then
		return RuntimeError
	end
    
    return nil
end

-- note: to see memory used by lua in kbytes: collectgarbage("count")

local function setupid(owner)
	local privs = minetest.get_player_privs(owner); if not privs then return end
	local maxid = 2;
	if privs.robot then maxid = 16 end -- max id's per user
	basic_robot.ids[owner] = {id = 1, maxid =  maxid}; --active id for remove control
end


local robot_spawner_update_form = function (pos, mode)
	
	if not pos then return end
	local meta = minetest.get_meta(pos);
	if not meta then return end
	local code = minetest.formspec_escape(meta:get_string("code"));
	local form;
	
	local id = meta:get_int("id");
	
	if mode ~= 1 then -- when placed
		
		form  = 
		"size[9.5,8]" ..  -- width, height
		"textarea[1.25,-0.25;8.75,9.8;code;;".. code.."]"..
		"button_exit[-0.25,-0.25;1.25,1;OK;SAVE]"..
		"button_exit[-0.25, 0.75;1.25,1;spawn;START]"..
		     "button[-0.25, 1.75;1.25,1;despawn;STOP]"..
			 "field[0.25,3.;1.,1;id;id;"..id.."]"..
			 "button[-0.25, 3.6;1.25,1;inventory;storage]"..
		     "button[-0.25, 4.6;1.25,1;library;library]"..
		     "button[-0.25, 5.6;1.25,1;help;help]";
			 
	else -- when robot clicked
		form  = 
		"size[9.5,8]" ..  -- width, height
		"textarea[1.25,-0.25;8.75,9.8;code;;".. code.."]"..
		"button_exit[-0.25,-0.25;1.25,1;OK;SAVE]"..
		     "button[-0.25, 1.75;1.25,1;despawn;STOP]"..
			 "button[-0.25, 3.6;1.25,1;inventory;storage]"..
		     "button[-0.25, 4.6;1.25,1;library;library]"..
		     "button[-0.25, 5.6;1.25,1;help;help]";
			 
	end
		
	if mode ==1 then return form end
	meta:set_string("formspec",form)

end

local function init_robot(obj)
	
	local self = obj:get_luaentity();
	local name = self.name; -- robot name
	basic_robot.data[name].obj = obj; --register object
	--init settings
	basic_robot.data.listening[name] = nil -- dont listen at beginning
	basic_robot.data[name].quiet_mode = false; -- can chat globally
	
	-- check if admin robot
	if self.isadmin then basic_robot.data[name].isadmin = 1 end
	
	--robot appearance,armor...
	obj:set_properties({infotext = "robot " .. name});
	obj:set_properties({nametag = "[" .. name.."]",nametag_color = "LawnGreen"});
	obj:set_armor_groups({fleshy=0})
	
	initSandbox ( name )
end

minetest.register_entity("basic_robot:robot",{
	operations = 1, 
	owner = "",
	name = "",
	hp_max = 100,
	itemstring = "robot",
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
			
			self.name = staticdata; -- remember its name
			
			local data = basic_robot.data[self.name];
			
			if not data then
				--minetest.chat_send_all("#ROBOT INIT:  error. spawn robot again.")
				self.object:remove(); 
				return;
			end
			
			self.owner = data.owner;
			self.spawnpos = {x=data.spawnpos.x,y=data.spawnpos.y,z=data.spawnpos.z};
			init_robot(self.object);
			self.running = 1;
			
			
			local meta =  minetest.get_meta(data.spawnpos);
			if meta then self.code = meta:get_string("code") end -- remember code
			if not self.code or self.code == "" then
				minetest.chat_send_player(self.owner, "#ROBOT INIT: no code found")
				self.object:remove(); 
			end
			
			return
		end
		
		-- lost robots 
		--minetest.chat_send_all("D R " .. self.owner)
		
		--if not self.spawnpos then self.object:remove() return end
		
	end,
	
	get_staticdata = function(self)
		return self.name;
	end,
	
	on_punch = function (self, puncher, time_from_last_punch, tool_capabilities, dir)
		
	end,
	
	on_step = function(self, dtime)
		
		self.timer=self.timer+dtime
		if self.timer>self.timestep and self.running == 1 then 
			self.timer = 0;
			local err = runSandbox(self.name);
			if err and type(err) == "string" then 
				local i = string.find(err,":");
				if i then err = string.sub(err,i+1) end
				if string.sub(err,-5)~="abort" then
					minetest.chat_send_player(self.owner,"#ROBOT ERROR : " .. err) 
				end
				self.running = 0; -- stop execution
				
				if string.find(err,"stack overflow") then -- remove stupid player privs and spawner, ban player ip
					local name = self.name;
					local pos = basic_robot.data[name].spawnpos;
					minetest.set_node(pos, {name = "air"});
				
					local privs = core.get_player_privs(self.owner);privs.interact = false; 
					
					core.set_player_privs(self.owner, privs); minetest.auth_reload()
					minetest.ban_player(self.owner)
					
				end
				
				local name = self.name;
				local pos = basic_robot.data[name].spawnpos;
			
				if not basic_robot.data[name] then return end
				if basic_robot.data[name].obj then
					basic_robot.data[name].obj = nil;
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
		
		minetest.show_formspec(clicker:get_player_name(), "robot_worker_" .. self.name, form);
	 end,
})



local spawn_robot = function(pos,node,ttl)
	if type(ttl) ~= "number" then ttl = 0 end
	if ttl<0 then return end
	
	local meta = minetest.get_meta(pos);
	
	--temperature based spam activate protect
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
	local id = meta:get_int("id");
	local name = owner..id;
	

	if id <= 0 then -- just compile code and run it, no robot spawn
		local codechange = false;
		if meta:get_int("codechange") == 1 then
			meta:set_int("codechange",0);
			codechange = true;
		end
		-- compile code & run it
		local err;
		local data = basic_robot.data[name];
		if codechange or (not data) then 
			basic_robot.data[name] = {}; data = basic_robot.data[name];
			meta:set_string("infotext",minetest.get_gametime().. " code changed ")
			data.owner = owner;
			if meta:get_int("admin") == 1 then data.isadmin = 1 end
			
			if not data.obj then
				--create virtual robot that reports position and other properties
				local obj = {};
				function obj:getpos() return {x=pos.x,y=pos.y,z=pos.z} end
				function obj:getyaw() return 0 end
			    function obj:get_luaentity()
					local luaent = {};
					luaent.owner = owner
					luaent.spawnpos = {x=pos.x,y=pos.y-1,z=pos.z};
					return luaent
				end
				function obj:remove() end
				
				data.obj = obj;
			end
		end
		
		
		if not data.bytecode then
			local script = meta:get_string("code");
			
			if data.isadmin~=1 then
				err = check_code(script);
				script = preprocess_code(script);
			end
			if err then 
				meta:set_string("infotext","#CODE CHECK ERROR : " .. err);
				return 
			end
			
			local bytecode, err = loadstring( script )
			if err then
				meta:set_string("infotext","#COMPILE ERROR : " ..  err)
				return
			end
			data.bytecode = bytecode;
		end
		
		--sandbox init
		if not data.sandbox then data.sandbox = getSandboxEnv (name) end

		-- actual code run process			
		data.ccounter = 0;data.operations = 1;
		
		setfenv(data.bytecode, data.sandbox )
		
		local Result, err = pcall( data.bytecode )
		if err then
			meta:set_string("infotext","#RUN ERROR : " ..  err)
			return
		end
	return
	end

	
	-- if robot already exists do nothing
	if basic_robot.data[name] and basic_robot.data[name].obj then
		minetest.chat_send_player(owner,"#ROBOT: ".. name .. " already active, removing ")
		basic_robot.data[name].obj:remove();
		basic_robot.data[name].obj = nil;
	end

	local objects =  minetest.get_objects_inside_radius(pos, 0.9);
	for _,obj in pairs(objects) do if not obj:is_player() then obj:remove() end	end
	
	local obj = minetest.add_entity(pos,"basic_robot:robot");
	local luaent = obj:get_luaentity();
	
	luaent.owner = owner;
	luaent.name = name;
	luaent.code = meta:get_string("code");
    luaent.spawnpos = {x=pos.x,y=pos.y-1,z=pos.z};
	if meta:get_int("admin") == 1 then luaent.isadmin = 1 end
				
			
	local data = basic_robot.data[name];
	if data == nil then
		basic_robot.data[name] = {};
		data = basic_robot.data[name];
		data.rom = {};
	end
	
	data.owner = owner;
	data.spawnpos  = {x=pos.x,y=pos.y-1,z=pos.z};
	
	
	init_robot(obj); -- set properties, init sandbox
	
	local self = obj:get_luaentity();
	local err = setCode( self.name, self.code ); -- compile code
	if err then
		minetest.chat_send_player(self.owner,"#ROBOT CODE COMPILATION ERROR : " .. err) 
		self.running = 0; -- stop execution
		self.object:remove();
		basic_robot.data[self.name].obj = nil;
		return
	end
	
	self.running = 1
end

local despawn_robot = function(pos)
	
	local meta = minetest.get_meta(pos);
	
	--temperature based spam activate protect
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

	-- spawn position on top
	pos.y=pos.y+1;
	local owner = meta:get_string("owner")
	local id = meta:get_int("id"); 
		if id <= 0 then meta:set_int("codechange",1) return end
	local name = owner..id;
	
	-- if robot already exists remove it
	if basic_robot.data[name] and basic_robot.data[name].obj then
		minetest.chat_send_player(owner,"#ROBOT: ".. name .. " removed")
		basic_robot.data[name].obj:remove();
		basic_robot.data[name].obj = nil;
	end
	
	local objects =  minetest.get_objects_inside_radius(pos, 0.9);
	for _,obj in pairs(objects) do if not obj:is_player() then obj:remove() end	end
	
end

--process forms from spawner
local on_receive_robot_form = function(pos, formname, fields, sender)
		
		local name = sender:get_player_name();
		if minetest.is_protected(pos,name) then return end
		
		if fields.OK then
			
			local meta = minetest.get_meta(pos);
			
			if fields.code then 
				local code = fields.code or "";
				
				if meta:get_int("admin") == 1 then
					local privs = minetest.get_player_privs(name); -- only admin can edit admin robot code
					if not privs.privs then
						return
					end
				end
				meta:set_string("code", code); meta:set_int("codechange",1)
			end
			
			if fields.id then 
				local id = math.floor(tonumber(fields.id) or 1);
				local owner = meta:get_string("owner")
				if not basic_robot.ids[owner] then setupid(owner) end 
				if id<-1000 and id>basic_robot.ids[owner].maxid then 
					local privs = minetest.get_player_privs(name);
					if not privs.privs then return end
				end
				meta:set_int("id",id) -- set active id for spawner
				meta:set_string("name", owner..id)
			end
	
			robot_spawner_update_form(pos);
			return
		end
		
		if fields.help then 
			
			local text =  "BASIC LUA SYNTAX\n \nif x==1 then A else B end"..
			"\n  for i = 1, 5 do something end \nwhile i<6 do A; i=i+1; end\n"..
			"\n  arrays: myTable1 = {1,2,3},  myTable2 = {[\"entry1\"]=5, [\"entry2\"]=1}\n"..
			"  access table entries with myTable1[1] or myTable2.entry1 or myTable2[\"entry1\"]\n \n"..
			"ROBOT COMMANDS\n \n"..
			"**MOVEMENT,DIGGING, PLACING, INVENTORY TAKE/INSERT\n  move.direction(), where direction is forward, backward, left,right, up, down)\n"..
			"  forward_down direction only works with dig, place and read_node\n"..
			"  turn.left(), turn.right(), turn.angle(45)\n"..
			"  dig.direction()\n"..
			"  place.direction(\"default:dirt\", optional orientation param)\n"..
			"  read_node.direction() tells you names of nodes\n"..
			"  insert.direction(item, inventory) inserts item from robot inventory to target inventory\n"..
			"  check_inventory.direction(itemname, inventory,index) looks at node and returns false/true, direction can be self,\n"..
			"    if index>0 it returns itemname. if itemname == \"\" it checks if inventory empty\n"..
			"  activate.direction(mode) activates target block\n"..
			"  pickup(r) picks up all items around robot in radius r<8 and returns list or nil\n"..
			"  craft(item,mode) crafts item if required materials are present in inventory. mode = 1 returns recipe\n"..
			"  take.direction(item, inventory) takes item from target inventory into robot inventory\n"..
			"  read_text.direction(stringname,mode) reads text of signs, chests and other blocks, optional stringname for other meta,\n  mode 1 read number\n"..
			"  write_text.direction(text,mode) writes text to target block as infotext\n"..
			"**BOOKS/CODE\n  title,text=book.read(i) returns title,contents of book at i-th position in library \n  book.write(i,title,text) writes book at i-th position at spawner library\n"..
			"  code.run(text) compiles and runs the code in sandbox\n"..
			"  code.set(text) replaces current bytecode of robot\n"..
			"  find_nodes(\"default:dirt\",3) returns distance to node in radius 3 around robot, or false if none\n"..
			"**PLAYERS\n"..
			"  find_player(3) finds players in radius 3 around robot and returns list, if none returns nil\n"..
			"  attack(target) attempts to attack target player if nearby \n"..
			"  grab(target) attempt to grab target player if nearby and returns true if succesful \n"..
			"  player.getpos(name) return position of player, player.connected() returns list of players\n"..
			"**ROBOT\n"..
			"  say(\"hello\") will speak\n"..
			"  self.listen(0/1) (de)attaches chat listener to robot\n"..
			"  speaker, msg = self.listen_msg() retrieves last chat message if robot listens\n"..
			"  self.send_mail(target,mail) sends mail to target robot\n"..
			"  sender,mail = self.read_mail() reads mail, if any\n" ..
			"  self.pos() returns table {x=pos.x,y=pos.y,z=pos.z}\n"..
			"  self.name() returns robot name\n"..
			"  self.skin(textures) sets robot skin, textures is array of 6 textures\n"..
			"  self.spam(0/1) (dis)enable message repeat to all\n"..
			"  self.remove() stops program and removes robot object\n"..
			"  self.reset() resets robot position\n"..
			"  self.spawnpos() returns position of spawner block\n"..
			"  self.viewdir() returns vector of view for robot\n"..
			"  self.fire(speed, pitch,gravity) fires a projectile from robot\n"..
			"  self.fire_pos() returns last hit position\n"..
			"  self.label(text) changes robot label\n"..
			"  self.display_text(text,linesize,size) displays text instead of robot face\n"..
			"  self.sound(sample,volume) plays sound named 'sample' at robot location\n"..
			"  rom is aditional table that can store persistent data, like rom.x=1\n"..
			"**KEYBOARD : place spawner at coordinates (20i,40j+1,20k) to monitor events\n"..
			"  keyboard.get() returns table {x=..,y=..,z=..,puncher = .. , type = .. } for keyboard event\n"..
			"  keyboard.set(pos,type) set key at pos of type 0=air, 1..6, limited to range 10 around\n"..
			"  keyboard.read(pos) return node name at pos\n"..
			"**TECHNIC FUNCTIONALITY: namespace 'machine'. most functions return true or nil, error\n" ..
			"  energy() displays available energy\n"..
			"  generate_power(fuel, amount) = energy, attempt to generate power from fuel material,\n" ..
			"    if amount>0 try generate amount of power using builtin generator - this requires\n" ..
			"    40 gold/mese/diamonblock upgrades for each 1 amount\n"..
			"  smelt(input,amount) = progress/true. works as a furnace, if amount>0 try to\n" ..
			"    use power to smelt - requires 10 upgrades for each 1 amount, energy cost is:\n"..
			"    1/40*(1+amount)\n"..
			"  grind(input) - grinds input material, requires upgrades for harder material\n"..
			"  compress(input) - requires upgrades - energy intensive process\n" ..
			"  transfer_power(amount,target_robot_name)\n";
		
			text = minetest.formspec_escape(text);
			
			--local form = "size [8,7] textarea[0,0;8.5,8.5;help;HELP;".. text.."]"
			
			--textlist[X,Y;W,H;name;listelem 1,listelem 2,...,listelem n]
			local list = "";
			for word in string.gmatch(text, "(.-)\r?\n+") do list = list .. word .. ", " end
			local form = "size [10,8] textlist[-0.25,-0.25;10.25,8.5;help;" .. list .. "]"
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
			local id = meta:get_int("id");
			local name = owner..id;
		
			if id<=0 then meta:set_int("codechange",1) end
			
			if not basic_robot.data[name] then return end
			if basic_robot.data[name].obj then
				basic_robot.data[name].obj:remove();
				basic_robot.data[name].obj = nil;
			end
			return
		end
		
		if fields.inventory then
			local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z ;
			local form  = 
			"size[8,8]" ..  -- width, height
			"list["..list_name..";main;0.,0;8,4;]"..
			"list[current_player;main;0,4.25;8,4;]"..
			"listring[" .. list_name .. ";main]"..
			"listring[current_player;main]";
			minetest.show_formspec(sender:get_player_name(), "robot_inventory", form);
		end
		
		if fields.library then
		
			local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z ;
			local list = "";
			local meta = minetest.get_meta(pos);
			
			local owner = meta:get_string("owner");
			local id = meta:get_int("id");
			local name = owner..id;
			
			local libposstring = meta:get_string("libpos");
			local words = {}; for word in string.gmatch(libposstring,"%S+") do words[#words+1]=word end
			local libpos = {x=tonumber(words[1] or pos.x),y=tonumber(words[2] or pos.y),z=tonumber(words[3] or pos.z)};
			local libform = "";
			
			if libpos.x and libpos.y and libpos.z and not minetest.is_protected(libpos,owner) then 
				libform = "list["..list_name..";library;4.25,0;4,4;]";
			else
				libform = "label[4.25,0;Library position is protected]";
			end
				
			local libnodename = minetest.get_node(libpos).name;
			if libnodename~="basic_robot:spawner" then 
				if libnodename == "ignore" then
					libform = "label[4.25,0;library target area is not loaded]"
				else
					libform = "label[4.25,0;there is no spawner at library coordinates]"
				end
			else
				local inv = minetest.get_meta(libpos):get_inventory();
				local text = "";
				for i=1,16 do
					local itemstack = inv:get_stack("library", i);
					local data = itemstack:get_meta():to_table().fields -- 0.4.16
					--local data = minetest.deserialize(itemstack:get_metadata()) -- pre 0.4.16
					if data then
						text = string.sub(data.title or "",1,32);
					else 
						text = "";
					end
					text = i..". " ..  minetest.formspec_escape(text);
					list = list .. text .. ",";
				end
			end
			
			--for word in string.gmatch(text, "(.-)\r?\n+") do list = list .. word .. ", " end -- matches lines
			local form = "size [8,8] textlist[0,0;4.,3.;books;" .. list .. "]"..
			"field[0.25,3.5;3.25,1;libpos;Position of spawner used as library;"..libposstring.."]"..
			"button_exit[3.25,3.2;1.,1;OK;SAVE]"..
			libform..
			"list[current_player;main;0,4.25;8,4;]";
			minetest.show_formspec(sender:get_player_name(), "robot_library_"..minetest.pos_to_string(pos), form);
		end
		
	end

-- handle form: when rightclicking robot entity, remote controller
minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		
		local robot_formname = "robot_worker_";
		if string.find(formname,robot_formname) then
			local name = string.sub(formname, string.len(robot_formname)+1); -- robot name
			local sender = player:get_player_name(); --minetest.get_player_by_name(name);
			
			if basic_robot.data[name] and basic_robot.data[name].spawnpos then
				local pos = basic_robot.data[name].spawnpos;
				
				local privs = minetest.get_player_privs(player:get_player_name());
				local is_protected = minetest.is_protected(pos, player:get_player_name());
				if is_protected and not privs.privs then return 0 end 
				
				-- if not sender then 
					on_receive_robot_form(pos,formname, fields, player)
				-- else
					-- on_receive_robot_form(pos,formname, fields, sender)
				-- end
				
				return
			end
		end
		
		local robot_formname = "robot_control_";
		if string.find(formname,robot_formname) then
			local name = string.sub(formname, string.len(robot_formname)+1); -- robot name
			if fields.OK and fields.code then
				local item = player:get_wielded_item(); --set_wielded_item(item)
				item:set_metadata(fields.code);
				player:set_wielded_item(item);
				if fields.id then 
					local id = tonumber(fields.id) or 1;
					local owner = player:get_player_name();
					basic_robot.ids[owner].id = id -- set active id
				end
			end
			return
		end
		
		local robot_formname = "robot_manual_control_";
		if string.find(formname,robot_formname) then
			local name = string.sub(formname, string.len(robot_formname)+1); -- robot name
			
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
				pcall(function () basic_robot.data[name].operations = 1; commands.dig(name,3) end)
			elseif fields.up then
				pcall(function () commands.move(name,5) end)
			elseif fields.down then
				pcall(function () commands.move(name,6) end)
			elseif fields.digdown then
				pcall(function () basic_robot.data[name].operations = 1; commands.dig(name,6) end)
			elseif fields.digup then
				pcall(function () basic_robot.data[name].operations = 1; commands.dig(name,5) end)
			end
			return
		end
		
		local robot_formname = "robot_library_";
		if string.find(formname,robot_formname) then
				local spos = minetest.string_to_pos(string.sub(formname, string.len(robot_formname)+1));
				
				if fields.books then
					if string.sub(fields.books,1,3)=="DCL" then
						local sel = tonumber(string.sub(fields.books,5)) or 1; 
						local meta = minetest.get_meta(spos);
						local libposstring = meta:get_string("libpos");
						local words = {}; for word in string.gmatch(libposstring,"%S+") do words[#words+1]=word end
						local libpos = {x=tonumber(words[1] or spos.x),y=tonumber(words[2] or spos.y),z=tonumber(words[3] or spos.z)};
						local inv = minetest.get_meta(libpos):get_inventory();local itemstack = inv:get_stack("library", sel);
						if itemstack then
							local title,text = basic_robot.commands.read_book(itemstack);
							title = title or ""; text = text or "";
							local dtitle = minetest.formspec_escape(title);
							local form = "size [8,8] textarea[0.,0.;8.75,8.5;book; TITLE : " .. minetest.formspec_escape(title) .. ";" ..
							minetest.formspec_escape(text) .. "] button_exit[-0.25,7.5;1.25,1;OK;SAVE] "..
							"button_exit[1.,7.5;2.75,1;LOAD;USE AS PROGRAM] field[4,8;4.5,0.5;title;title;"..dtitle.."]";
							minetest.show_formspec(player:get_player_name(), "robot_book_".. sel.. ":".. minetest.pos_to_string(libpos), form);
							
						end
					end
				end
				
				if fields.OK and fields.libpos then
					local sender = player:get_player_name(); --minetest.get_player_by_name(name);
					local meta = minetest.get_meta(spos);
					meta:set_string("libpos", fields.libpos);
				end
				
			return
		end
		
		local robot_formname = "robot_book_"; -- book editing gui
		if string.find(formname,robot_formname) then
				local p = string.find(formname,":");
				local sel = tonumber(string.sub(formname, string.len(robot_formname)+1,p-1)) or 1;
				local libpos = minetest.string_to_pos(string.sub(formname, p+1));
			
				if minetest.is_protected(libpos, player:get_player_name()) then return end
				
				if fields.OK and fields.book then
					local meta = minetest.get_meta(libpos);
					local inv = minetest.get_meta(libpos):get_inventory();local itemstack = inv:get_stack("library", sel);
					if itemstack then
						local data = itemstack:get_meta():to_table().fields -- 0.4.16, old minetest.deserialize(itemstack:get_metadata()) 
						if not data then data = {} end
						local text = fields.book or "";
						data.text = text or ""
						data.title = fields.title or ""
						data.text_len = #data.text
						data.page = 1
						data.owner = data.owner or ""
						local lpp = 14
						data.page_max = math.ceil((#text:gsub("[^\n]", "") + 1) / lpp)
						
						--local data_str = minetest.serialize(data)
						local new_stack = ItemStack("default:book_written")
						
						new_stack:get_meta():from_table({fields = data}) -- 0.4.16
						--new_stack:set_metadata(data_str);
						inv:set_stack("library",sel, new_stack);					
					end
				end
				
				if fields.LOAD then
					local meta = minetest.get_meta(libpos);
					--minetest.chat_send_all(libpos.x .. " " .. libpos.y .. " " .. libpos.z)
					--minetest.chat_send_all(fields.book or "")
					local inv = minetest.get_meta(libpos):get_inventory();local itemstack = inv:get_stack("library", sel);
					if itemstack then
						local data = itemstack:get_meta():to_table().fields -- 0.4.16, old minetest.deserialize(itemstack:get_metadata()) or {};
						meta:set_string("code",	data.text or "")
						robot_spawner_update_form(libpos);
						minetest.chat_send_player(player:get_player_name(),"#robot: program loaded from book")
					end
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
		local data = basic_robot.data[pname];
		data.listen_msg = message;
		data.listen_speaker = name;
	end
	return false
end
)


minetest.register_node("basic_robot:spawner", {
	description = "Spawns robot",
	tiles = {"cpu.png"},
	groups = {cracky=3, mesecon_effector_on = 1},
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
		meta:set_int("id",1); -- initial robot id
		meta:set_string("name", placer:get_player_name().."1")
		
		meta:set_string("infotext", "robot spawner (owned by ".. placer:get_player_name() .. ")")
		meta:set_string("libpos",pos.x .. " " .. pos.y .. " " .. pos.z)
		
		robot_spawner_update_form(pos);

		local inv = meta:get_inventory(); -- spawner inventory
		inv:set_size("main",32);
		inv:set_size("library",16); --4*4
	end,

	mesecons = {effector = {
		action_on = spawn_robot, 
		action_off = despawn_robot
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
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return 0 end 
		return count
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
		
			local owner = user:get_player_name();
			local code = minetest.formspec_escape(itemstack:get_metadata());
			local ids = basic_robot.ids[owner]; if not ids then setupid(owner) end
			local id = basic_robot.ids[owner].id or 1; -- read active id for player
			local name = owner..id;
			local form = 
			"size[9.5,1.25]" ..  -- width, height
			"textarea[1.25,-0.25;8.75,2.25;code;;".. code.."]"..
			"button_exit[-0.25,-0.25;1.25,1;OK;SAVE]"..
			"field[0.25,1;1.,1;id;id;"..id.."]"
			minetest.show_formspec(owner, "robot_control_" .. name, form);
			return
	end,
	
	on_use = function(itemstack, user, pointed_thing)
		
		local owner = user:get_player_name();
		local ids = basic_robot.ids[owner]; if not ids then setupid(owner) end
		local id = basic_robot.ids[owner].id or 1; -- read active id
		local name = owner .. id
		
		local data = basic_robot.data[name];
		
		if data and data.sandbox then
			
		else
			minetest.chat_send_player(name, "#remote control: your robot must be running");
			return
		end
		
		local t0 = data.remoteuse or 0; -- prevent too fast remote use
		local t1 = minetest.get_gametime();
		if t1-t0<1 then return end
		data.remoteuse = t1;
		
		if data.isadmin == 1 then
			local privs = minetest.get_player_privs(owner); -- only admin can run admin robot
			if not privs.privs then
				return
			end
		end
		
		local script = itemstack:get_metadata();
		if script == "" then
			--display control form
			minetest.show_formspec(owner, "robot_manual_control_" .. name, get_manual_control_form(name));
			return
		end
		
		if not data.isadmin then
			if check_code(script)~=nil then return end
		end
		
		local ScriptFunc, CompileError = loadstring( script )
		if CompileError then
			minetest.chat_send_player(owner, "#remote control: compile error " .. CompileError )
			return
		end
		
		setfenv( ScriptFunc, basic_robot.data[name].sandbox )
		
		local Result, RuntimeError = pcall( ScriptFunc );
		if RuntimeError then
			minetest.chat_send_player(owner, "#remote control: run error " .. RuntimeError )
			return
		end
	end,
})


minetest.register_entity(
	"basic_robot:projectile",
	{
		hp_max = 100,
		physical = true,
		collide_with_objects = true,
		weight = 5,
		collisionbox = {-0.15,-0.15,-0.15, 0.15,0.15,0.15},
		visual ="sprite",	
		visual_size = {x=0.5, y=0.5},
		textures = {"default_furnace_fire_fg.png"},
		is_visible = true,
		oldvel = {x=0,y=0,z=0},
		name = "", -- name of originating robot
		spawnpos = {},
		state = false,

		--on_activate = function(self, staticdata)
		--		self.object:remove()
		--end,

		--get_staticdata = function(self)
		--	return nil
		--end,

		on_step = function(self, dtime)
			local vel = self.object:getvelocity();
			if (self.oldvel.x~=0 and vel.x==0) or (self.oldvel.y~=0 and vel.y==0) or (self.oldvel.z~=0 and vel.z==0) then
				local data = basic_robot.data[self.name];
				if data then
					data.fire_pos = self.object:getpos();
				end
				self.object:remove()
				return
			elseif vel.x==0 and vel.y==0 and vel.z==0 then self.object:remove()
			end
			self.oldvel = vel;
			if not self.state then self.state = true end
			
			end,
			
			get_staticdata = function(self) -- this gets called before object put in world and before it hides
				if not self.state then return nil end
				local data = basic_robot.data[self.name];
				if data then
					data.fire_pos = self.object:getpos();
				end
				self.object:remove();
				return nil
			end,
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


minetest.register_privilege("robot", "increased number of allowed active robots")