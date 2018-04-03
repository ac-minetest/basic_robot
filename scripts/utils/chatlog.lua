--rnd 2017
if not logdata then
	self.label("chatlog bot");
	_G.minetest.forceload_block(self.pos(),true)
	n = 250;
	idx = 1;
	logdata = {};
	
	insert = function(text) -- insert new message
		idx = idx +1;
		if idx > n then idx = 1 end
		logdata[idx] = text;
	end
	
	last = function(k,filter) -- return last k messages
		if k > n then k = 30 end
		local i,j,ret;
		i=idx;j=0; ret = ""
		
		for j = 1,k do 
			if not logdata[i] then break end
			if filter and not string.find(logdata[i], filter) then
			else
				ret = ret .. logdata[i] .. "\n";
			end
			i=i-1; if i < 1 then i = n end
		end
		return ret
	end
	
	self.listen(1)
end

speaker, msg = self.listen_msg()
if msg then
	if string.sub(msg,1,4) == "?log" then
		local j = string.find(msg," ",6);
		local k = tonumber(string.sub(msg,6) or "") or n;
		local text;
		if j then text = last(k,string.sub(msg,j+1)) else text = last(k) end
		local form = "size[8,8]".. "textarea[0.,0;11.,9.5;text;chatlog;".. text .. "]" 
		self.show_form(speaker, form)
	else
		insert(os.date("%X") .. " " .. speaker .. "> " .. msg)
	end
end