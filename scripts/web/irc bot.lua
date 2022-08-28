-- irc_bot, 05/02/2022 by rnd
-- adds irc bot commands with password login

if not init then init = true
	_G.basic_robot.ircbot = {}; ircbot = _G.basic_robot.ircbot
	ircbot.user_list = {} -- [user] = true, must login first
	
	ircbot.auth_data = {  -- [user] = {pass_hash,level,robot_name}
		["r_n_d"] = {"5yfRRkrhJDbomacm2lsvEdg4GyY",3,"rnd1"},
		["Noah"] =  {"5yfRRkrhJDbomacm2lsvEdg4GyY",3,"noah1"}
	}; --
	
	robotname = self.name()
	
	_G.irc.register_bot_command("c", {
		params = "",
		description = "",
		func = function(usr,msg)
			
			-- user not logged in yet?
			local lvl = ircbot.user_list[usr.nick]
			if not lvl then
				if msg == "" then return false,"basic_robot: login first using: c $password" end
				if not ircbot.auth_data[usr.nick] then return false, "basic_robot: you are not in user database. please contact server admin." end
				
				if ircbot.auth_data[usr.nick][1] == minetest.get_password_hash("", msg) then
					ircbot.user_list[usr.nick] = ircbot.auth_data[usr.nick][2]
					local msg = "basic_robot: Logged in as " .. usr.nick ..", level " .. ircbot.user_list[usr.nick]
					lvl = ircbot.auth_data[usr.nick][2]
					local robotname = ircbot.auth_data[usr.nick][3]
					if lvl>=3 then msg = msg .. ". you can use 'c !lua_cmd' to run lua_cmd in robot " .. robotname .. " sandbox" end
					return false, msg
				else
					return false,"basic_robot: wrong password!"
				end
			end
		
			-- action here : DEMO just displays message once logged in
			local c = string.sub(msg,1,1)
			if c~="!" or lvl<3 then _G.basic_robot.ircmsg = msg return end
			
			local ScriptFunc, CompileError = _G.loadstring( string.sub(msg,2))
			if CompileError then return false, CompileError end
			
			local robotname = ircbot.auth_data[usr.nick][3]
			_G.setfenv( ScriptFunc, _G.basic_robot.data[robotname].sandbox ) -- run code in robot sandbox
			local Result, RuntimeError = _G.pcall( ScriptFunc );
			if result then return false, _G.tostring(Result) end
			if RuntimeError then return false,RuntimeError end
			
			
		end
	})

  -- how to send msg to irc user
  ircchat = minetest.registered_chatcommands["irc_msg"].func;
  name = "r_n_d" -- client on irc you want to send msg too
	--  ircchat("ROBOT", name .." " .. "hello irc world") -- chat will appear as coming from <ROBOT> on skyblock
end


self.label(_G.basic_robot.ircmsg or "")