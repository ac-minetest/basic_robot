-- cheat trust game by rnd, made in 60 minutes
-- http://ncase.me/trust/

--[[
	TO DO: 
	hierarchies, they determine who plays with who (boss plays only with his direct underlings)
	fakers: they give fake +points
--]]


if not init then
	init = true
	if not find_player(6) then error("#TRUST GAME: no players near") end
	
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

	error_rate = 0.0; -- 10% probability we take wrong decision
	
	grudger = 
	{
		name = "grudger",
		opponent = {}, -- list of opponent moves from previous games,
		state = 1, -- internal state, for grudger it means how he plays next move
		reset = function(self)
			self.state = 1;	self.opponent = {};
		end,		
		game = function(self) -- how will we play next move
			if self.state == 1 then
				local opp = self.opponent;
				if #opp>0 and opp[#opp] == 2 then self.state = 2 end -- you cheat me once and we are done, pardner.
			end
			return self.state
		end,
		err = error_rate, -- probability we make different decision 
	}
	
	cheater = 
	{
		name = "cheater",
		opponent = {}, -- list of opponent moves from previous games,
		reset = function(self)
			self.opponent = {};
		end,
		game = function(self)
			return 2
		end,
		err = error_rate, -- probability we make different decision 
	}
	
	cooperator = 
	{
		name = "cooperator",
		opponent = {}, 
		reset = function(self)
			self.opponent = {};
		end,
		game = function(self)
			return 1
		end,
		err = error_rate, -- probability we make different decision 
	}
	
	copycat =
	{
		name = "copycat",
		opponent = {},
		reset = function(self)
			self.opponent = {};
		end,
		game = function(self)
			local opp = self.opponent;
			if #opp>0 then return opp[#opp] else return 1 end -- i do to you what you did to me last move
		end,
		err = error_rate, -- probability we make different decision 
	}
	
	fcopycat =
	{
		name = "forgiving copycat",
		opponent = {},
		reset = function(self)
			self.opponent = {}; self.state = 0; self.cheat = 0;
		end,
		state = 0,
		cheat = 0,
		game = function(self)
			local opp = self.opponent;
			if #opp>0 then 
				if opp[#opp] == 2 then -- you cheat me
					if self.state == 1 then self.cheat = self.cheat+ 1 else self.state = 1 end -- cheat in a row
				else 
					self.state = 0
					self.cheat = 0
				end 
				if self.cheat >= 1 then -- fk you 
					return 2 
				else -- you cheated me less than 2x, its still cool
					return 1
				end
			else -- first time
				return 1 
			end
		end,
		err = error_rate, -- probability we make different decision 
	}
	
	
	detective = 
	{
		name = "detective",
		opponent = {},
		moves = {1,2,1,1}, -- starting 4 moves
		step = 0, -- what move we played so far
		state = 0,
		reset = function(self)
			self.state = 0;	self.step = 0; self.opponent = {};
		end,
		game = function(self) -- how will we play next move
			local st = self.step+1;
			self.step =  st;
			local opp = self.opponent;
			
			if st < 5 then
				if self.state == 0 and opp[#opp] == 2 then self.state = 1 end -- i caught you cheating!
				return self.moves[st]
			end
			
			if self.state == 0 then -- exploiter
				return 2
			else -- copycat
				if #opp>0 then return opp[#opp] end -- copycat
			end
			return self.state
		end,
		err = error_rate, -- probability we make different decision 
	}
	
	--  internal functions
	
	Player = {}
	function Player:new (o)
	  ret = {}; _G.setmetatable(ret, self); self.__index = self
	  for k,v in pairs(o) do ret[k] = v end
	  ret.points = 0
	  return ret
	end
	
	gamestep = function(player1,player2)
		local res1 = player1:game(); if math.random(1000)<=1000*player1.err then res1 = 3-res1 end
		local opponent = player2.opponent;
		opponent[#opponent+1] = res1; -- player2 remembers player1 move
		local res2 = player2:game(); if math.random(1000)<=1000*player2.err then res2 = 3-res2 end
		opponent = player1.opponent;
		opponent[#opponent+1] = res2; -- player1 remembers player2 move
		local res = rules[res1][res2];
		player1.points = player1.points + res[1];
		player2.points = player2.points + res[2];	
		return res1,res2 -- return what players did
	end
	
	paired_match = function(player1,player2, rounds)
		player1:reset();player2:reset()
		for i = 1, rounds do
			gamestep(player1,player2)
		end
	end
	
	sort_players = function(players)
		table.sort(players, 
			function(p1,p2) return p1.points<p2.points end
		) -- sorts in ascending order of points
	end
	
	group_match = function(players,elimination) -- each player plays once with every other player
		local n = #players;
		local m = 10; -- play m games with each opponent
		for i = 2,n do
			for j = 1,i-1 do
				if math.random(2) == 1 then 
					paired_match(players[i],players[j],m) 
				else
					paired_match(players[j],players[i],m)
				end
			end
		end
		
		if elimination then
			sort_players(players)
			for i = 1,5 do -- replace 5 worse players with clones of 5 best players
				local points2 = players[#players-i+1].points;
				if points2 then 
					local points1 = players[i].points;
					if points1<points2 or (points1==points2 and math.random(2) == 1) then
						players[i] = Player:new( players[#players-i+1] );
						players[i].points = points2;
					end
					
				end
			end
		end
		
	end

	get_results = function(players)
		local msg = colorize("red","player results\n")
		for j = 1, #players do -- display final results
			msg =  msg .. j .. ". " .. players[j].name .. ": points " .. players[j].points .. "\n"
		end
		return msg
	end
	
	
	-- SIMULATION START
	
	self.spam(1)
	_G.math.randomseed(os.time())
	
	players = {Player:new(grudger), Player:new(cheater), Player:new(cooperator), Player:new(copycat),Player:new(detective)} --,Player:new(fcopycat)} 
	
	M = 10000; -- do 1000 matches, make average later
	for i = 1, M do
		group_match(players) -- SIMPLE GROUP MATCH, everyone play 1x vs everyone else (random player ordering in single match)
	end
	for i =1,#players do players[i].points = players[i].points/M end
	
	
	
	
	-- players = {}
	-- for i = 1, 5 do	players[#players+1 ] = Player:new(grudger) end
	-- for i = 1, 5 do	players[#players+1 ] = Player:new(cheater) end
	-- for i = 1, 5 do	players[#players+1 ] = Player:new(cooperator) end
	-- for i = 1, 5 do	players[#players+1 ] = Player:new(copycat) end
	-- for i = 1, 5 do	players[#players+1 ] = Player:new(detective) end
	-- group_match(players)
	
	-- for i = 1, 10 do-- play 10 matches with elimination
		 -- group_match(players,true)
	-- end
	
	sort_players(players)
	self.label("10000 rounds + averaged, error rate = " .. error_rate .."\n" .. get_results(players)  .. "comment: under 6.2% error copycats more succesful, but above 6.2% cheaters. at 50% error everyone same")
	players = nil; -- clear up
	
	
	--STEP BY STEP DUAL VS 2 PLAYERS
	-- players = {Player:new(grudger),Player:new(detective)};
	-- step = 0;
	-- say("#game start")
	-- for i = 1, 10 do
		-- step = step +1
		-- local res1,res2;
		-- res1,res2 = gamestep(players[1],players[2])
		-- say("step " .. step .. ": " .. players[1].name .. " " .. res1 .. " -> "  .. players[1].points .. " VS " .. players[2].name .. " " .. res2 .. " -> " .. players[2].points);
	-- end
	
end