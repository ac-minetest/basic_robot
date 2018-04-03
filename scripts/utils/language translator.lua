if not dict then
	lang = "german"
	dict = {};
	fname = "F:\\games\\rpg\\minetest-0415server\\mods\\basic_translate\\"..lang;
	local f = _G.assert(_G.io.open(fname, "r"));local dicts = f:read("*all");f:close()

	step = 0; maxwords = 10000;
	i=0
	
	while(step<maxwords) do
		
		step=step+1
		i1 = string.find(dicts,"\t",i+1)
		i2 = string.find(dicts,"\n",i+1)
	
		if not i2 then break end
		
		local word = string.sub(dicts, i+1,i1-1);
		local tword = string.sub(dicts, i1+1,i2-1);
		local word1; local word2;local data;
		i12 = string.find(word," ");
		
		if i12 and i12<i2 then 
			word1 = string.sub(word,1,i12-1); word2 = string.sub(word,i12+1) 
			data = dict[word1];
			if not data then 
				dict[word1] = {{[word2] = tword}} 
			else
				data[#data+1] = {[word2] = tword};
			end
		else
			data = dict[word];
			if not data then 
				dict[word] = {{[""] = tword}} 
			else
				data[#data+1] = {[""] = tword};
			end
		end
		--say("X"..word.."X"..tword)
		i=i2
	end
	
	say(lang .. " dictionary: ".. step .. " words loaded")
--	self.label(string.gsub(_G.dump(dict),"\n",""))
	
	local deb = false;
	translate = function(input)
		local out = "";
		input = string.lower(input)
		local i = 0; local n = string.len(input)
		local step  = 0
		while i and i<n and step < 100 do
			step = step + 1
			local i1 = string.find(input," ",i+1);
			local word;
			if not i1 then --end
				word = string.sub(input, i+1) 
			else  -- just take one word until " "
				word = string.sub(input, i+1, i1-1) 
			end
			
			i1 = i+string.len(word)+1
			if deb then say("parsed word " .. word .. " remainder '" .. string.sub(input, i1).."'") end

			local data = dict[word];
			if data then
				if #data == 1 then 
					local newout = data[1][""];
					if not newout then
						for key,v in pairs(data[1]) do newout = v; i1 = i1 + string.len(key)+1 break end
					end
					out = out .. " " .. newout
					if deb then say("immediate trans for " .. word) end
				else -- more possibilities
					if deb then say("more possibilities : ".. #data) end
					--check patterns for match:like a de -> c or a b -> d, where data for a  = {{[de] = c},{[b] = d}
					local found = false
					local defaultv = ""
					
					
					for j=1,#data do
						
						for key,v in pairs(data[j]) do
							local keylen = string.len(key)
							local pattern = string.sub(input,i1+1,i1+keylen)
							if deb then say("pattern '" .. pattern .. "' key '" .. key .. "' len " .. keylen) end
							if key == "" then defaultv = v 
							elseif pattern == key then
								found = true;
								if deb then say(word .. " " .. pattern .. " -> match key " .. key) end
								out = out .. " " .. v; i1 = i1+string.len(key)+1 -- skip to after key
							end
						end
						if found then break end
					end
					
					if not found then out = out .. " " .. defaultv end
					
				end
			else
				out = out .. " " .. word
			end
			i=i1
			if deb then say("next word at i " .. i1 .. " remainder " .. string.sub(input,i1)) end
		end

		return out
	end
	
	--	say(translate("hello world"))
	self.listen(1)
end



speaker,msg = self.listen_msg()
if msg then
	if string.sub(msg,1,1) == "?" then 
		msg = string.sub(msg,2)
		local transmsg = translate(msg);
		_G.minetest.chat_send_all("TRANSLATOR> " .. transmsg)
	end
end