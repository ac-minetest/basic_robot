-- basic_robot by rnd, 2016


basic_robot = {};
------  SETTINGS  --------
basic_robot.call_limit = {50,200,1500,10^9}; -- how many execution calls per script run allowed, for auth levels 0,1,2 (normal, robot, puzzle, admin)
basic_robot.count = {2,4,16,128} -- how many robots player can have

basic_robot.radius = 32; -- divide whole world into blocks of this size - used for managing events like keyboard punches
basic_robot.password = "raN___dOM_ p4S"; -- IMPORTANT: change it before running mod, password used for authentifications

basic_robot.admin_bot_pos = {x=0,y=1,z=0} -- position of admin robot spawner that will be run automatically on server start

basic_robot.maxoperations = 10; -- how many operations (dig, place,move,...,generate energy,..) available per run,  0 = unlimited
basic_robot.dig_require_energy = true; -- does robot require energy to dig stone?

basic_robot.bad_inventory_blocks = { -- disallow taking from these nodes inventories to prevent player abuses
	["craft_guide:sign_wall"] = true,
	["basic_machines:battery_0"] = true,
	["basic_machines:battery_1"] = true,
	["basic_machines:battery_2"] = true,
	["basic_machines:generator"] = true,
}
----- END OF SETTINGS ------

basic_robot.http_api = minetest.request_http_api(); 

basic_robot.version = "2019/09/27a";

basic_robot.gui = {}; local robogui = basic_robot.gui -- gui management
basic_robot.data = {}; -- stores all robot related data
--[[
[name] = { sandbox= .., bytecode = ..., ram = ..., obj = robot object, spawnpos= ..., authlevel = ... , t = code execution time} 
robot object = object of entity, used to manipulate movements and more
--]]
basic_robot.ids = {}; -- stores maxid for each player
--[name] = {id = .., maxid = .. }, current id for robot controller, how many robot ids player can use

basic_robot.virtual_players = {}; -- this way robot can interact with the world as "player" TODO

basic_robot.data.listening = {}; -- which robots listen to chat

dofile(minetest.get_modpath("basic_robot").."/robogui.lua") -- gui stuff
dofile(minetest.get_modpath("basic_robot").."/commands.lua")

local check_code, preprocess_code,is_inside_string;



-- SANDBOX for running lua code isolated and safely

