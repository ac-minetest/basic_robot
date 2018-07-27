-- paint canvas by rnd, 2018
if not init then
	colors = {
	"black","blue","brown","cyan","dark_green","dark_grey","green","grey",
	"magenta","orange","pink","red","violet","white","yellow"
	}
	invcolors = {};	for i = 1,#colors do invcolors[colors[i]] = i end
	
	color = 1;
	size = 16;
	
	init = true
	
	local ent = _G.basic_robot.data[self.name()].obj:get_luaentity();
	ent.timestep = 0.5
	
	players = find_player(5); 	if not players then self.remove() end
	player = _G.minetest.get_player_by_name(players[1])
	self.label("-> " .. players[1])
	
	spos = self.spawnpos(); spos.y=spos.y+1;
	
	canvasn = "wool:white"
	reset_canvas = function()
		for i = 1, size do
			for j = 1, size do
				minetest.set_node({x=spos.x +i , y = spos.y + j, z = spos.z },{name = canvasn})
			end
		end	
	end
	reset_canvas()
	
	save_image = function()
		local ret = {};
		for i = 1, size do
			for j = 1, size do
				local nname = string.sub(minetest.get_node({x=spos.x +i , y = spos.y + j, z = spos.z }).name,6)
				local pcolor = invcolors[nname] or 1;
				ret[#ret+1]= string.char(96+pcolor)
			end
		end	
		return table.concat(ret,"")
	end
	
	load_image = function(image)
		if not image then return end 
		local ret = {}; local k = 0;
		for i = 1, size do
			for j = 1, size do
				k=k+1;
				local pcolor = colors[string.byte(image,k)-96] or "black";
				minetest.set_node({x=spos.x +i , y = spos.y + j, z = spos.z },{name = "wool:"..pcolor})
			end
		end	
	end
	
	
	--draw buttons
	for i = 1,#colors do
		minetest.set_node({x=spos.x +i , y = spos.y , z = spos.z },{name = "wool:"..colors[i]})
	end
	
	minetest.set_node({x=spos.x +1 , y = spos.y-1 , z = spos.z },{name = "basic_robot:button_83"})
	minetest.set_node({x=spos.x +2 , y = spos.y-1 , z = spos.z },{name = "basic_robot:button_76"})
	
	
	vn = {x=0,y=0,z=1};
	T0 = {x=spos.x+0.5,y=spos.y+0.5,z=spos.z-0.5*vn.z};
	
	get_intersect = function(vn, T0, p, v)
		local a = (T0.x-p.x)*vn.x + (T0.y-p.y)*vn.y + (T0.z-p.z)*vn.z;
		local b =  vn.x*v.x + vn.y*v.y + vn.z*v.z
		if b<=0 then return nil end
		if a<=0 then return nil end
		local t = a / b
		return {x = p.x+v.x*t, y= p.y+v.y*t, z = p.z+v.z*t}
	end

end

if player:get_player_control().LMB then -- player interacts with 'virtual canvas gui'
	local v = player:get_look_dir();
	local p = player:get_pos(); p.y = p.y + 1.5
	local c = get_intersect(vn,T0,p,v); 
	if c then 
		
		local x = c.x - T0.x; local y = c.y - T0.y
		if x>0 and x<size and y>-2 and y<size then
			if y>0 then -- above: painting
				c.z = c.z+0.5
				minetest.set_node(c, {name = "wool:" .. colors[color]})
			elseif y>-1 then -- color selection
				x = 1+math.floor(x)
				if colors[x] then
					color = x;
					self.label(colors[x])
				end
			else -- save,load button row
				x = 1+math.floor(x)
				if x==1 then 
					self.label("SAVED.")
					book.write(1,"ROBOT_IMAGE",save_image())
				elseif x==2 then 
					local _,image = book.read(1)
					load_image(image);
					self.label("LOADED.") 
				end
			end
		end
	
	end
end