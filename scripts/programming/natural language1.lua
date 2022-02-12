-- Natural language compiler, outputs lua code
-- (C) rnd 2021
-- TODO: add IF: if condition arg1 ACTION1 else ACTION2 ?
-- ADD SUBROUTINE: sub NAME = enter subroutine definition mode, sub end = ends definition mode

if not init then init = true
    dtext = {};
	dout = function(text) dtext[#dtext+1] = text end
	text = 
	[[
	if cond1 value action1 and action2 and action3 else actiona1 and actiona2	
	]]
	
	translate =	{ -- dictionary of used words
		["forward"] = "forward",
		["backward"] = "backward",
		["left"] = "left",
		["right"] = "right",
		["random"] = "random",
		["dirt"] = "default:dirt",
		["wood"]= "default:wood",
		["cobble"] = "default:cobble",
	}
	
	cmds = {
		["if"] = function(code,ibeg,iend) -- if COND value ACTION1 and ACTION2 and ... ACTIONn else(optional) ACTION1 and ... and ACTIONm
			-- COND: 'see' nodename (block right in front), 'var = value' value of variable?,...
			local ELSE = " else"
			local AND = " and"
			local i,j,condtype,value;
			condtype, j = get_next_word(code,ibeg,iend)
			local out = {};
			dout(condtype)

			if condtype== "see" then
				value, j = get_next_word(code,j,iend)
				value = translate(value or "");
				if not minetest.registered_nodename(value) then say("error: unknown block name " .. value .. "used in 'if'") return "" end
				out[#out+1] = "if read_node.forward() == " .. value .. " then ";
			else 
				say("error: unknown condition " .. condtype .. " used in 'if'") return "" end
			end
			-- now after j left: ACTION1 else(optional) ACTION2, ACTION can be multiple, separated by ' and '
			
			
			-- parse and before else
			local k = j;
			lcoal cmds = {}
			while k do
				k = string.find(code,AND,j)
				if k and k<ielse then
					cmds[#cmds+1] = string.sub(code,j,k-1)
					j=k+1;
				else 
					break
				end
			end
			
			dout(table.concat(cmds,"\n"))
			
			
			--j=...
			out[#out+1] = "end"
			
			
			return table.concat(out," "),j
			
		end,
		
		["move"] = function(code,ibeg,iend)
			-- move forward count
			local i,direction,count
			direction,i = get_next_word(code,ibeg,iend)
			direction = translate[direction];
			if not direction then say("error: unknown direction used in 'turn'") return "" end 
			return "move."..direction .."(); pause();",i;
		end,
		
		["turn"] = function(code,ibeg,iend)
			-- move forward count
			local i,direction,count
			direction,i = get_next_word(code,ibeg,iend)
				
			direction = translate[direction];
			if not direction then say("error: unknown direction used in 'turn'") return "" end 
			local c;
			if direction == "random" then
				c = "if math.random(2) == 1 then turn.left() else turn.right() end;";
			else
				c = "turn."..direction .."();"
			end
			return c.." pause();",i
		end,
		
		["dig"] = function() return "dig.forward(); pause();" end,
		
		["place"] = function(code,ibeg,iend)
			-- place nodename
			local nodename,i
			nodename,i = get_next_word(code,ibeg,iend)
			nodename = translate[nodename]
			if not nodename then say("error: unknown nodename used in 'place'") return "" end 
			
			return "place.forward('" .. nodename .. "'); pause();",i
		end, 
		
	}
	
	-- given position ibeg in string find next word, return it and then return position immediately after word.
	-- word is defined as a sequence of alphanumeric characters (%w)
	-- example 'hello world', ibeg = 1. -> 'hello', 6

	get_next_word = function(code, ibeg,iend) -- attempt to return next word, starting from position ibeg. returns word, index after word
		if not ibeg or not iend then return end
		local j = string.find(code,"%w",ibeg); -- where is start of word?
		if not j or j>iend then return "", iend+1 end -- no words present
		ibeg = j;
		j = string.find(code,"%W",j);--where is end of word?
		if not j or j>iend then return string.sub(code,ibeg,iend-1),iend+1 end
		return string.sub(code,ibeg,j-1), j
	end


	parse_code = function(code)
		local out = {};
		local ibeg,iend,word;
		local clen = string.len(code)
		local step =0
		
		iend = 1; ibeg = 1;
		while step < 10 do
			if ibeg>clen then break end
			step = step+1
			iend = string.find(code, "\n", ibeg)
			if not iend then iend = clen end -- get out of loop, no more lines to process
			
			word, ibeg = get_next_word(code,ibeg,iend)
			--dout("rem " .. string.sub(code,ibeg,iend))
			--dout("Dword '" .. word .. "' " .. ibeg .. " " .. iend)
			local cmd = cmds[word];
			
			if cmd then out[#out+1],ibeg = cmd(code,ibeg,iend) end
			if not ibeg then ibeg = iend+1 end
			if ibeg<=iend then -- still some space remaining in line, last parameter is repetition
				local count,i
				count,i = get_next_word(code,ibeg,iend); 
				count = tonumber(count) or 1 
				if count>9 then count = 9 elseif count<1 then count=1 end
				if count > 1 then out[#out] = "for i=1,"..count.. " do " .. out[#out] .. " end" end
			end
			ibeg = iend +1 -- go new line
		end
		return table.concat(out,"\n")
	end
	
	
	self.label(parse_code(text) .. "\n\n" .. table.concat(dtext,"\n"))
end