function getSandboxEnv (name)
	
	local authlevel = basic_robot.data[name].authlevel or 0;

	local commands = basic_robot.commands;
	local directions = {left = 1, right = 2, forward = 3, backward = 4, up = 5, down = 6, 
		left_down = 7, right_down = 8, forward_down = 9, backward_down = 10,
		left_up = 11, right_up = 12, forward_up = 13,  backward_up = 14
		}
	
	if not basic_robot.data[name].rom then basic_robot.data[name].rom = {} end -- create rom if not yet existing
	local env = 
	{
		pcall=pcall,
		robot_version = function() return basic_robot.version end,
		
		boost = function(v) 
			if math.abs(v)>2 then v = 0 end; local obj = basic_robot.data[name].obj;
			if v == 0 then 
				local pos = obj:getpos(); pos.x = math.floor(pos.x+0.5);pos.y = math.floor(pos.y+0.5); pos.z = math.floor(pos.z+0.5);
				obj:setpos(pos); obj:set_velocity({x=0,y=0,z=0});
				return
			end
			local yaw = obj:get_yaw();
			obj:set_velocity({x=v*math.cos(yaw),y=0,z=v*math.sin(yaw)});
		end,
		
		turn = {
			left = function() commands.turn(name,math.pi/2) end,
			right = function() commands.turn(name,-math.pi/2) end,
			angle = function(angle) commands.turn(name,angle*math.pi/180) end,
		},
		
		pickup = function(r) -- pick up items around robot
			return commands.pickup(r, name);
		end,
		
		craft = function(item, idx,mode, amount)
			return commands.craft(item, mode, idx, amount, name)
		end,
		
		pause = function() -- pause coroutine
			if not basic_robot.data[name].cor then error("you must start program with '--coroutine' to use pause()") return end
			coroutine.yield()
		end,
		
		self = {
			pos = function() return basic_robot.data[name].obj:getpos() end,
			spawnpos = function() local pos = basic_robot.data[name].spawnpos; return {x=pos.x,y=pos.y,z=pos.z} end,
			name = function() return name end,
			operations = function() return basic_robot.data[name].operations end,
			viewdir = function() local yaw = basic_robot.data[name].obj:getyaw(); return {x=math.cos(yaw), y = 0, z=math.sin(yaw)} end,
			
			set_properties = function(properties)
				if not properties then return end; local obj = basic_robot.data[name].obj;
				obj:set_properties(properties);
			end,
			
			set_animation =  function(anim_start,anim_end,anim_speed,anim_stand_start)
				local obj = basic_robot.data[name].obj;
				obj:set_animation({x=anim_start,y=anim_end}, anim_speed, anim_stand_start)
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
			
			fire = function(speed, pitch,gravity, texture, is_entity) -- experimental: fires an projectile
				local obj = basic_robot.data[name].obj;
				local pos = obj:getpos();
				local yaw = obj:getyaw()+ math.pi/2;
				pitch = pitch*math.pi/180
				local velocity = {x=speed*math.cos(yaw)*math.cos(pitch), y=speed*math.sin(pitch),z=speed*math.sin(yaw)*math.cos(pitch)};
				-- fire particle
				if not is_entity then 
					minetest.add_particle(
					{
						pos = pos,
						expirationtime = 10,
						velocity = {x=speed*math.cos(yaw)*math.cos(pitch), y=speed*math.sin(pitch),z=speed*math.sin(yaw)*math.cos(pitch)},
						size = 5,
						texture = texture or "default_apple.png",
						acceleration = {x=0,y=-gravity,z=0},
						collisiondetection = true,
						collision_removal = true,			
					}
					);
				return 
				end
				local obj = minetest.add_entity(pos, "basic_robot:projectile");
				if not obj then return end
				obj:setvelocity(velocity);
				obj:set_properties({textures = {texture or "default_furnace_fire_fg.png"}})
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
				obj:set_properties({nametag = text or ""}); -- "[" .. name .. "] " .. 
			end,
			
			display_text = function(text,linesize,size)
				local obj = basic_robot.data[name].obj;
				return commands.display_text(obj,text,linesize,size)
			end,
			
			find_path = function(pos) -- compute path
				return commands.find_path(name,pos)
			end,

			walk_path = function() -- walk to next node of path
				return commands.walk_path(name)
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
		
		crypto = {-- basic cryptography - encryption, scramble, mod hash
			encrypt = commands.crypto.encrypt, 
			decrypt = commands.crypto.decrypt, 
			scramble = commands.crypto.scramble, 
			basic_hash = commands.crypto.basic_hash,
			};
			
		
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
			function(r,pos) 
				pos = pos or basic_robot.data[name].obj:getpos();
				if r>10 then return false end
				local objects =  minetest.get_objects_inside_radius(pos, r);
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
		
		
		say = function(text, pname)
			if not basic_robot.data[name].quiet_mode and not pname then
				minetest.chat_send_all("<robot ".. name .. "> " .. text)
				if not basic_robot.data[name].allow_spam then 
					basic_robot.data[name].quiet_mode=true
				end
			else
				if not pname then pname = basic_robot.data[name].owner end
				minetest.chat_send_player(pname,"<robot ".. name .. "> " .. text) -- send chat only to player pname
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
				local stack = basic_robot.commands.write_book(basic_robot.data[name].owner,title,text);
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
		},
			
		rom = basic_robot.data[name].rom,
		
		string = {
			byte = string.byte,	char = string.char,
			find = string.find,
			gsub = string.gsub,
			gmatch = string.gmatch,
			len = string.len, lower = string.lower,
			upper = string.upper, rep = string.rep,
			reverse = string.reverse, sub = string.sub,
			
			format = function(...)
				local out = string.format(...)
				if string.len(out) > 1024 then
					error("result string longer than 1024")
					return
				end
				return out				
			end,
			
			concat = function(strings, sep)
				local length = 0;
				for i = 1,#strings do
					length = length + string.len(strings[i])
					if length > 1024 then 
						error("result string longer than 1024")
						return
					end
				end
				return table.concat(strings,sep or "") 
			end,
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
		os = {
			clock = os.clock,
			difftime = os.difftime,
			time = os.time,
			date = os.date,			
		},
		
		colorize = core.colorize,
		serialize = minetest.serialize,
		deserialize = minetest.deserialize,
		tonumber = tonumber, pairs = pairs,
		ipairs = ipairs, error = error, type=type,
		
	};
	
	-- ROBOT FUNCTIONS: move,dig, place,insert,take,check_inventory,activate,read_node,read_text,write_text
	
	env.move = {}; -- changes position of robot
	for dir, dir_id in pairs(directions) do
		env.move[dir]  =  function() return commands.move(name,dir_id) end
	end
	
	env.dig = {};
	for dir, dir_id in pairs(directions) do
		env.dig[dir]  =  function() return commands.dig(name,dir_id) end
	end
	
	env.place = {};
	for dir, dir_id in pairs(directions) do
		env.place[dir] = function(nodename, param2) return commands.place(name,nodename, param2, dir_id) end
	end
	
	env.insert = {}; -- insert item from robot inventory into another inventory
	for dir, dir_id in pairs(directions) do
		env.insert[dir] = function(item, inventory) return commands.insert_item(name,item, inventory,dir_id) end
	end

	env.take = {}; -- takes item from inventory and puts it in robot inventory
	for dir, dir_id in pairs(directions) do
		env.take[dir] = function(item, inventory) return commands.take_item(name,item, inventory,dir_id) end
	end
	
	env.check_inventory = {};
	for dir, dir_id in pairs(directions) do
		env.check_inventory[dir] = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,dir_id) end
	end
	env.check_inventory.self = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,0) end;
	
	env.activate = {};
	for dir, dir_id in pairs(directions) do
		env.activate[dir] = function(mode) return commands.activate(name,mode, dir_id) end
	end
	
	env.read_node = {};
	for dir, dir_id in pairs(directions) do
		env.read_node[dir] = function() return commands.read_node(name,dir_id) end
	end
	
	env.read_text = {} -- returns text
	for dir, dir_id in pairs(directions) do
		env.read_text[dir] = function(stringname,mode) return commands.read_text(name,mode,dir_id,stringname) end
	end
	
	env.write_text = {} -- returns text
	for dir, dir_id in pairs(directions) do
		env.write_text[dir] = function(text) return commands.write_text(name, dir_id,text) end
	end
			
	if authlevel>=1 then -- robot privs
	
		env.self.sound = minetest.sound_play
		env.self.sound_stop = minetest.sound_stop
	
		env.table = {
			concat = table.concat,
			insert = table.insert,
			maxn = table.maxn,
			remove = table.remove,
			sort = table.sort,
		}
		
		env.code.run = function(script)
			if basic_robot.data[name].authlevel < 3 then
				local err = check_code(script);
				script = preprocess_code(script, basic_robot.call_limit[basic_robot.data[name].authlevel+1]);
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
		
		env.self.read_form = function()
			local fields = basic_robot.data[name].read_form;
			local sender = basic_robot.data[name].form_sender;
			basic_robot.data[name].read_form = nil; 
			basic_robot.data[name].form_sender = nil; 
			return sender,fields
		end
			
		env.self.show_form = function(playername, form)
			commands.show_form(name, playername, form)
		end
	end
	
	-- set up sandbox for puzzle
		
	if authlevel>=2 then -- puzzle privs
		basic_robot.data[name].puzzle = {};
		local data = basic_robot.data[name];
		local pdata = data.puzzle;
		pdata.triggerdata = {};
		pdata.gamedata = {};
		pdata.block_ids = {}
		pdata.triggers = {};
		env.puzzle = { -- puzzle functionality
			set_node = function(pos,node) commands.puzzle.set_node(data,pos,node) end,
			get_node = function(pos) return minetest.get_node(pos) end,
			activate = function(mode,pos) commands.puzzle.activate(data,mode,pos) end,
			get_meta = function(pos) return commands.puzzle.get_meta(data,pos) end,
			get_gametime = function() return minetest.get_gametime() end,
			get_node_inv = function(pos) return commands.puzzle.get_node_inv(data,pos) end,
			get_player = function(pname) return commands.puzzle.get_player(data,pname) end,
			chat_send_player = function(pname, text)	minetest.chat_send_player(pname or "", text)	end,
			get_player_inv = function(pname) return commands.puzzle.get_player_inv(data,pname) end,
			set_triggers = function(triggers) commands.puzzle.set_triggers(pdata,triggers) end, -- FIX THIS!
			check_triggers = function(pname) 
				local player = minetest.get_player_by_name(pname); if not player then return end
				commands.puzzle.checkpos(pdata,player:getpos(),pname) 
			end,
			add_particle = function(def) minetest.add_particle(def) end,
			count_objects = function(pos,radius) return #minetest.get_objects_inside_radius(pos, math.min(radius,5)) end,
			pdata = pdata,
			ItemStack = ItemStack,
		}
		
	end

	--special sandbox for admin
	if authlevel<3 then -- is admin?
		env._G = env;
	else
		env.minetest = minetest;
		env._G=_G;
		debug = debug;
	end
	
	return env	
