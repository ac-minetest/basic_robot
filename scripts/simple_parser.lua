if not text then
	text = "diamond 3;mese 4;gold 2;diamond 1;"
	function parse(text) 
		ret = {};
		for a,b in text:gmatch("(%w+) (%w+)%;") do
			ret[a] = (ret[a] or 0) + (tonumber(b) or 0)
		end
		return ret
	end
	
	function export(array)
		ret = "";
		for k,v in pairs(array) do
			ret = ret .. (_G.tostring(k) or "") .. " " .. (_G.tostring(v) or "") ..";"
		end
		return ret
	end
	say("input: " .. text)
	local arr = parse(text);
	say("parsed text: " .. string.gsub(_G.dump(arr),"\n",""))
	say("back to string :" .. export(arr))
end