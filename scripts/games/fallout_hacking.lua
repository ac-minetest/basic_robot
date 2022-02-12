-- 'hacking' game from Fallout, by rnd
if not init then
	init = true
	
	max_guesses = 4 -- how many guesses player gets
	n = 40; -- how many options
	pass_length=5
	charset_size=10 -- a,b,c,d,e,...?
	cols = 4;
	rows = math.ceil(n/cols);

	generate_random_string = function(n,m)
		local ret = {};
		for i = 1,n do ret[i]=string.char(math.random(m)+96) end --24
		return table.concat(ret)
	end
	
	get_similiarity = function(text1,text2)
		local n = string.len(text1);
		if string.len(text2)~=n then return 0 end
		local ret = 0;
		for i = 1,n do
			if string.sub(text1,i,i) == string.sub(text2,i,i) then ret = ret + 1 end
		end
		return ret
	end
	
	get_form = function()
		local n = #passlist;
		
		local frm = "label[0,0;" .. intro_msg .. "] " .. "label[0,8.5;" .. msg .. "] "
		local k = 0
		for i=0,cols-1 do
			for j = 1,rows do
				k=k+1; if k>n then break end
				frm = frm .. "button[" .. 2*i.. ",".. j*0.75 ..";2,1;" .. k .. ";".. passlist[k] .. "] "
			end
		end
		local form = "size[" .. 2*cols .. "," .. 9 .. "]" .. frm;
		return form
	end

	_G.math.randomseed(os.time())
	intro_msg = minetest.colorize("lawngreen","FALLOUT PASSWORD HACKING GAME\nmatch is both position and character.")
	msg = "" --TEST\nTEST\nTEST";
	passlist = {}; passdict = {}
	
	
	
	count = 0;
	while count< n do
		local pass = generate_random_string(pass_length,charset_size); -- password length, charset size
		if not passdict[pass] then passlist[#passlist+1] =  pass; passdict[pass] = true; count = count + 1 end
	end
	correct = math.random(n)
--	say(passlist[correct])
	guesses = 0
	

	rom.data = {};
	if not rom.data then rom.data = {} end	
	self.spam(1)
	
	local players = find_player(4);
	if not players then say("#fallout hacking game: no players") self.remove() end
	pname = players[1];
	minetest.chat_send_player(pname,"#fallout hacking game, player " .. pname)

	--if rom.data[pname] then say("password is locked out!") self.remove() end
	
	self.show_form(pname,get_form())
	self.read_form()
		
end

sender,fields = self.read_form()
	if sender and sender == pname then -- form event
		local pl = _G.minetest.get_player_by_name(pname);
		if pl then
				local selected = 0
				for k,_ in pairs(fields) do	if k~="quit" then selected = tonumber(k) break end end
				
				if selected>0 then
					guesses = guesses + 1
					if selected == correct then 
						minetest.chat_send_all("#FALLOUT HACKING: " .. pname .. " guessed the password " .. passlist[correct]  .. " after " .. guesses .. " guesses.")
						self.show_form(pname, "size[3,1] label[0,0.5;" .. minetest.colorize("lawngreen", "ACCESS GRANTED") .. "]")
						self.remove()
						--correct: do something with player
					else
						if guesses == 3 then msg = msg .. "\n" end
						msg = msg .. " " .. minetest.colorize("yellow",guesses .. ". " .. passlist[selected]) .. " (" .. get_similiarity(passlist[correct], passlist[selected]) .. " match)"
						self.show_form(pname, get_form())
					end
					if guesses>=max_guesses then 
						msg = minetest.colorize("red","A C C E S S  D E N I E D!")
						self.show_form(pname, get_form())
						minetest.chat_send_player(pname,"too many false guesses. password locked out!") rom.data[pname] = 1; self.remove()
					end					
				end
		if fields.quit then self.remove() end
		end
	end