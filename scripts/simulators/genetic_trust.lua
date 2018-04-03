if not init then
	rom.best_player = nil
	init = true
	depth = 4; -- how many moves does random player evaluate
	error_rate = 0.25; -- players make wrong decision with this probability
	generation = 10; -- how many times we repeat
	steps = 100; -- how many steps each generation
	bestc = 0; -- how many times was new best player picked
	mode = 2; -- 1, evolution!, 2 play game
	
	-- game pay offs
	rules = {
			{ 
			   {2., 2.}, -- first player cooperate, second player cooperate: +2,+2
			   {-1, 3}, -- first player cooperate, second player cheat: -1,+3
			},
			{ 
				{3,-1}, -- first player cheats, second player cooperate
				{0,0}, -- first player cheats, second player cheat
			}	
		};

	copytable = function(tab) 
		if type(tab)~="table" then return tab end 
		local ret = {};	
		for k,v in pairs(tab) do ret[k] = copytable(v) end	return 
		ret 
	end

	copycat = {
		rules = {
			{0}, -- initial: 0 = cooperate
			{0,1}, -- after one move : cooperate if other cooperated last turn, cheat if other cheated last turn
		}, 
		-- encode decision sequence in binary: 01110 = dec 8+4+2=14
		memory = 1, -- how many moves back player consideres?
		moves ={}, -- opponent moves
		mood = 0, -- probability that player will cheat if he had intention to cooperate
		moody = 0.5, -- by how much cheat/cooperate change mood
		points = 0,
		name = "copycat"
	}

	cheater = {
		rules = {
			{1}, 
		}, 
		memory = 0, -- how many moves back player consideres?
		moves ={}, -- opponent moves
		mood = 0,
		moody = 0.5,
		points = 0,
		name = "cheater"
	}
	
	realplayer = {
		rules = {
			{0}, 
		}, 
		memory = 0, -- how many moves back player consideres?
		moves ={}, -- opponent moves
		mood = 0,
		moody = 0.,
		points = 0,
		name = "real player",
		real = true,
		out = 0
	}


	create_random_player = function(memory)
		local rules = {};
		for i = 1, memory+1 do
			rules[i] = {};
			for j = 1,2^(i-1) do
				rules[i][j] = math.random(2)-1
			end
		end
		return {rules = rules, memory = memory, moves = {}, mood = 0, moody = math.random(), points = 0, name = "randomplayer"}
	end


	-- player makes next move according to his memory of moves so far
	play = function(player)
		if player.real then return player.out end -- real player
		local moves = player.moves;
		local n = #moves; 
		if n > player.memory then n = player.memory end -- there are many moves, examine only what we can
		local rules = player.rules[n+1]
		local state = bin2dec(player.moves,n); -- examine last n moves
		--say("n " .. n .. " state " .. state)
		return rules[state+1]
	end

	

	group_play = function(playrs) -- each randomplayer plays with every other player in lower group
			local n = #playrs;
			local m = 10; -- play m games with each opponent, random pair order
			for i = 1,10 do
				for j = 11,20 do -- i plays with j, randomized order
					playrs[i].moves = {}; playrs[j].moves = {}; -- reset remembered moves before paired match!
					playrs[i].mood = 0;
					for k = 1,m do
						if math.random(2) == 1 then 
							interact(playrs[i],playrs[j])
						else
							interact(playrs[j],playrs[i])
						end
					end
				end
			end
			
	end
	
	sort_players = function(pl)
		table.sort(pl, 
			function(p1,p2) return p1.points<p2.points end
		) -- sorts in ascending order of points
	end
	
	genetics = function(playrs)
		local population = {}
		for i = 11,20 do -- pick out only "randomplayer"s
			population[#population+1] = playrs[i] --copytable()
		end
		
		sort_players(population); -- sort from worst to best
		for i = 1,5 do -- replace 5 worst players with new random players
			local points2 = population[#population-i+1].points; -- points of i-th best player
			if points2 then 
				local points1 = population[i].points;
				if points1<points2 or (points1==points2 and math.random(2) == 1) then -- 
					
					population[i] = create_random_player(depth);
					--if i == 1 then say(serialize(population[i].rules)) end
					population[i].points = 0 --points2;
					population[i].name = "randomplayer"
				end
			end
		end

		
		--say("best random points " .. population[#population].points)
		for i = 11,20 do -- pick out only "randomplayer"s
			playrs[i] = population[i-10]
		end
		
	end

	-- paired interaction: player1 plays with player2, then player2 plays with player1
	interact = function(player1,player2)
		local res1 = play(player1);
		local mood = player1.mood;
		
		if not player1.real and math.random(1000)<=1000*error_rate then res1=1-res1 end
		if res1 == 0 and math.random()<= mood then res1 = 1 end
		
		local moves = player2.moves; moves[#moves+1 ] = res1;
		--say("1 moves : " .. serialize(moves) .. " res1 " .. res1)
		local res2 = play(player2);
		
		mood = player2.mood;
		if math.random(1000)<=1000*error_rate then res2=1-res2 end
		if res2 == 0 and math.random()<= mood then res2 = 1 end
		
		moves = player1.moves; moves[#moves+1] = res2;
		--say("2 moves : " .. serialize(moves) .. " res2 " .. res2)
		local res = rules[res1+1][res2+1];
		player1.points = player1.points + res[1];
		player2.points = player2.points + res[2];
		
		if res2 == 0 then -- player2 cooperated, mood change
			if res1==1 then
				mood = mood + player2.moody;
			else
				mood = mood - player2.moody;
			end
			if mood>1 then mood = 1 elseif mood<0 then mood = 0 end
			player2.mood = mood
		end
		
		if res1 == 0 then -- mood change for player1
			mood = player1.mood;
			if res2==1 then
				mood = mood + player1.moody;
			else
				mood = mood - player1.moody;
			end
			if mood>1 then mood = 1 elseif mood<0 then mood = 0 end
			player1.mood = mood
		end
	end

	dec2bin = function(input)
		local ret  = {};
		if input == 0 then return {0} end
		while input~=0 do
			local r=input%2; input = (input -r)/2
			ret[#ret+1] = r;
		end
		local n = #ret;
		local rret = {}
		for	i = 1, n do
			rret[i]=ret[n-i+1]
		end
		return rret
	end

	bin2dec = function(bin, length) -- length= how many last elements we take
		if length == 0 then return 0 end
		if not length then length = #bin end
		local offset = #bin - length; if offset<0 then offset = 0 end
		local ret = 0;
		for i = 1,#bin-offset do
			ret = 2*ret + bin[i+offset]
		end
		return ret
	end
	
	get_results = function(players)
		local ret = {} for i=1,#players do	ret[i] = players[i].name .. " " .. players[i].points .. "M " .. players[i].mood .. "(" .. players[i].moody .. ")" end return table.concat(ret,"\n")
	end

	
	players = {} -- start with 5 cheaters, 5 copycats and 10 randomplayers
	
	if mode == 1 then
		for i = 1,5 do players[i] = copytable(cheater) end
		for i = 1,5 do players[5+i] = copytable(copycat) end

		for i = 1,10 do players[10+i] = create_random_player(depth) end -- last 10 players are random
		
		
		age = 0
		rom.best_player = nil;
	elseif mode == 2 then
		players = {copytable(realplayer), copytable( create_random_player(4) ) } ;
		self.listen(1)
	end
	--players[20] = copytable(rom.best_player) or create_random_player(depth) -- add best player from before
	--players[20].name = "randomplayer"
		
	
end


if mode == 1 then

	local bestpoints = 0
	for k = 1, generation do -- repeat experiment generation*

		--rom.best_player = nil
		for i = 1,#players do players[i].points = 0 end


		for j = 1, steps do -- several steps to see who is best long term on average
			--for i = 1,#players do players[i].points = 0 end
			group_play(players)
		end
		
		bestpoints = 0

		genetics(players) -- remove 5 worst randomplayers & replace them by new randoms

		
		local population = {}
		bestrandom = 0
		for i = 11,20 do
			if players[i].points >= bestrandom then bestrandom = players[i].points end
			population[#population+1] = players[i]
		end
		--say("randomplayer population size " .. #population)
		sort_players(population);
		if rom.best_player then 
			lastbest = rom.best_player.points
			if bestrandom >= lastbest then -- PICK NEW BEST
				bestc = bestc+1
				rom.best_player = copytable(population[#population]); -- remember best randomplayer for next experiment
			end
		else
			rom.best_player = copytable(population[#population]); -- remember best randomplayer for next experiment
		end
		
	
	end
	
	age = age + generation
	
	--display results!
	msg = ""
	msg = msg .. "Planet Earth (galactical name Halfwits), age " .. age .. ", error_rate " .. error_rate .. ", steps " .. steps .. ", generations " .. generation .. ":\n"
	msg = msg .."\nlast round\n"
	--sort_players(players)
	bestpoints = 0
	for i =1,#players do
		if players[i].points>bestpoints then bestpoints = players[i].points end
		msg = msg .. players[i].name .. ": " .. players[i].points .. " M " .. players[i].mood .. "(" .. players[i].moody .. ")\n"
	end
	local rules = rom.best_player.rules;
	msg = msg .. "BEST: " .. bestpoints .. "\n\n## alltime best random player no. " .. bestc .. ", points " .. rom.best_player.points .. " moody " .. rom.best_player.moody .. 
	"\ncurrent best random player/max current score: ".. math.floor(100*bestrandom/bestpoints*100)/100 .. "% \nrules " .. serialize(rules) .. " )\n";
	
	local msg1 = "{" .. rules[1][1] .. "}\n"
	for i =  2,#rules do
		local rule = rules[i];
		msg1 = msg1.. "{"
		for j = 1,#rule do
			local rule_string = table.concat(dec2bin(j-1),"");
			rule_string = string.rep("0",i-string.len(rule_string)-1) ..  rule_string;
			msg1 = msg1 .. rule_string .."="..rule[j]..","
		end
		msg1 = msg1 .. "}\n"
	end
	
	self.label(msg .. msg1)

elseif mode == 2 then -- play vs player
	
	speaker,msg = self.listen_msg();
	if msg then
		if msg == "0" or msg == "1" then
			local nextmove = tonumber(msg);
			if nextmove == 1 and players[1].out == 1 then 
				say("look buddy, we dont like cheaters around here. dont cheat twice in a row") 
			else
				players[1].out = nextmove
				interact(players[1], players[2])
				say("input " .. players[1].out .. ", BOT MOVES: " .. serialize(players[1].moves) .. " BOT MOOD " .. players[2].mood .. "(" .. players[2].moody .. ") SCORE: you " .. players[1].points .. " bot " .. players[2].points)	
			end
		end
	end
	
	
end