-- coal maker mod idea in 30 minutes by rnd
-- build dirt box around 3x3x3 area filled with wood, remove one boundary wood (lower one) and start fire there. start robot then!

check_firebox = function(pos)
	local p = minetest.find_node_near(pos, 5, "fire:basic_flame") -- locate fire nearby!
	if not p or minetest.get_node(p).name ~= "fire:basic_flame" then say("light fire first!"); self.remove() end
	d=3; -- inner size of box, area filled with wood
	local dirs = {{-1,0,0},{1,0,0},{0,0,-1},{0,0,1}};local dir1,dir2; -- position of vertices on dirt box
	for i = 1,#dirs do
		local dir = dirs[i];
		if minetest.get_node({x=p.x+d*dir[1],y=p.y+d*dir[2],z=p.z+d*dir[3]}).name  == "default:dirt" and
		minetest.get_node({x=p.x+(d-1)*dir[1],y=p.y+(d-1)*dir[2],z=p.z+(d-1)*dir[3]}).name == "default:wood" then dir2 = dirs[i]; break end
	end
	if not dir2 then say("error, place fire in correct place in correctly built dirt box!") self.remove() end
	dir1 = {dir2[3], dir2[2], -dir2[1]};
	local v1 = {x=p.x-(d-1)*dir1[1]-dir2[1],y=p.y-1,z=p.z-(d-1)*dir1[3]-dir2[3]}
	local v2 = {x=p.x+(d-1)*dir1[1]+(d)*dir2[1],y=p.y+d,z=p.z+(d-1)*dir1[3]+(d)*dir2[3]}
	local res = minetest.find_nodes_in_area(v1,v2,{"default:wood","default:dirt"},true);
	if (#(res["default:dirt"] or {})) == 97 and #(res["default:wood"] or {})==26 then 
		say("all ok. making charcoal now!")
		minetest.swap_node(p,{name = "air"}) -- turn off fire!
	else say("fail! check that you built dirt box/wood correctly!")
	end
end

check_firebox(self.pos())
self.remove()