-- file 'manager' by rnd

if not init then
	fmver = "2018/12/09"
   local players = find_player(4);
   if not players then self.remove() end
   pname = players[1];
   size = 8;
   vsize = 6.5;
   
	path = "/";
	pathlist = {}
	folderlist = {};
	filelist = {};
	
	render_page = function()
		local foldlist = minetest.get_dir_list(path,true) -- only folders
		if foldlist then folderlist = foldlist else folderlist = {} end
		for i = 1,#foldlist do foldlist[i] =  "*"..foldlist[i] end
		foldlist[#foldlist+1] = "*.."
		local fillist = minetest.get_dir_list(path,false) 
		if fillist then filelist = fillist else  filelist = {} end
		local content = table.concat(folderlist,",") .. ",-------------------," .. table.concat(filelist,",")
		return "size[" .. size .. "," .. size .. "] label[0,-0.25;ROBOT FILE MANAGER " .. fmver .. " by rnd\nPATH " .. minetest.formspec_escape(path) .. "] textlist[-0.25,0.75;" .. (size+1) .. "," .. (vsize+1) .. ";wiki;".. content .. ";1]";
	end
	
	page = {}
	self.show_form(pname,render_page())
	init = true
	self.read_form()
end

sender,fields = self.read_form()
if sender then 
	local fsel = fields.wiki;
	if fsel and string.sub(fsel,1,3) == "DCL" then
		local sel = tonumber(string.sub(fsel,5)) or 1; -- selected line
		local fold = folderlist[sel];
		if fold and string.sub(fold,1,1) == "*" then
			if fold == "*.." then -- go back
				if #pathlist>0 then
					local i = string.len(pathlist[#pathlist]);
					if i>0 then 
						pathlist[#pathlist] = nil
						path = string.sub(path,1,-i-2);
					end
				end
			else
				pathlist[#pathlist+1] = string.sub(fold,2)
				path = path .. "/".. pathlist[#pathlist]
			end
			
			self.show_form(pname,render_page())
		end
	end
	--self.label(fsel);
end