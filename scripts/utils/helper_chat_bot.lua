if not init then 

	self.set_properties({
		visual = "mesh", mesh = "character.b3d",
		textures = {"character_45.png"},
		visual_size = {x = 5, y = 5}
	});
	 move.down()
	
	animation = {
	-- Standard animations.
	stand     = { x=  0, y= 79, },
	lay       = { x=162, y=166, },
	walk      = { x=168, y=187, },
	mine      = { x=189, y=198, },
	walk_mine = { x=200, y=219, },
	sit       = { x= 81, y=160, },
	}
bstate = "walk_mine"
bspeed = 5--15
	self.set_animation(animation[bstate].x,animation[bstate].y, bspeed, 0)

	init = true; self.listen(1);

	_G.minetest.forceload_block(self.pos(),true)
	self.spam(1); self.label("") --help bot")
	
	talk = function(msg) minetest.chat_send_all("<help bot> " .. msg) end
	keywords = {
		{"tpr", 14},
		{"tpy",19},
		{"help",
			{"robot",6},{"",1}
		},
		{"how",
			{"play",1},{"island",17},{"robot", 6},{"stone",4},{"tree",3},{"wood",3},{"lava",5},{"mossy",16},{"cobble",4},{"dirt",10},{"clay",23},
			{"do i get",1},{"do i make",1}, {"to get",1},{"farm",15}, 
		},
		{"i need",
			{"wood",3}
		},

		{"hello",2}, -- words matched must appear at beginning
		{"hi",2},
		{"back",7}, 
		{" 'hard",{"",9}}, -- word matched can appear anywhere
		{" died", {"",9}},
		{" die",{"",8}}, {" dead",{"",8}},
--		{"rnd",{"",11}},
		{"^bye",{"",12}},
		{"!!",{"",9}},
		
		{"calc", 13},
		{"day",18},
		{"RESET_LEVEL",20},
		{"YES",21},
	}
	answers = {
		"%s open inventory, click 'Quests' and do them to get more stuff", --1
		"hello %s",
		"you can get wood from bush stems or trees. tree sapling needs to be planted on fertilized composter with 10 N nutrient",
		"get pumice from lava and water. then search craft guide how to make cobble",
		"you get lava as dig tree quest reward. warning - put lava away from flammable blocks. full composter does not burn - its safe.", -- 5
		"you have to write a program so that robot knows what to do. for list of commands click 'help' button inside robot.",
		"wb %s",
		"dont die, you lose your stuff and it will reset your level on level 1",
		"you suck %s!", -- 9
		"to get dirt craft composter, put gravel on it, punch it and wait until its ready. then punch again to get dirt.", -- 10
		"rnd is afk. in the meantime i can answer your questions",
		"bye %s",
		function(speaker,msg)  -- 13, calc
			local expr = string.sub(msg,5); 
			if string.find(expr,"%a") then return end;
			if string.find(expr,"{") then return end;
			local exprfunc = _G.loadstring("return " .. expr);
			local res = exprfunc and exprfunc() or say("error in expression: " .. expr);
			if type(res) == "number" then say(expr .. " = " .. res) end
		end,
		function(speaker,msg) -- 14,tpr
			tpr[1] = speaker
			tpr[2] = string.sub(msg,5) or "";
			minetest.chat_send_player(tpr[2], "#TPR: " .. speaker .. " wants to teleport to you. say \\tpy")
		end,
		"to make farm craft composter, put leaves on it,punch and wait until its ready. Then right click composter to see if it has enough nutrients. If yes, plant your crops on top.", -- 15
"put cobble near water and wait.", --16
		"you get your own island when you finish all quests on level 1. before that your island will be reused by other players.", --17
		function(speaker,msg) -- 18, day
			minetest.set_timeofday(0.25); say("time set to day")
		end,
		function(speaker,msg) -- 19,tpy
			if tpr[2] ~= speaker then return end;
			local p1 = minetest.get_player_by_name(tpr[1]);
			local p2 = minetest.get_player_by_name(tpr[2]);tpr[2] = ""
			if p1 and p2 then
				p1:setpos(p2:getpos())
			end
		end,
		function(speaker,msg) -- 20,RESET_LEVEL
			say("this will reset your skyblock level to beginning of level 1. are you sure " .. speaker .. "? say YES")
			qa[1] = speaker; qa[2] = 22
		end,
		function(speaker,msg) -- 21,yes to some question
			if qa[1] ~= speaker then return end
			answers[qa[2]](speaker,msg)
			qa[1] = ""
		end,
		
		function(speaker,msg) -- 22 reset level 
			say("your level is reset " .. speaker .. ". have a nice day.")
		end,
		
		"you get clay by grinding dirt in grinder ( basic_machines ). Either craft grinder from constructor or get as level 3 1st quest reward" -- 23
		
	}
	tpr = {"",""} -- used for teleport
	qa = {"",1}; -- speaker
end

speaker,msg = self.listen_msg();
if msg then
	--msg = string.lower(msg);
	sel = 0;
	for i = 1, #keywords do
		local k = string.find(msg,keywords[i][1])
		if k then 
			if type(keywords[i][2])~="table" then -- one topic only
				if k == 1 then sel = keywords[i][2] break end
			else
				for j=2,#keywords[i] do -- category of several topics
					if string.find(msg,keywords[i][j][1]) then 
						sel =  keywords[i][j][2]; break;
					end
				end
			end
		end
	end
	
	if sel>0 then
		local response = answers[sel];
		if type(response) == "function" then
			response(speaker,msg)		
		elseif string.find(response,"%%s") then
			talk(string.format(response,speaker))
		else
			talk(response)
		end
	end
	
end