-- webcommands : access url like: 192.168.0.10/hello_world 

--[[ instructions:
	1.download nodejs server from
		https://nodejs.org/dist/v10.14.2/node-v10.14.2-win-x86.zip
	2. run nodejs server using run.bat
		:loop
			node --inspect myprogs/minetest_webcommands.js
		goto loop
	3. run robot and type 'http://192.168.0.10:80/hello this is a test' into browser
	(you need to write your router address here, i.e. ip accessible from  internet OR lan address)
--]]

if not fetch then
	fetch = _G.basic_robot.http_api.fetch;
	state = 0 -- ready to fetch new command
-- WARNING: this is run outside pcall and can crash server if errors!
	result = function(res)  -- res.data is string containing result
	  state = 0
	  if not res.succeeded then self.label("#ERROR: data couldn't be downloaded :\n" .. minetest.serialize(res) ) return end
	  if res.data == "" then return end
	  local req = res.data; req = string.gsub(req,"%%20"," ")
	  if res.data then self.label(os.clock() .. ' received cmd : ' .. req) end
	end

end

if state == 0 then
	fetch({url = "http://192.168.0.10/MT", timeout = 30}, result)
	state = 1
end