--[[ 
 help bot 2
 
 'how to make/craft X' = 'how' 'make' 'x'
 pattern match:
  word1 word2 ... wordn
  
  word1 - start of pattern
  
  patterns = {
	["pattern_start"] = { 
		{ -- list of possible sequences
			{{"pattern2", ..},{"pattern3", ..}, ..},"response"} -- { patternsequence, "response"}
		},
		...
	}

--]]

if not init then init = true
 _G.minetest.forceload_block(self.pos(),true)
	patterns = {
	["calc"] = {	{{}, "calc"}	},
	["day"] = {	{{}, "day"}	},
	["day4ever"] = {	{{}, "day4ever"}	},
	["crazy_mode"] = {	{{}, "crazy_mode"}	},
	["normal_mode"] = {	{{}, "normal_mode"}	},
	
	["hi"] = {	{{}, "greeting"}	},
	["hey"] = {	{{}, "greeting"}	},
	["hello"] = {	{{}, "greeting"}	},
	
	["bye"] = {	{{}, "goodbye"}	},
	
	["help"] = { 
		{
			{{"play"}}, "play_help"
		},
		{
			{}, "help_general"
		},
	},

	["tell"] = { 
		{
			{{"bot"}}, "tell_bot"
		},
	},
	
	["ask"] = { 
		{
			{{"bot"}}, "ask_bot"
		},
	},

	["how"] = { 
		{
			{{"plant"},{"tree"}}, "plant_tree_help"
		},
		{
			{{"play"}}, "play_help"
		},
		{
			{{"get"},{"island"}}, "getting_island_help"
		},
		{
			{{"get"},{"tree"}}, "plant_tree_help"
		},
		{
			{{"get"},{"wood"}}, "getting_wood_help"
		},
		{
			{{"get"},{"clay"}}, "getting_clay_help"
		},
		{
			{{"get"},{"stone"}}, "getting_stone_help"
		},
		{
			{{"get","make"},{"dirt"}}, "getting_dirt_help"
		},
		{
			{{"get","find"}}, "getting_stuff_help"
		},
		{
			{{"craft"}}, "craft_help"
		},
		{
			{{"farm"}}, "farm_help"
		},
		{
			{{"robot"}}, "robot_help"
		},
		{
			{{"craft","make"}}, "craft_help"
		},
	},
	
	["tpr"] = {	{{}, "tpr"}	},
	["tpy"] = {	{{}, "tpy"}	},
	}
	
	bot_knowledge = {}; -- bot knows stuff players tell it
	chat_data = {} -- various player data
 	--[[ 
	[name] = {greet = true} -- already said hi
			tpr  = requester -- someone want to teleport to 'name'
	--]]

	responses = {
		["greeting"] = function(name,imatch, iendmatch, words) 
			if imatch>2 then return end
			if not chat_data[name] then chat_data[name] = {greet = true} elseif chat_data[name].greet then return end
			
			chat_data[name].greet = true -- remember we said hi
			
			local ipdata = _G.helloip.players[name]; local country = 'en'
			if ipdata then country = ipdata.country end
			
			local greetings = {
				["ZZ"] = "hi ", 
				["EN"] = "hello and welcome ",
				["DE"] = "hallo und willkommen ",
				["FR"] = "bonjour et bienvenue ",
				["PL"] = "czesc i witaj ",
				["RU"] = "privet i dobro pozhalovat' ",
				["NL"] = "hallo en welkom ",
			}
			talk((greetings[country] or greetings["EN"]) .. name ) 
		end,
		
		["goodbye"] = function(name,imatch,iendmatch, words) 
			if imatch>2 then return end
			talk("see you later " .. name) 
		end,
		["farm_help"] = function(name) 
			_G.basic_robot.gui["farming_help"].show(name)
		end,
		["robot_help"] = function(name) 
			_G.basic_robot.gui["robot_help"].show(name)
		end,
		["craft_help"] = function(name) 
			local text = "Build 3x3 normal wood table on the ground. Drop items in shape of crafting recipe on the table. Then use craft tool on table to craft item.\n\nIt is important to be looking in direction toward top of recipe.\n\nYou can craft more than 1 item - try dropping 5 of each items in recipe to craft 5 items ...\n\nUsing craft tool on bush will give you wood."
			local form = "size[8,4.5] textarea[0,0.25;9,5.5;msg;CRAFT HELP;"..text .."]"
			minetest.show_formspec(name, "basic_craft_help_text",form)
		end,
		["plant_tree_help"] = function(name) talk(name .. " you need to plant tree on composter. insert 10 leaves in composter first by putting leaves on top and punching composter. repeat this 10 times.") end,
		["play_help"] = function(name) talk(name .. " open inventory and read crafting and farming help. Look at quests too and do them to progress. You can make island larger with leaves.") end,
		["getting_island_help"] = function(name) talk(name .. " you need to complete level 1 to get your own island. for now your island only temporary.") end,
		["help_general"] = function(name) talk("what you need help with " .. name .. " ?") end,
		["getting_clay_help"] = function(name) talk("you get clay by grinding dirt in grinder ( basic_machines ). Either craft grinder from constructor or get it as level 3 1st quest reward") end,
		["getting_wood_help"] = function(name) talk("you can get wood from bush stems or trees - use craft tool on bush stem.") end,
		["getting_stone_help"] = function(name) talk("get pumice from lava and water. then search craft guide how to make cobble") end,
		["getting_dirt_help"] = function(name) talk("place gravel on composter and punch composter.when composting done punch again to get out dirt.") end,
		
		["tpr"] = function(name,imatch, iendmatch, words)
			local target = words[2]; if not target then return end
			if not minetest.get_player_by_name(target) then return end
			local tdata = chat_data[target];
			if not tdata then chat_data[target] = {}; tdata = chat_data[target] end
			tdata.tpr = name
			talk(name .. " wants to teleport to you - say tpy", target)
		end,
		["tpy"] = function(name,imatch, iendmatch, words)
			local data = chat_data[name];
			if not data then chat_data[name] = {}; data = chat_data[name] end
			local requester = data.tpr; if not requester then return end
			
			local rpl = minetest.get_player_by_name(requester)
			if not rpl then return end
			rpl:set_pos( minetest.get_player_by_name(name):get_pos() )
			data.tpr = nil
		end,
		["calc"] = function(name,imatch,__,words) -- calculator
			if imatch~=1 then return end
			local expr = string.sub(table.concat(words," "),5)
			if string.find(expr,"%a") then return end;
			if string.find(expr,"{") then return end;
			local exprfunc = _G.loadstring("return " .. expr);
			local res = exprfunc and exprfunc() or say("error in expression: " .. expr);
			if type(res) == "number" then talk(expr .. " = " .. res) end
		end,
		
		["ask_bot"] = function(name,imatch, iendmatch, words)
			if imatch>1 then return end
			local expr = string.sub(table.concat(words," "),9)
			--i = string.find(expr," ")
			--if i then expr = string.sub(expr,1,i-1) end
			local answer = bot_knowledge[expr];
			if not answer then 
				talk("i don't know about " .. expr)
			else
				talk(expr .. " " .. answer)
			end
		end,
		
		["tell_bot"] = function(name,imatch, iendmatch, words)
			if imatch>1 then return end
			local expr = string.sub(table.concat(words," "),10)
			local i = string.find(expr, " ")
			if not i then 
				talk("what did you want to tell me about " .. expr .. " ?")
			else
				local dwords = {" is ", " are "}
				local j;
				for k=1,#dwords do j =  string.find(expr,dwords[k]);if j then break end	end
				local topic, value
				if j then
					topic = string.sub(expr,1,j-1) value = string.sub(expr,j)
				else
					topic = string.sub(expr,1,i-1) value = string.sub(expr,i+1)
				end				
				bot_knowledge[topic] = value
				talk("i will remember what you told me about " .. topic, name)
			end
		end,
		
		["day"] = function()
			minetest.set_timeofday(0.25); talk("time set to day")
		end,
		["day4ever"] = function()
			minetest.set_timeofday(0.25); talk("forever day")
			minetest.settings:set("time_speed",0); 
		end,		
		["crazy_mode"] = function()
			talk("crazy mode ON")
			minetest.settings:set("time_speed",500000); 
		end,
		["normal_mode"] = function()
			talk("crazy mode OFF")
			minetest.settings:set("time_speed",72); 
		end
		
	}

	talk = function(text,name)
		if not name then
			minetest.chat_send_all("<help bot> " .. text)
		else
			minetest.chat_send_player(name,"<help bot> " .. text)
		end
	end

	check_msg = function(text)
	local level = 0;
	local pattern;
	local words = {}
	for word in string.gmatch(text,"[^%s,?:]+") do words[#words+1] = word	end

	local imatch
	for i = 1,#words do
		if patterns[words[i]] then pattern = patterns[words[i]] imatch = i end -- perhaps this will match?
	end
	if not imatch then return end
	--say("possible match: " .. words[imatch])

	-- check out all pattern possibilities
	local jmatch
	local iendmatch = imatch

	for j = 1, #pattern do
		if jmatch then break end -- already got it
		
		local level = 1
		local pat = pattern[j]
		--say("pattern " .. j .. " length :" .. #pat[1]+1)
		if #pat[1] ==  0 then -- empty pattern, we have match
			jmatch = j; break
		end		
		
		for i = imatch+1, #words do -- only search from next word
			if jmatch then break end
			for k = 1, #pat[1][level] do
				if words[i] == pat[1][level][k] then
					level = level +1; 
					if #pat[1]+1 == level then jmatch = j iendmatch = i end
					break
				end
			end
		end
	end

	if jmatch then
		local responseid = pattern[jmatch][2]
		--say("match: " .. words[imatch] .. ", response " .. responseid)
		return responses[responseid],imatch,iendmatch, words
	end

	end

	self.listen(1); 
--self.label("help bot - ask me questions")
self.label("")
end
  
speaker,msg = self.listen_msg()
if msg then 
	local response, imatch, iendmatch, words
	response, imatch,iendmatch, words = check_msg(msg)
	if response then response(speaker, imatch, iendmatch, words) end
end