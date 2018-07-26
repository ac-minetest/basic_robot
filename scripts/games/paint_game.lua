-- paint canvas by rnd
-- TODO: add load/save button, save in book
-- save: ask for name (chat ) and save in book
-- load display list of names and ask which one (chat)
if not init then
	
	colors = {
	"black","blue","brown","cyan","dark_green","dark_grey","green","grey",
	"magenta","orange","pink","red","violet","white","yellow"
	}
	
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
	for i = 1, size do
		for j = 1, size do
			minetest.set_node({x=spos.x +i , y = spos.y + j, z = spos.z },{name = canvasn})
		end
	end	
	
	
	
	for i = 1,#colors do
		minetest.set_node({x=spos.x +i , y = spos.y , z = spos.z },{name = "wool:"..colors[i]})
	end
	
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

if player:get_player_control().LMB then
	local v = player:get_look_dir();
	local p = player:get_pos(); p.y = p.y + 1.5
	local c = get_intersect(vn,T0,p,v); 
	if c then 
		
		local x = c.x - T0.x; local y = c.y - T0.y
		if x>0 and x<size and y>-1 and y<size then
			--self.label(x .. " " .. y)
			if y>0 then
				c.z = c.z+0.5
				minetest.set_node(c, {name = "wool:" .. colors[color]})
			else
				x = 1+math.floor(x)
				if colors[x] then
					color = x;
					self.label(colors[x])
				end
			end
		end
	
	end
	
end
