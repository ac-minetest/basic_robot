--rnd 2017
if not logdata then
	self.label("chatlog bot");
	_G.minetest.forceload_block(self.pos(),true)
	n = 500; -- store so many messsages before repeating
	maxresults = 100 -- display at most 'this' result

	logdata = {}; -- circular array to hold messages
	idx = 1;
	insert_log = function(logdata,text) -- store new message
		idx = idx +1;
		if idx > n then idx = 1 end
		logdata[idx] = text;
	end
	
	retrieve_log = function(logdata,count,filter) -- return last k messages, with filter only selected messages
		
		local k = 0;
		local i=idx; local j=0; local ret = {}
		
		for j = 1,n do 
			if not logdata[i] then break end
			if filter and not string.find(logdata[i], filter) then
			else
				ret[#ret+1] = logdata[i]
				k=k+1
				if k>=count then break end -- enough results
			end
			i=i-1; if i < 1 then i = n end
		end
		return table.concat(ret,"\n")
	end
	
	self.listen(1)
end

speaker, msg = self.listen_msg()
if msg then
	if string.sub(msg,1,4) == "?log" then
		local j = string.find(msg," ",7); -- find first argument
		local k;local text;
		if j then k = tonumber(string.sub(msg,6,j-1)) else k = tonumber(string.sub(msg,6)) end -- if there was first argument find second
		k = k or maxresults;
		if j then text = retrieve_log(logdata,k,string.sub(msg,j+1)) else text = retrieve_log(logdata,k) end
		local form = "size[8,8]".. "textarea[0.,0;11.,9.5;text;chatlog;".. text .. "]" 
		self.show_form(speaker, form)
	else
		insert_log(logdata, os.date("%X") .. " " .. speaker .. "> " .. msg)
	end
end