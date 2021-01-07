--text formatting to specified width ( real font width appearance )

if not init then init = true
	width = 13; -- desired width of formatted text
	text = "bereits riskante situationen werden durch die britische variante noch riskanter"
	dout = function(text) say(text,"_") end

	cwidths = { -- how many chars fit into string lenght of 46 repeated a's
		["a"] = 46,	["b"] = 46,["c"] = 57,["d"] = 46,["e"] = 46,
		["f"] = 103,["g"] = 46,["h"] = 46,["i"] = 103,["j"] = 103,
		["k"] = 52,["l"] = 103,["m"] = 32,["n"] = 46,["o"] = 46,
		["p"] = 46,["q"] = 46,["r"] = 83,["s"] = 52,["t"] = 103,
		["u"] = 46, ["v"] = 52,["w"] = 34.5,["x"] = 52,["y"] = 52,
		["z"] = 52,
		[" "] = 103,["."] = 103, [","] = 103,[":"]=103,[";"]=103,
		["?"] = 46,
		
		["0"] = 52,["1"] = 52,["2"] = 46,["3"] = 46,["4"] = 46,
		["5"] = 46,["6"] = 46,["7"] = 46,["8"] = 46,["9"] = 46,
	}

	local ac = cwidths["a"];
	for k,v in pairs(cwidths) do cwidths[k] = ac/v end -- compute lenghts in widths of 'a'

	format_text = function(text,width,cwidths)
		local ret = {};
		local x = 0;
		for word in string.gmatch(text,"%S+") do
			local xw = x; -- remember where we were before word
			local newline = false;
			
			for i = 1, string.len(word) do
				local c = string.sub(word,i,i)
				local w = cwidths[c] or 1
				if c~="\n" then
					x=x+w;
					if x>width then	newline = true end
				else
					ret[#ret+1]=c;x=0; -- adding new line character
				end
			end
			
			if newline then -- add word and space between words if not in newline
				ret[#ret+1] = "\n"..word.. " ";
				x=x+cwidths[" "]
				x=x-xw; -- word width in new line
			else
				x=x+cwidths[" "] 
				ret[#ret+1] = word.." " 
			end 
		end
		return table.concat(ret,"")
	end


	display = function(width)
		local res =  format_text(text, width,cwidths)
		self.label(res)
	end
	
	display(width)
  
  --self.show_form("_",
   --"size[6,6] label[0,0;"..
   --res .. "]" )

--self.remove()
	self.listen(1)
end

speaker,msg = self.listen_msg()
if speaker == "_" then
	display( tonumber(msg) or width)
end