local robogui = basic_robot.gui;

-- GUI

-- robogui GUI START ==================================================
-- a simple table of entries: [guiName] =  {getForm = ... , show = ... , response = ... , guidata = ...}
robogui.register = function(def)
	robogui[def.guiName] = {getForm = def.getForm, show = def.show, response = def.response, guidata = def.guidata or {}}
end
minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		local gui = robogui[formname];
		if gui then gui.response(player,formname,fields) end
	end
)
-- robogui GUI END ====================================================


--- DEMO of simple form registration, all in one place, clean and tidy
-- adapted for use with basic_robot


-- if not basic_gui then
	-- basic_gui = _G.basic_gui; minetest = _G.minetest;
	-- basic_gui.register({
	-- guiName = "mainWindow", -- formname
	
	-- getForm = function(form_id, update) -- actual form design
		-- local gui = basic_gui["mainWindow"];
		-- local formdata = gui.guidata[form_id]
		
		-- if not formdata then -- init
			-- gui.guidata[form_id] = {}; formdata = gui.guidata[form_id]
			-- formdata.sel_tab = 1;
			-- formdata.text = "default";
			-- formdata.form = "";
		-- end
		-- if not update then return formdata.form end
		
		-- local sel_tab = formdata.sel_tab;
		-- local text = formdata.text;
		
		-- formdata.form = "size[8,9]"..
				-- "label[0,0;basic_gui_DEMO, form_id " .. form_id .. ", tab " .. sel_tab .. "]"..
				-- "button[0,1;2,1;gui_button;CLICK ME]"..
				-- "textarea[0.25,2;2,1;gui_textarea;text;" .. text .. "]"..
				-- "tabheader[0,0;tabs;tab1,table demo,tab3;".. sel_tab .. ";true;true]"..
				-- "list[current_player;main;0,5;8,4;]";
		
		-- if sel_tab == 2 then
			-- formdata.form = "size[12,6.5;true]" ..
			-- "tablecolumns[color;tree;text,width=32;text]" ..
			-- "tableoptions[background=#00000000;border=false]" ..
			-- "field[0.3,0.1;10.2,1;search_string;;" .. minetest.formspec_escape(text) .. "]" ..
			-- "field_close_on_enter[search_string;false]" ..
			-- "button[10.2,-0.2;2,1;search;" .. "Search" .. "]" ..
			-- "table[0,0.8;12,4.5;list_settings;"..
			-- "#FFFF00,1,TEST A,,"..
			-- "#FFFF00,2,TEST A,,"..
			-- ",3,test a,value A,"..
			-- "#FFFF00,1,TEST B,,"..
			-- ",2,test b,value B,"
		-- end
		
		-- formdata.info = "This information comes with the form post"; -- extra data set
	-- end,
	
	-- show = function(player_name,update) -- this is used to show form to user
		-- local formname = "mainWindow";
		-- local form_id = player_name; -- each player has his own window!
		-- local gui = basic_gui[formname];
		-- local formdata = gui.guidata[form_id]; -- all form data for this id gets stored here
		-- if update then gui.getForm(form_id,true); formdata = gui.guidata[form_id]; end
		-- minetest.show_formspec(player_name, "mainWindow", formdata.form)
	-- end,
	
	-- response = function(player,formname, fields) -- this handles response
		
		-- local player_name = player:get_player_name();
		-- local form_id = player_name;
		-- local gui = basic_gui[formname];
		-- local formdata = gui.guidata[form_id]; --gui.guidata[form_id]; 
		-- if not formdata then say("err") return end --error!
		
		-- if fields.gui_textarea then 
			-- formdata.text = fields.gui_textarea or "" 
		-- end
		
		
		-- if fields.tabs then 
			-- formdata.sel_tab  = tonumber(fields.tabs) or 1;
			
			-- gui.show(player_name,true) -- update and show form
		-- else
			
			-- local form = "size[5,5]" ..
			-- "label[0,0;you interacted with demo form, fields : " .. 
			-- _G.minetest.formspec_escape(_G.dump(fields)) .. "]"..
			-- "label[0,4;" .. formdata.info .. "]"
			-- _G.minetest.show_formspec(player_name,"basic_response", form);
		-- end
	-- end,
	

-- })
-- end

