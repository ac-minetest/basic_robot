-- webcommands : access url like: 192.168.0.10/hello_world 

--[[ instructions:
	1.download nodejs server from
		https://nodejs.org/dist/v10.14.2/node-v10.14.2-win-x86.zip
	2. run nodejs server using run.bat
		:loop
			node $path/minetest_webcommands.js
		goto loop
	3. run robot and type 'http://192.168.0.10/webmsg/hello this is a test' into browser
	(you need to write your router address here, i.e. ip accessible from  internet OR lan address)
--]]

if not fetch then
	address = "192.168.0.10";
	fetch = _G.basic_robot.http_api.fetch;
	state = 0 -- ready to fetch new command
-- WARNING: this is run outside pcall and can crash server if errors!
	result = function(res)  -- res.data is string containing result
	  state = 0
	  if not res.succeeded then self.label("#ERROR: data couldn't be downloaded :\n" .. minetest.serialize(res) ) return end
	  if res.data == "" then return end
	  local req = res.data; req = string.gsub(req,"%%20"," ")
	  if res.data then 
		self.label(os.date("%X") ..', cmd : ' .. req)
		local i = string.find(req," !")
		if i then
			run_commmand(string.sub(req,i+2))
		end
	end
	end
	
	admin = minetest.setting_get("name")
	run_commmand = function(message)
		local cmd, param = _G.string.match(message, "([^ ]+) *(.*)")
			if not param then
				param = ""
			end
			local cmd_def = minetest.chatcommands[cmd]
			if cmd_def then
				cmd_def.func(admin, param)
			else
				minetest.chat_send_all(admin..": "..message)
		end
	end
	
	MT2web = function(message)
		message = string.gsub(message," ","%%20") -- NOTE: if you send request that has 'space' in it there will be error 400!
		fetch({url = "http://".. address .. "/mtmsg/"..message, timeout = 5}, result) 
	end
	MT2web("minetest robot started and listening.")
end



if state == 0 then
	fetch({url = "http://"..address.."/getwebmsg/", timeout = 5}, result)
	state = 1
end