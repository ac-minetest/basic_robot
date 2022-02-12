if not get_hash then

	get_hash = function(s,p)
		if not s then return end
		local h = 0; local n = string.len(s);local m = 4; -- put 4 characters together
		local r = 0;local i = 0;
		while i<n do
			i=i+1;r = 256*r+ string.byte(s,i);
			if i%m == 0 then h=h+(r%p) r=0 end
		end
		if i%m~=0 then h=h+(r%p) end
		return h%p
	end
	
	
	hashdb = {}; --array with entries: [hash] = list of possible hits
	
	insert = function(key,value)
		local hash = get_hash(key,10011);
		local data = hashdb[hash]; if data == nil then hashdb[hash] = {}; data = hashdb[hash] end
		data[#data+1]={key,value};
		return hash
	end
	
	lookup = function(key)
		local hash = get_hash(key,10011);
		if not hash then return end
		local data = hashdb[hash];
		if not data then return nil end
		for i = 1,#data do
			if data[i][1]==key then return data[i][2] end
		end
		return nil
	end
	
	analyse = function()
		local count = 0; local maxlen = 0; local maxidx = 1; local n = #hashdb;
		for i = 1, 10000 do
			local data = hashdb[i];
			if data then
				local length = #data;
				if length > maxlen then maxlen = length; maxidx = i end
				count = count + 1
			end
		end
		
		if maxlen>0 then
			local data = hashdb[maxidx];
			say("number of used hash entries is " .. count .. ", average " .. (step/count) .. " entries per hash, "..
			" max length of list is " .. maxlen .. " at hash ".. maxidx )--.. " : " .. 
			--string.gsub(_G.dump(data),"\n","")  )
			
		end
	end
	
	-- LOAD DICTIONARY WORDS into hashtable
	
	lang = "german"

	fname = "F:\\games\\rpg\\minetest-0415server\\mods\\basic_translate\\"..lang;
	local f = _G.assert(_G.io.open(fname, "r"));local dicts = f:read("*all");f:close()

	step = 0; maxwords = 10000;
	i=0
	dict = {}; -- for comparison
	
	while(step<maxwords) do
		
		step=step+1
		i1 = string.find(dicts,"\t",i+1)
		i2 = string.find(dicts,"\n",i+1)
	
		if not i2 then break end
		
		local word = string.sub(dicts, i+1,i1-1);
		local tword = string.sub(dicts, i1+1,i2-1);
    	insert(word, tword) -- load into hashtable
		dict[word]=tword
    	i=i2
	end
	
	self.listen(1)
	self.spam(1)
	say(step .. " words loaded")
end

-- handle chat event
speaker,msg = self.listen_msg()

if msg then
	if msg == "?*" then
		local n = 1000000; local msg = "hello"
		local ret = "";
		local t1 = os.clock();
		for i = 1, n do ret = lookup(msg) end; t1 = os.clock()-t1;
		local t2 = os.clock();
		for i = 1, n do ret = dict[msg] end
		t2 = os.clock()-t2;
		say(t1 .. " " .. t2)
	
	elseif msg == "??" then
		analyse()
	elseif string.sub(msg,1,1)=="?" then
		msg = string.sub(msg,2);
		local ret = lookup(msg);
		if ret then say("found entry for " .. msg .. " : " .. ret) else say("entry not found") end
	end
end