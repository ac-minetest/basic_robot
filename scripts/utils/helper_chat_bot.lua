if not init then 
	init = true; self.listen(1);
	self.spam(1); self.label("help bot")
	keywords = {
		{"help",
			{"robot",6},{"",1}
		},
		{"how",
			{"play",1},{"robot", 6},{"stone",4},{"tree",3},{"wood",3},{"lava",5},{"cobble",4},{"dirt",10},
			{"do i get",1},{"do i make",1}, {"to get",1}
		},
		{"i need",
			{"wood",3}
		},

		{"hello",2}, -- words matched must appear at beginning
		{"hi",2},
		{"back",7}, 
		{" hard",{"",9}}, -- word matched can appear anywhere
		{" died", {"",9}},
		{" die",{"",8}}, {" dead",{"",8}},
		{"rnd",{"",11}},
		{"bye",{"",12}},
		{"!!",{"",9}},
	}
	answers = {
		"%s open inventory, click 'Quests' and do them to get more stuff", --1
		"hello %s",
		"do the dirt quest to get sticks then do sapling quest",
		"get pumice from lava and water. then search craft guide how to make cobble",
		"you get lava as compost quest reward or with grinder", -- 5
		"you have to write a program so that robot knows what to do. for list of commands click 'help' button inside robot.",
		"wb %s",
		"dont die, you lose your stuff and it will reset your level on level 1",
		"you suck %s!", -- 9
		"to get dirt craft composter and use it with leaves", -- 10
		"rnd is afk. in the meantime i can answer your questions",
		"bye %s",
	}
end

speaker,msg = self.listen_msg();
if msg then
	msg = string.lower(msg);
	sel = 0;
	for i = 1, #keywords do
		local k = string.find(msg,keywords[i][1])
		if k then 
			if type(keywords[i][2])~="table" then
				if k == 1 then sel = keywords[i][2] break end
			else
				for j=2,#keywords[i] do
					if string.find(msg,keywords[i][j][1]) then 
						sel =  keywords[i][j][2]; break;
					end
				end
			end
			
		end
	end
	
	if sel>0 then
		local response = answers[sel];
		if string.find(response,"%%s") then
			say(string.format(response,speaker))
		else
			say(response)
		end
	end
	
end