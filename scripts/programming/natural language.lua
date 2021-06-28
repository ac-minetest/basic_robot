	-- "natural language" programming demo by rnd, 2021
	-- input is lines of 'natural' language, will be translated into lua code

	--[[
	move forward 3
	turn left
	dig left
	if see dirt turn left and move forward
	
	subroutine circle commands..

	--> TRANSFORMED into lua :

	for i = 1,3 do move.forward(); pause(); end
	turn.left(); pause();
	dig.left(); pause()
	if read_node.forward()=="dirt" then turn.left();pause(); move.forward(); pause() end
	
	TODO: integrate into robots, maybe command: code.natural(..)
	--]]

if not init then init = true
	
	prog = [[
	subroutine walk
	if see air move forward and move down
	if see dirt move up
	if see wood turn right
	subroutine end
	
	walk	
	]]
	
	subroutines = {}; -- [subname] = true , so we know its subroutine
	
	nodenames = -- translation of block names into minetest
	{
		["dirt"] = "default:dirt",
		["cobble"] = "default:cobble",
		["stone"] = "default:stone",
		["wood"] = "default:wood",
		["water"] = "default:water_source",
	}

	keywords = {
		["quit"] = function() return "break;" end,
		["move"] = {
			["forward"] = function() return "if move.forward() then pause();paused=true; end;" end,
			["backward"] = function() return "if move.backward() then pause();paused=true; end;" end,
			["left"] = function() return "if move.left() then pause();paused=true; end;" end,
			["right"] = function() return "if move.right() then pause();paused=true; end;" end,
			["up"] = function() return "if move.up() then pause();paused=true; end;" end,
			["down"] = function() return "if move.down() then pause();paused=true; end;" end,
		},
		
		["turn"] = {
			["left"] = function() return "turn.left(); pause();paused=true;" end,
			["right"] = function() return "turn.right(); pause();paused=true;" end,
			["random"] = function() return "if math.random(2)==1 then turn.right() else turn.left() end; pause(); paused=true;" end
		},
		
		["dig"] = function() return "dig.forward(); pause();" end, --TODO: remember to set robot energy to large value at start
		
		["place"] = function(line) 
			local pattern1 = "place";
			local i = string.find(line,pattern1)+ string.len(pattern1)+1
			local nodename = string.sub(line, i) --  what are we placing?
			if nodenames[nodename] then nodename = nodenames[nodename] end -- translate name
			return "place.forward('" .. nodename .. "'); pause();" 
		end, 
		
		["if"] = {
			["see"] = function(line) 
				
				local pattern1 = "see";
				local pattern2 = "and" .. " "; -- important, space after 'and'
				
				local i = string.find(line,pattern1) + string.len(pattern1) + 1
				--nodename command
				local j = string.find(line," ",i)
				local nodename, command
				nodename = string.sub(line,i,j-1)
				if nodenames[nodename] then nodename = nodenames[nodename] end -- translate name
				-- maybe command has several parts separated by 'and' ?
				--cmd1 and cmd2 and cmd3
				j = j+1; local cmds = {}; local found = false
				while true do
					local k = string.find(line,pattern2,j+1)
					if not k then-- no more AND
						if found then 
							cmds[#cmds+1] = string.sub(line,j + string.len(pattern2)) break 
						else
							cmds[#cmds+1] = string.sub(line,j) break 
						end
					end
					if found then
						cmds[#cmds+1] = string.sub(line,j+string.len(pattern2),k-1)
					else
						cmds[#cmds+1] = string.sub(line,j,k-1)
					end
					found = true
					j=k
				end
				
				for i = 1,#cmds do
					cmds[i] = parse_line(cmds[i])
				end
				
				return "if read_node.forward()=='" ..nodename .. "' then " .. table.concat(cmds," ") .. " end"
			end,
		},
	}

	parse_line = function(line)
		local struct = keywords;
		for word in string.gmatch(line,"%S+") do
				local matched = struct[word]
				local issub = subroutines[word]
				if matched or issub then
					--say(word .. " = "  .. type(matched))
					if type(matched) == "table" then
						struct = matched; -- climb deeper into structure
					else
						local instruction;
						if issub then 
							instruction = word.."();"
						else
							instruction = matched(line)
						end
						
						-- do we have need to repeat instruction?
						local i = string.find(line,word) + string.len(word) + 1
						local snum = tonumber(string.sub(line,i)) or 1 -- repeating?
						if snum>1 and snum<10 then
							return "for i = 1,"..snum .." do " .. instruction .. " end;"
						end
						return instruction
					end
				else
					say("error in line: " .. line .. ", unknown command " .. word) return ""
				end
			end
	end

	parse_prog = function(code)
		local out = {};
		local subdef = false; -- are we defining subroutine?
		local subname;
		local subcmds = {}
		local pattern1 = "subroutine"
		
		for line in string.gmatch(code,"[^\n]+") do -- line by line
			
			local i = string.find(line,pattern1)
			if i then -- do we define new subroutine command?
				local j = i+string.len(pattern1)+1
				local sname = string.sub(line,j)
				if subdef and sname == "end"  then -- end of subroutine
					subdef = false 
					if not keywords[subname] then
						out[#out+1 ]  = "function " .. subname .. "()\n" .. table.concat(subcmds,"\n") .. "\nend"
						subroutines[subname] = true;
					else
						-- error, subroutine name is reserved keyword
					end
					subcmds = {};
				else
					subdef = true -- all commands will now register with subroutine
					subname = sname
				end
			else -- normal command
				if subdef then
					subcmds[#subcmds+1] = parse_line(line)
				else
					out[#out+1] = parse_line(line)
				end
			end
			
		end
		return "--coroutine NaturalLanguage autogenerated\nwhile true do paused = false; "..table.concat(out,"\n") .."if not paused then pause() end  end"
	end

	parsed_prog = parse_prog(prog)
	self.label(prog .. "\n\n==>\n\n" .. parsed_prog)
	code.set(parsed_prog) -- actually run code by robot

end