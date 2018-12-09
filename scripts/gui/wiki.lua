-- ROBOT WIKI by rnd
-- to do: ability for multiple links in 1 line


if not init then
   _G.basic_robot.data[self.name()].obj:get_luaentity().timestep = 0.1
   local players = find_player(4);
   if not players then self.remove() end
   pname = players[1];
   size = 8;
   vsize = 8;
   linesize = 60; -- break up longer lines
   
	wiki = {   -- example of wiki pages
		["MAIN PAGE"] = 
		{
			"-- WIKI CONTENTS -- ", "",
			"double click link marked with [] or press enter while selected.","",
			"[Viewing wiki]",
			"[Editing wiki]"
		},
		
		["Viewing wiki"] = {
			"back to [MAIN PAGE]","",
			" ** Viewing wiki",
			"double click link marked with [] or press enter while selected."
		},
		
		["Editing wiki"] = {
			"back to [MAIN PAGE]","",
			" ** Editing wiki",
			"Edit wiki table and write in entries"
		}
	}
	
	for k,v in pairs(wiki) do
	local pages = wiki[k]; for i = 1,#pages do pages[i] = minetest.formspec_escape(pages[i]) end
	end
	
	
	current = "MAIN PAGE";
	
	render_page = function()
		local content = table.concat(wiki[current],",")
		return "size[" .. size .. "," .. size .. "] textlist[-0.25,-0.25;" .. (size+1) .. "," .. (vsize+1) .. ";wiki;".. content .. ";1]";
	end
	
	page = {}
	self.show_form(pname,render_page())
	init = true
end

sender,fields = self.read_form()
if sender then 
	local fsel = fields.wiki;
	if fsel and string.sub(fsel,1,3) == "DCL" then
		local sel = tonumber(string.sub(fsel,5)) or 1; -- selected line
		local address = current or "main";
		local pages = wiki[address];
					
		local link = _G.string.match(pages[sel] or "", "\\%[([%w%s]+)\\%]")
		if wiki[link] then 
			current = link;
			self.show_form(pname,render_page())
			--robot_show_help(name)
		end
	end
end