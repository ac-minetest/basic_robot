--SERVER ROBOT : can send various data to other robots that requested it
if not cmds then

-- user auth data
auth = {["rnd1"]=2};

-- server commands
cmds = {
	list = {
		run = function() 
			local ret = "";	for i,_ in pairs(cmds) do ret = ret .. " " .. i end; return ret
		end,
		help = "list all commands",
		level = 0
	},
	
	help = {
		run = function(words)
			local arg = words[2];
			if not arg then return "help: missing argument" end
			local cmd = cmds[arg];
			if not cmd then return "help: nonexistent command" end
			return cmd.help or "" 
		end,
		help = "display help for command",
		level = 0
	},
	
	chat = {
		run = function(words)
			words[1] = "";_G.minetest.chat_send_all("#server bot : " .. table.concat(words," ") or "");	return true;
		end,
		help = "prints text globally",
		level = 2	
	},
	
	minetest = {
		run = function() return minetest end,
	help = "returns minetest namespace",
	level = 3
	}

};

LISTENING = 0; --states
state = LISTENING; -- init
_G.minetest.forceload_block(self.pos(),true)
end



if state == LISTENING then
	sender,mail = self.read_mail()
	if mail then
		if type(mail)~="string" then mail = "" end
		self.label("received request " ..  mail);
		local words = {};
		for word in string.gmatch(mail,"%S+") do words[#words+1]=word end -- get arguments
		if not words or not words[1] then 
			self.send_mail(sender,"error: nil request") 
		else
			local cmd = cmds[words[1]];
			if not cmd or not cmd.run then 
				self.send_mail(sender,"error: illegal command") 
			elseif (auth[sender] or 0) < cmd.level then 
				self.send_mail(sender,"error: auth level " .. (auth[sender] or 0) ..", need level " .. cmd.level) 
			else
				self.send_mail(sender,cmd.run(words));
				self.label("sending data to " .. sender .. " ...")
			end
		end
	else
		self.label("listening...")
	end

end