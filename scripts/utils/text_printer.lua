-- text printer by rnd
-- instruction: go to position where text starts and look in desired direction
-- say: t TEXT\nTEXT...

if not init then init = true
	name = "_"
	
	get_dir = function(view)
		local dir
		if math.abs(view.x)>math.abs(view.z) then
			if view.x>0 then dir = {1,0} else dir = {-1,0} end
		else
			if view.z>0 then dir = {0,1} else dir = {0,-1} end
		end
		return dir
	end
	
	render_text = function(text)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		local dir = get_dir(player:get_look_dir())
		local i=0; 
		local x=0;local y=0
		while i<string.len(text) do
		    i=i+1
			local c = string.sub(text,i,i)
			if c == "\\" and string.sub(text,i+1,i+1) == "n" then
				x=0;y=y-1;i=i+2;c = string.sub(text,i,i)
			end
			cb = (string.byte(c) or 32)-97
			minetest.set_node({x=pos.x+dir[1]*x,y=pos.y+y,z=pos.z+dir[2]*x},{name = "basic_robot:button_"..(97+cb)})
			x=x+1
		end
	end
	self.listen(1)

end

speaker,msg = self.listen_msg()
if speaker == name and string.sub(msg,1,2) == "t " then
	
	render_text(string.sub(msg,3))
end