end

-- code checker

check_code = function(code)
  --"while ", "for ", "do ","goto ",  
  local bad_code = {"repeat", "until", "_c_", "_G", "while%(", "while{", "pcall","%.%.[^%.]"} --,"\\\"", "%[=*%[","--[["}
  for _, v in pairs(bad_code) do
    if string.find(code, v) then
      return v .. " is not allowed!";
    end
  end
end


local identify_strings = function(code) -- returns list of positions {start,end} of literal strings in lua code

	local i = 0; local j; local _; local length = string.len(code);
	local mode = 0; -- 0: not in string, 1: in '...' string, 2: in "..." string, 3. in [==[ ... ]==] string
	local modes = {
		{"'","'"}, -- inside ' '
		{"\"","\""}, -- inside " "
		{"%[=*%[","%]=*%]"}, -- inside [=[ ]=]
	}
	local ret = {}
	while i < length do
		i=i+1
	
		local jmin = length+1;
		if mode == 0 then -- not yet inside string
			for k=1,#modes do
				j = string.find(code,modes[k][1],i);
				if j and j<jmin then  -- pick closest one
					jmin = j
					mode = k
				end
			end
			if mode ~= 0 then -- found something
				j=jmin
				ret[#ret+1] = {jmin}
			end
			if not j then break end -- found nothing
		else
			_,j = string.find(code,modes[mode][2],i); -- search for closing pair
			if not j then break end
			if (mode~=2 or (string.sub(code,j-1,j-1) ~= "\\") or string.sub(code,j-2,j-1) == "\\\\") then -- not (" and not \" - but "\\" is allowed)
				ret[#ret][2] = j
				mode = 0
			end
		end
		i=j -- move to next position
	end
	if mode~= 0 then ret[#ret][2] = length end
	return ret
end


is_inside_string = function(strings,pos) -- is position inside one of the strings?
	local low = 1; local high = #strings;
	if high == 0 then return false end
	local mid = high;
	while high>low+1 do
		mid = math.floor((low+high)/2)
		if pos<strings[mid][1] then high = mid else low = mid end
	end
	if pos>strings[low][2] then mid = high else mid = low end
	return strings[mid][1]<=pos and pos<=strings[mid][2]
end

local find_outside_string = function(script, pattern, pos, strings)
	local length = string.len(script)
	local found = true;
	local i1 = pos;
	while found do
		found = false
		local i2 = string.find(script,pattern,i1);
		if i2 then
			if not is_inside_string(strings,i2) then return i2 end
			found = true;
			i1 = i2+1;
		end
	end
	return nil
end

-- COMPILATION

preprocess_code = function(script, call_limit)  -- version 07/24/2018

	--[[ idea: in each local a = function (args) ... end insert counter like:
	local a = function (args) counter_check_code ... end 
	when counter exceeds limit exit with error
	--]]
	
	script = script:gsub("%-%-%[%[.*%-%-%]%]",""):gsub("%-%-[^\n]*\n","\n") -- strip comments

	-- process script to insert call counter in every function
	local _increase_ccounter = " _c_ = _c_ + 1; if _c_ > " .. call_limit .. 
	" then _G.error(\"Execution count \".. _c_ .. \" exceeded ".. call_limit .. "\") end; "
	
	local i1=0; local i2 = 0;
	local found = true;
	
	local strings = identify_strings(script);

	local inserts = {};
	
	local constructs = {
		{"while%s", "%sdo%s", 2, 6}, -- numbers: insertion pos = i2+2,  after skip to i1 = i12+6
		{"function", ")", 0, 8},
		{"for%s", "%sdo%s", 2, 4},
		{"goto%s", nil , -1, 5},
	}
	
	for i = 1,#constructs do
		i1 = 0; found = true
		while (found) do -- PROCESS SCRIPT AND INSERT COUNTER AT PROBLEMATIC SPOTS
		
			found = false;
	
			i2=find_outside_string(script, constructs[i][1], i1, strings) -- first part of construct
			if i2 then
				local i21 = i2;
				if constructs[i][2] then
					i2 = find_outside_string(script, constructs[i][2], i2, strings); -- second part of construct ( if any )
					if i2 then 
						inserts[#inserts+1]= i2+constructs[i][3]; -- move to last position of construct[i][2]
						found = true;
					end
				else
					inserts[#inserts+1]= i2+constructs[i][3]
					found = true -- 1 part construct
				end
				
				if found then 
					i1=i21+constructs[i][4]; -- skip to after constructs[i][1]
				end
			end
				
		end
	end
	
	table.sort(inserts)
	
	-- add inserts
	local ret = {};	i1=1;
	for i = 1, #inserts do
		i2 = inserts[i];
		ret[#ret+1] = string.sub(script,i1,i2);
		i1 = i2+1;
	end
	ret[#ret+1] = string.sub(script,i1);
	script = table.concat(ret,_increase_ccounter)
	
	-- must reset ccounter when paused, but user should not be able to force reset by modifying pause!
	-- (suggestion about 'pause' by Kimapr, 09/26/2019)
	
	return "_c_ = 0 local _pause_ = pause pause = function() _c_ = 0; _pause_() end " .. script;
	
	--return script:gsub("pause%(%)", "_c_ = 0; pause()") -- reset ccounter at pause
end


local function CompileCode ( script )
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
	local cor = false;
	if string.find(string.sub(script,1,32), "coroutine") then cor = true end
	
	local authlevel = basic_robot.data[name].authlevel;
	
	if authlevel<3 then -- not admin
		err = check_code(script);
		script = preprocess_code(script,basic_robot.call_limit[authlevel+1]);
	elseif cor then
		script = preprocess_code(script, basic_robot.call_limit[authlevel+1]); --  coroutines need ccounter reset or 'infinite loops' fail after limit
	end
	if err then return err end
	
		
	local bytecode, err = CompileCode ( script );
	if err then return err end
	basic_robot.data[name].bytecode = bytecode;
	
	if cor then -- create coroutine if requested
		basic_robot.data[name].cor = coroutine.create(bytecode)
	else 
		basic_robot.data[name].cor = nil
	end
	return nil
end

basic_robot.commands.setCode=setCode; -- so we can use it

local function runSandbox( name)
    
	local data = basic_robot.data[name]
	local ScriptFunc = data.bytecode;
	if not ScriptFunc then 
		return "Bytecode missing."
	end	
	
	data.operations = basic_robot.maxoperations;
	data.t = os.clock()
	
	setfenv( ScriptFunc, data.sandbox )
	
	local cor = data.cor;
	if cor then -- coroutine!
		local err,ret
		ret,err = coroutine.resume(cor)
		data.t = os.clock()-data.t
		if err then return err end
		return nil
	end
	
	local Result, RuntimeError = pcall( ScriptFunc )
	data.t = os.clock()-data.t
	if RuntimeError then
		return RuntimeError
	end
	
    return nil
end

-- note: to see memory used by lua in kbytes: collectgarbage("count")

local get_authlevel = function(name) -- given player name return auth level
	local privs = minetest.get_player_privs(name); 
	local authlevel = 0;
	if privs.privs then -- set auth level depending on privs
		authlevel = 3
	elseif privs.puzzle then 
		authlevel = 2
	elseif privs.robot then
		authlevel = 1
	else
		authlevel = 0
	end
	return authlevel
end

local function setupid(owner)
	local privs = minetest.get_player_privs(owner); if not privs then return end
	local maxid = basic_robot.count[get_authlevel(owner)+1] or 2;
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
		"button[-0.25,7.5;1.25,1;EDIT;EDIT]".. 
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
		
	if mode == 1 then return form end
	meta:set_string("formspec",form)

end

basic_robot.editor = {};
editor_get_lines = function(text,name)
	local data = basic_robot.editor[name]; 
	if not data then 
		basic_robot.editor[name] = {}; 
		basic_robot.editor[name].lines = {};
		basic_robot.editor[name].selection = 1;
		data = basic_robot.editor[name]; 
	else
		data.lines = {};
	end
	
	local lines = data.lines; 
	for line in string.gmatch(text,"[^\r\n]+") do lines[#lines+1] = line end
end


code_edit_form = function(pos,name)
	local lines = basic_robot.editor[name].lines;
	local input = minetest.formspec_escape(basic_robot.editor[name].input or "");
	local selection = basic_robot.editor[name].selection or 1;
	
	local list = "";
	for _,line in pairs(lines) do list = list .. minetest.formspec_escape(line) .. "," end
	local form = "size[12,9.25]" .. "textlist[0,0;12,8;listname;" .. list .. ";"..selection..";false]" .. 
	"button[10,8;2,1;INSERT;INSERT LINE]" ..
	"button[10,8.75;2,1;DELETE;DELETE LINE]" ..
	"button_exit[2,8.75;2,1;SAVE;SAVE CODE]" ..
	"button[0,8.75;2,1;UPDATE;UPDATE LINE]"..
	"textarea[0.25,8;10,1;input;;".. input .. "]"
	return form
end



local function init_robot(obj, resetSandbox)
	
	local self = obj:get_luaentity();
	local name = self.name; -- robot name
	basic_robot.data[name].obj = obj; --register object
	--init settings
	basic_robot.data.listening[name] = nil -- dont listen at beginning
	basic_robot.data[name].quiet_mode = false; -- can chat globally
	
	-- check if admin robot
	basic_robot.data[name].authlevel = self.authlevel or 0
	
	--robot appearance,armor...
	obj:set_properties({infotext = "robot " .. name});
	obj:set_properties({nametag = "[" .. name.."]",nametag_color = "LawnGreen"});
	obj:set_armor_groups({fleshy=0})

	if resetSandbox then initSandbox ( name ) end

end

minetest.register_entity("basic_robot:robot",{
	operations = basic_robot.maxoperations, 
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
	textures={"topface.png","legs.png","left-hand.png","right-hand.png","face.png","face-back.png"},
	
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
			self.authlevel = data.authlevel;
			
			self.spawnpos = {x=data.spawnpos.x,y=data.spawnpos.y,z=data.spawnpos.z};
			init_robot(self.object, false); --  do not reset sandbox to keep all variables, just wake up
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
				-- recreate dead coroutine, does this have some side effects like memory leak?
				if err == "cannot resume dead coroutine" then 
					local data = basic_robot.data[self.name]
					data.cor = coroutine.create(data.bytecode)
					err=runSandbox(self.name)
					if not err then return end
				end
				
				if string.sub(err,-5)~="abort" and not cor then
					minetest.chat_send_player(self.owner,"#ROBOT ERROR : " .. err) 
				end
				
				
				self.running = 0; -- stop execution
				
				if string.find(err,"stack overflow") then
					local name = self.name;
					local pos = basic_robot.data[name].spawnpos;
					minetest.set_node(pos, {name = "air"});
					--local privs = core.get_player_privs(self.owner);privs.interact = false; 
					--core.set_player_privs(self.owner, privs); minetest.auth_reload()
					minetest.kick_player(self.owner, "#basic_robot: stack overflow")
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
	

	if id <= 0 then -- just compile code and run it, no robot entity spawn
		local codechange = false;
		if meta:get_int("codechange") == 1 then
			meta:set_int("codechange",0);
			codechange = true;
		end
		-- compile code & run it
		local err;
		local data = basic_robot.data[name];
		if codechange or (not data) then -- reset all, sandbox will change too
			basic_robot.data[name] = {}; data = basic_robot.data[name];
			meta:set_string("infotext",minetest.get_gametime().. " code changed ")
			data.owner = owner;
			data.authlevel = meta:get_int("authlevel")
			
			local sec_hash = minetest.get_password_hash("",data.authlevel.. owner .. basic_robot.password) 
			if meta:get_string("sec_hash")~= sec_hash then
				minetest.chat_send_player(owner,"#ROBOT: " .. name .. " is using fake auth level. dig and place again.")
				return
			end
			
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
		
			if data.authlevel<3 then -- not admin
				err = check_code(script);
				script = preprocess_code(script, basic_robot.call_limit[data.authlevel+1]);
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
		data.operations = basic_robot.maxoperations;
		
		setfenv(data.bytecode, data.sandbox )
		
		local Result, err = pcall( data.bytecode )
		if err then
			meta:set_string("infotext","#RUN ERROR : " ..  err)
			return
		end
	return
	end -- end of entityless robot code

	
	-- if robot entity already exists refresh it
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
	luaent.authlevel = meta:get_int("authlevel")
	
	local sec_hash = minetest.get_password_hash("",luaent.authlevel.. owner .. basic_robot.password) 
	if meta:get_string("sec_hash")~= sec_hash then
		minetest.chat_send_player(owner,"#ROBOT: " .. name .. " is using fake auth level.  dig and place again.")
		obj:remove();
		return
	end
			
	local data = basic_robot.data[name];
	if data == nil then
		basic_robot.data[name] = {};
		data = basic_robot.data[name];
		--data.rom = {};
	end
	
	data.owner = owner;
	data.spawnpos  = {x=pos.x,y=pos.y-1,z=pos.z};
	
	
	init_robot(obj,true); -- set properties, resetSandbox = true
	
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


--admin robot that starts automatically after server start
minetest.after(10, function() 
	local admin_bot_pos = basic_robot.admin_bot_pos;
	minetest.forceload_block(admin_bot_pos,true) -- load map position
	spawn_robot(admin_bot_pos,nil,1)
	print("[BASIC_ROBOT] admin robot at " .. admin_bot_pos.x .. " " .. admin_bot_pos.y .. " " .. admin_bot_pos.z .. " started.")
end)
	

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
				if string.len(code) > 64000 then 
					minetest.chat_send_all("#ROBOT: " .. name .. " is spamming with long text.") return 
				end
				
				if meta:get_int("authlevel") > 1 and name ~= meta:get_string("owner")then
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
				if id<-1000 or id>basic_robot.ids[owner].maxid then 
					local privs = minetest.get_player_privs(name);
					if not privs.privs then return end
				end
				meta:set_int("id",id) -- set active id for spawner
				meta:set_string("name", owner..id)
			end
	
			robot_spawner_update_form(pos);
			return
		end
		
		if fields.EDIT then
			local meta = minetest.get_meta(pos);if not meta then return end
			if meta:get_int("admin") == 1 then
				local privs = minetest.get_player_privs(name); -- only admin can edit admin robot code
				if not privs.privs then
					return
				end
			end
			
			local code = meta:get_string("code");
			editor_get_lines(code,name);
			local form = code_edit_form(pos,name);
			minetest.after(0, -- why it ignores this form sometimes? old form interfering?
				function()
					minetest.show_formspec(name, "robot_editor_:"..minetest.pos_to_string(pos), form);
				end
			)
			return
		end
		
		if fields.help then ----- INGAME HELP ------
			robogui["robot_help"].show(name)
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
				if string.len(fields.code) > 1000 then 
					minetest.chat_send_player(player:get_player_name(),"#ROBOT: text too long") return 
				end
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
				pcall(function () basic_robot.data[name].operations = basic_robot.maxoperations; commands.dig(name,3) end)
			elseif fields.up then
				pcall(function () commands.move(name,5) end)
			elseif fields.down then
				pcall(function () commands.move(name,6) end)
			elseif fields.digdown then
				pcall(function () basic_robot.data[name].operations = basic_robot.maxoperations; commands.dig(name,6) end)
			elseif fields.digup then
				pcall(function () basic_robot.data[name].operations = basic_robot.maxoperations; commands.dig(name,5) end)
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
		
		local robot_formname = "robot_editor_"; -- editor  gui TODO
		if string.find(formname,robot_formname) then
			local name = player:get_player_name();
			local p = string.find(formname,":");
			local pos = minetest.string_to_pos(string.sub(formname, p+1));
			
			if fields.listname then
				local list = fields.listname;
				if string.sub(list,1,3) == "CHG" then
					local selection = tonumber(string.sub(list,5)) or 1
					basic_robot.editor[name].selection = selection;
					local lines = basic_robot.editor[name].lines;
					basic_robot.editor[name].input = lines[selection] or "";
					minetest.show_formspec(name, "robot_editor_:"..minetest.pos_to_string(pos), code_edit_form(pos,name));
				end
			elseif fields.UPDATE then
				local lines = basic_robot.editor[name].lines or {};
				local selection = basic_robot.editor[name].selection or 1;
				fields.input = fields.input or "";
				fields.input = string.gsub(fields.input, '\\([%[%]\\,;])', '%1') -- dumb minetest POSTS escaped stuff...
				lines[selection] = fields.input
				basic_robot.editor[name].input = lines[selection];
				minetest.show_formspec(name, "robot_editor_:"..minetest.pos_to_string(pos), code_edit_form(pos,name));
			elseif fields.DELETE then
				local selection = basic_robot.editor[name].selection or 1;
				table.remove(basic_robot.editor[name].lines,selection);
				minetest.show_formspec(name, "robot_editor_:"..minetest.pos_to_string(pos), code_edit_form(pos,name));
			elseif fields.INSERT then
				local selection = basic_robot.editor[name].selection or 1;
				table.insert(basic_robot.editor[name].lines,selection,"")
				minetest.show_formspec(name, "robot_editor_:"..minetest.pos_to_string(pos), code_edit_form(pos,name));
			elseif fields.SAVE then
				local selection = basic_robot.editor[name].selection or 1;
				local lines = basic_robot.editor[name].lines or {};
				if fields.input and fields.input~="" then 
					fields.input = string.gsub(fields.input, '\\([%[%]\\,;])', '%1') -- dumb minetest POSTS escaped stuff...
					lines[selection]= fields.input 
				end
				local meta = minetest.get_meta(pos);
				if not lines then return end
				local code = table.concat(lines,"\n");
				meta:set_string("code",code);
				basic_robot.editor[name].lines = {};
				robot_spawner_update_form(pos,0);
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
						if string.len(text) > 64000 then 
							local sender = player:get_player_name();
							minetest.chat_send_all("#ROBOT: " .. sender .. " is spamming with long text.") return 
						end
						data.text = text or ""
						data.title = fields.title or ""
						data.text_len = #data.text
						data.description = fields.title or ""
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
	local hidden = false;
	if string.sub(message,1,1) == "\\" then hidden = true; message = string.sub(message,2) end
	local listeners = basic_robot.data.listening; -- which robots are listening?
	for pname,_ in pairs(listeners) do
		local data = basic_robot.data[pname];
		data.listen_msg = message;
		data.listen_speaker = name;
	end
	return hidden
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
		local owner = placer:get_player_name();
		meta:set_string("owner", owner); 
		
		local authlevel = get_authlevel(placer:get_player_name());
		
		meta:set_int("authlevel",authlevel)
		local sec_hash = minetest.get_password_hash("",authlevel .. owner .. basic_robot.password) -- 'digitally sign' authlevel using password
		meta:set_string("sec_hash", sec_hash);
	
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
	groups = {book = 1}, --not_in_creative_inventory = 1
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
		
		local script = itemstack:get_metadata();
		if script == "@" then -- remote control as a tool - notify robot in current block of pointed position, using keyboard event type 0
			local round = math.floor;
			local r = basic_robot.radius; local ry = 2*r; -- note: this is skyblock adjusted
			local pos  = pointed_thing.under
			if not pos then return end
			local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry+1,z=round(pos.z/r+0.5)*r}; -- just on top of basic_protect:protector!
			local meta = minetest.get_meta(ppos);
			local name = meta:get_string("name");
			local data = basic_robot.data[name];
			if data then data.keyboard = {x=pos.x,y=pos.y,z=pos.z, puncher = owner, type = 0} end
			return
		end
		
		
		local ids = basic_robot.ids[owner]; if not ids then setupid(owner) end
		local id = basic_robot.ids[owner].id or 1; -- read active id
		local name = owner .. id
		
		local data = basic_robot.data[name];
		
		if data and data.sandbox then
			
		else
			minetest.chat_send_player(owner, "#remote control: your robot must be running");
			return
		end
		
		local t0 = data.remoteuse or 0; -- prevent too fast remote use
		local t1 = minetest.get_gametime();
		if t1-t0<1 then return end
		data.remoteuse = t1;
		
		if data.authlevel >= 3 then
			local privs = minetest.get_player_privs(owner); -- only admin can run admin robot
			if not privs.privs then
				return
			end
		end
		
		if script == "" then
			--display control form
			minetest.show_formspec(owner, "robot_manual_control_" .. name, get_manual_control_form(name));
			return
		end
		
		if data.authlevel<3 then
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
			if (self.oldvel.x~=0 and vel.x==0) or (self.oldvel.y~=0 and vel.y==0) or (self.oldvel.z~=0 and vel.z==0) then -- hit
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
minetest.register_privilege("puzzle", "allow player to use puzzle. namespace in robots")

print('[MOD]'.. " basic_robot " .. basic_robot.version .. " loaded.")
