-- painting import from minetest 'painting mod' to robot canvas by rnd
-- stand near image and run "get_texture()" command in remote control

if not init then
  self.label("PAINTING IMPORTER")
	pname = "rnd"
	player = minetest.get_player_by_name(pname)
	
	get_texture = function()
		
		
		local pos = player:get_pos(); local radius = 2
		local objs = minetest.get_objects_inside_radius(pos, radius)
		local obj = {};
		
		local ret =  {};
		for i=1,#objs do
			if not objs[i]:is_player() then obj = objs[i] break end
		end

		if obj then
			local tex  = obj:get_properties().textures
			local out = tex[1] or ""
			if string.sub(out,1,9) == "[combine:" then
				local pcolors = {"black","blue","brown","cyan","darkgreen","darkgrey","green","grey",
					"magenta","orange","pink","red","violet","white","yellow"}
				local ipcolors = {}; for i = 1,#pcolors do ipcolors[pcolors[i]] = i end
				
				local ret = {};
				local i =0; local j = 1; local k = 0; local size = 16;
				--ret[1] = {}
				for word in out:gmatch("=(%a+)%.png") do
					ret[#ret+1] = string.char(96 + (ipcolors[word] or 1))
				end
				
				local rret = {}; 
				for i = 1, size do rret[i] = {} for j = 1,size do rret[i][j] = 0 end end
				
				k = 0 -- rotate 90 right
				for j = 1,size do
					for i = size,1,-1 do
						k = k + 1
						rret[size-i+1][size-j+1] = ret[k]
					end
				end
				
				ret = {}; for i = 1, size do for j = 1, size do ret[#ret+1]= rret[i][j] end end -- write back

				out = table.concat(ret,"")
				book.write(1,"IMPORTED_PAINTING", out)
				minetest.chat_send_player(pname, "PAINTING FOUND, saved in robot library in book 1.")
			end
		else return "empty"
		end
	end
	
	init = true
end