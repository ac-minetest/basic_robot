-- with current mods there are 4 registered chat responses so we add 5th
-- CHANGE COLOR OF CHAT FOR CERTAIN PLAYERS

if not rom.color_chat_messages then rom.color_chat_messages = 1+#minetest.registered_on_chat_messages  end

colors = {"cyan", "LawnGreen"}
chatgroup = {}; -- players in here will see chat without colors
--say("chat " .. rom.chat_messages)

minetest.registered_on_chat_messages[rom.color_chat_messages] = 
function(name,message) 
	if message == "nocolor" then
		chatgroup[name] = not chatgroup[name]
		minetest.chat_send_all("colored chat display " .. (chatgroup[name] and "DISABLED" or "ENABLED") .. " for " .. name)
		return false
	else
		--message = os.date("%X") .. " " .. name .." <> " .. message;
		local newmessage = "["..name .."] " .. message;
		local player = minetest.get_player_by_name(name);
		local pos1 = player:get_pos();
		
		for _,player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local pos2 = player:get_pos();
			local dist = math.sqrt((pos2.x-pos1.x)^2+(pos2.y-pos1.y)^2+ (pos2.z-pos1.z)^2)
			local length = string.len(name);
			local color = 1; -- default
			if (chatgroup[name] or dist>32 or dist == 0) then color = 0 end
			if string.find(message,string.lower(name)) then color = 2 end
			
			if color == 0 then
				minetest.chat_send_player(name, newmessage)
			else
				minetest.chat_send_player(name, minetest.colorize(colors[color], newmessage))
			end
			
		end
	end
	return true
end

self.remove()