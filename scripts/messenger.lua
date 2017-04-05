if not s then
	s=0
	msgsize = 2500;
	_,text = book.read(1);text = text or "";
	write_msg = function(sender,msg)

		local newsize = string.len(text)+string.len(msg);
		if newsize>msgsize then return "messages space exceeded" end
		text = text .. "\n"..os.date() .. " " .. sender .. ": " .. msg; 
		book.write(1,"messages",text)
	end

end

--textarea[X,Y;W,H;name;label;default]
--button[X,Y;W,H;name;label]
if s == 0 then
	players = find_player(4);
	if players and players[1] then
		s=1
		local form = "size[8,4.5]" ..
		"textarea[0,0;9,4.5;msg;MESSAGE FOR ADMIN;]"..
		"button_exit[-0.5,4.15;2,1;send;send]"
		self.show_form(players[1],form)
	end
elseif s==1 then
	sender,fields = self.read_form();
	if sender then
		if fields.send then
			msg = fields.msg;
			if msg and msg~="" then
				write_msg(sender,msg);activate.up(1)
				_G.minetest.chat_send_player(sender,"#mailbot: message has been stored")
			end
		end
		self.remove()
	end
end