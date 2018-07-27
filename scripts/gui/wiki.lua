-- ROBOT WIKI
if not init then
   _G.basic_robot.data[self.name()].obj:get_luaentity().timestep = 0.1
   local players = find_player(4);
   if not players then self.remove() end
   pname = players[1];
   size = 8;
   vsize = 8;
   linesize = 60; -- break up longer lines
   
	wiki = {   
		["Main menu"] = "HELP CONTENTS\n \n".."double click link marked with [] or press enter while selected.\n \n".."[How to play]\n".."[Robot tutorial]",
		["How to play"] = "HOW TO PLAY\n \nOpen inventory (press i on pc), then go to Quests and read."..
		"Complete quests to progress in game and get nice rewards.\n \n[Main menu]",
		["Robot tutorial"] = "ROBOT TUTORIAL\n \nLearn on simple programs first then make a lot of your own\n \n[Main menu]",
	}
	current = "Main menu";
	
	render_page = function()
		page = {}
		local text = wiki[current];
		for line in text:gmatch("[^\n]+") do
			local llen = string.len(line);
			local m = math.floor(llen/linesize)+1;
			for i = 1, m do
				page[#page+1]=minetest.formspec_escape(string.sub(line,(i-1)*linesize+1, i*linesize))
			end
				
		end

		local content = table.concat(page,",")
		return "size[" .. size .. "," .. size .. "] textlist[-0.25,-0.25;" .. (size+1) .. "," .. (vsize+1) .. ";wiki;".. content .. ";1]";
	end
	
	page = {}
	self.show_form(pname,render_page())
	init = true
end

sender,fields = self.read_form()
if sender then 
	--self.label(serialize(fields)) 
	local fsel = fields.wiki;
	if fsel then
		if string.sub(fsel,1,3) == "DCL" then 
			local sel = tonumber(string.sub(fsel,5)) or 1;
			if string.sub(page[sel],1,2) == "\\[" then
				current = string.sub(page[sel],3,-3)
				self.show_form(pname,render_page())
			end
		end
	end
	
end