local help_address = {}; -- array containing current page name for player
local help_pages = {
	["main"] = { 
		"     === ROBOT HELP - MAIN SCREEN === ","",
		"[Commands reference] display list of robot commands",
		"[Lua basics] short introduction to lua","",
		"INSTRUCTIONS: double click links marked with []",
		"------------------------------------------","",
		"basic_robot version " .. basic_robot.version,
		"(c) 2016 rnd",
	},
	
	["Lua basics"] = {
		"back to [main] menu",
		"BASIC LUA SYNTAX","",
		"  IF CONDITIONAL: if x==1 then A else B end",
		"  FOR LOOP: for i = 1, 5 do something end",
		"  WHILE LOOP: while i<6 do A; i=i+1; end",
		'  ARRAYS: myTable1 = {1,2,3},  myTable2 = {["entry1"]=5, ["entry2"]=1}',
		'    access table entries with myTable1[1] or myTable2.entry1 or',
		'    myTable2["entry1"]',
		"  FUNCTIONS: f = function(x) return 2*x end, call like f(3)",
		"  STRINGS: name = \"rnd\" or name = [[rnd ]] (multiline string)",
		"    string.concat({string1,string2,...}, separator) returns",
		"    concatenated string with maxlength is 1024",
	},
	
	["Commands reference"] = {
		"back to [main] menu",
		
		"ROBOT COMMANDS","",
		"  1. [MOVEMENT DIGGING PLACING NODE SENSING]",
		"  2. [TAKE INSERT AND INVENTORY]",
		"  3. [BOOKS CODE TEXT WRITE OR READ]",
		"  4. [PLAYERS]",
		"  5. [ROBOT SPEAK LABEL APPEARANCE OTHER]",
		"  6. [KEYBOARD AND USER INTERACTIONS]",
		"  7. [TECHNIC FUNCTIONALITY]",
		"  8. [CRYPTOGRAPHY]",
		"  9. [PUZZLE]",
		"  10.[COROUTINES] - easier alternative to finite state machines",
	},
	
	["MOVEMENT DIGGING PLACING NODE SENSING"] = {
		"back to [Commands reference]",
		"MOVEMENT,DIGGING, PLACING, NODE SENSING","",
		"  move.direction(), where direction is: left, right, forward, backward,",
		"    up, down, left_down, right_down, forward_down, backward_down,",
		"    left_up, right_up, forward_up, backward_up",
		"  boost(v) sets robot velocity, -6<v<6, if v = 0 then stop",
		"  turn.left(), turn.right(), turn.angle(45)",
		"  dig.direction()",
		"  place.direction(\"default:dirt\", optional orientation param)",
		"  read_node.direction() tells you names of nodes",
	},
	
	["TAKE INSERT AND INVENTORY"] = {
		"back to [Commands reference]",
		"TAKE INSERT AND INVENTORY","",
		"  insert.direction(item, inventory) inserts item from robot inventory to",
		  "  target inventory",
		"  check_inventory.direction(itemname, inventory,index) looks at node and ",
		"    returns false/true, direction can be self, if index>0 it returns itemname.",
		"    if itemname == \"\" it checks if inventory empty",
		"  activate.direction(mode) activates target block",
		"  pickup(r) picks up all items around robot in radius r<8 and returns list",
		"    or nil",
		"  craft(item,idx,mode) crafts item if required materials are present in",
		"    inventory, mode = 1 returns recipe, optional recipe idx",
		"  take.direction(item, inventory) takes item from target inventory into",
		" robot inventory",
	},
	
	["BOOKS CODE TEXT WRITE OR READ"] = {
		"back to [Commands reference]",
		"BOOKS CODE TEXT WRITE OR READ","",
		"  title,text=book.read(i) returns title,contents of book at i-th position in",
		"    library",
		"  book.write(i,title,text) writes book at i-th position at spawner library",
		"  code.run(text) compiles and runs the code in sandbox (privs only)",
		"  code.set(text) replaces current bytecode of robot",
		"  find_nodes(\"default:dirt\",3) returns distance to node in radius 3 around",
		"    robot, or false if none found",
		"  read_text.direction(stringname,mode) reads text of signs, chests and",
		"    other blocks, optional stringname for other meta, mode 1 to read number",
		"  write_text.direction(text,mode) writes text to target block as infotext",
	},
	
	["PLAYERS"] = {
		"back to [Commands reference]",
		"PLAYERS","",
		"  find_player(3,pos) finds players in radius 3 around robot(position) and",
		"    returns list of found player names, if none returns nil",
		"  attack(target) attempts to attack target player if nearby",
		"  grab(target) attempt to grab target player if nearby and returns",
		"    true if succesful",
		"  player.getpos(name) return position of player, player.connected()",
		" returns list of connected players names",
	},
	
	["ROBOT SPEAK LABEL APPEARANCE OTHER"] = {
		"back to [Commands reference]",
		"ROBOT","",
		"  say(\"hello\") will speak",
		"  self.listen(0/1) (de)attaches chat listener to robot",
		"  speaker, msg = self.listen_msg() retrieves last chat message if robot",
		"    has listener attached",
		"  self.send_mail(target,mail) sends mail to target robot",
		"  sender,mail = self.read_mail() reads mail, if any",
		"  self.pos() returns table {x=pos.x,y=pos.y,z=pos.z}",
		"  self.name() returns robot name",
		"  self.operations() returns remaining robot operations",
		"  self.set_properties({textures=.., visual=..,visual_size=.., , ) sets visual",
		"    appearance",
		"  self.set_animation(anim_start,anim_end,anim_speed,anim_stand_start)",
		"    set mesh,animation",
		"  self.spam(0/1) (dis)enable message repeat to all",
		"  self.remove() stops program and removes robot object",
		"  self.reset() resets robot position",
		"  self.spawnpos() returns position of spawner block",
		"  self.viewdir() returns vector of view for robot",
		"  self.fire(speed, pitch,gravity, texture, is_entity) fires a projectile",
		"    from robot. if is_entity false (default) it fires particle.",
		"  self.fire_pos() returns last hit position",
		"  self.label(text) changes robot label",
		"  self.display_text(text,linesize,size) displays text instead of robot face,",
		"    if no size just return texture string",
		"  self.find_path(pos) attempts to find path to pos (coordinates must be",
		"    integer). On success return length of path, otherwise nil",
		"  self.walk_path() attempts to walk path it previously found. On success ",
		"    returns number of remaining nodes, on fail it returns -next node distance or 0",
		"  self.sound(sample,volume, opt. pos) plays sound named 'sample' at",
		"    robot, location (optional pos)",
		"  rom is aditional table that can store persistent data, like rom.x=1",
	},
	
	["KEYBOARD AND USER INTERACTIONS"] = {
		"back to [Commands reference]",
		"KEYBOARD","",
		"  EVENTS : place spawner at coordinates (r*i,2*r*j+1,r*k) to monitor",
		"    events. value of r is ".. basic_robot.radius,
		"  keyboard.get() returns table {x=..,y=..,z=..,puncher = .. , type = .. }",
		"    for keyboard event",
		"  keyboard.set(pos,type) set key at pos of type 0=air,1-6,7-15,16-271,",
		"    limited to range 10 around spawner",
		"  keyboard.read(pos) return node name at pos",
	},
	
	["TECHNIC FUNCTIONALITY"] = {
		"back to [Commands reference]",
		"TECHNIC FUNCTIONALITY","",
		"  All commands are in namespace 'machine', for example machine.energy()",
		"    most functions return: ok, error = true or nil, error",
		"  To use some commands fully robot must be upgraded. 1 upgrade is",
		"    goldblock+meseblock+diamonblock.",
		"  energy() displays available energy",
		"  generate_power(fuel, amount) = energy, attempt to generate power",
		"    from fuel material. If amount>0 try generate amount of power",
		"    using builtin generator - this requires 40 upgrades for each",
		"    1 amount",
		"  smelt(input,amount) = progress/true. works as a furnace, if amount>0",
		"    try to use power to smelt - requires 10 upgrades for each 1 amount,",
		"    energy cost of smelt is: 1/40*(1+amount)",
		"  grind(input) - grinds input material, requires upgrades for harder",
		"    materials",
		"  compress(input) - requires upgrades - energy intensive process",
		"  transfer_power(amount,target_robot_name)",
	},
	
	["CRYPTOGRAPHY"] = {
		"back to [Commands reference]",
		"CRYPTOGRAPHY","",
		"  namespace 'crypto'",
		"  encrypt(input,password) returns encrypted text, password is any string",
		"  decrypt(input,password) attempts to decrypt encrypted text",
		"  scramble(input,randomseed,sgn)  (de)permutes text randomly according",
		"    to sgn = -1,1",
		"  basic_hash(input,n) returns simple mod hash from string input within",
		"    range 0...n-1",
	},
	
	["PUZZLE"] = {
		"back to [Commands reference]",
		"PUZZLE","",
		"  namespace 'puzzle' - need puzzle priv",
		"  set_triggers({trigger1, trigger2,...}) sets and initializes spatial triggers",
		"  check_triggers(pname) check if player is close to any trigger and run",
		"    that trigger",
		"  set_node(pos,node) - set any node, limited to current protector",
		"    region",
		"  get_player(pname) return player objRef in current protector region",
		"  chat_send_player(pname, text)",
		"  get_node_inv(pos) / get_player_inv(pname) - return inventories of nodes",
		"    /players in current mapblock",
		"  get_meta(pos) - return meta of target position",
		"  get_gametime() - return current gametime",
		"  ItemStack(itemname) returns ItemRef to be used with inventory",
		"  count_objects(pos,radius)",
		"  pdata contains puzzle data like .triggers and .gamedata",
		"  add_particle(def)"
	},
	
		["COROUTINES"] = {
		"back to [Commands reference]",
		"COROUTINES","",
		"robot can run code using lua coroutines. To enable this mode just put the word",
		"coroutine in the first 32 characters of your program. Example: ", "",
		" --testing program for coroutine",
		"   for i = 1,5 do ",
		"       say(i); dig.forward(); move.forward()",
		"       pause()",
		"   end",
	},

	
	
}
for k,v in pairs(help_pages) do
	local pages = help_pages[k]; for i = 1,#pages do pages[i] = minetest.formspec_escape(pages[i]) end
end


local robot_show_help = function(pname) --formname: robot_help
	local address = help_address[pname] or "main";	
	
	--minetest.chat_send_all("D DISPLAY HELP for ".. address )
	local pages = help_pages[address];

	local content = table.concat(pages,",")
	local size = 9; local vsize = 8.75;

	local form = "size[" .. size .. "," .. size .. "] textlist[-0.25,-0.25;" .. (size+1) .. "," .. (vsize+1) .. ";wiki;".. content .. ";1]";
	--minetest.chat_send_all("D " .. form)
	minetest.show_formspec(pname, "robot_help", form)
	return
end


robogui["robot_help"] = {
	response = function(player,formname,fields)
		local name = player:get_player_name()

		local fsel = fields.wiki;
		if fsel and string.sub(fsel,1,3) == "DCL" then
			local sel = tonumber(string.sub(fsel,5)) or 1; -- selected line
			local address = help_address[name] or "main";
			local pages = help_pages[address];
						
			local link = string.match(pages[sel] or "", "\\%[([%w%s]+)\\%]")
			if help_pages[link] then 
				help_address[name] = link;
				robot_show_help(name)
			end
		end
	end,
	
	getForm = function(player_name)
	
	end,
	
	show = robot_show_help,
};
