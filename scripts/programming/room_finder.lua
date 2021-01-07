-- room finder by rnd (45 minutes)
-- given starting position it explores 3d world to find enclosed area of room, up to max 2000 nodes

if not init then init = true
local rpos = self.pos()
local radius = 16
bpos = minetest.find_node_near(rpos, radius,"beds:bed_bottom");bpos.y=bpos.y+1 -- bed
--say(bpos.x .. " " .. bpos.y .. " " .. bpos.z)


	walls = { -- define possible walls here
		["default:cobble"]=true, ["default:wood"] = true,
		["default:obsidian_glass"]=true,["default:glass"] = true,
		["doors:door_obsidian_glass_a"]=true,["doors:door_obsidian_glass_b"]=true,
		["doors:hidden"] = true,
	}


local find_room = function(bpos)


	local cbdata = {bpos} -- explore boundary
	local cdata = {[minetest.hash_node_position(bpos)] = true} -- db of room pos
	local dirs = {{x=-1,y=0,z=0},{x=1,y=0,z=0},{x=0,y=-1,z=0},{x=0,y=1,z=0},{x=0,y=0,z=-1},{x=0,y=0,z=1}}
	local ccount = 1

	crawl_step = function()
		local pos = cbdata[#cbdata];cbdata[#cbdata] = nil;
		for i = 1,#dirs do
			local p = {x=pos.x+dirs[i].x,y=pos.y+dirs[i].y,z=pos.z+dirs[i].z}
			if not cdata[minetest.hash_node_position(p)] and not walls[minetest.get_node(p).name] then
				cdata[minetest.hash_node_position(p)] = true
				cbdata[#cbdata+1] = p
				ccount = ccount +1
			end
		end
	end

	
	local maxsteps = 2000;
	local step = 0

	while #cbdata>0 and step<maxsteps do
		step=step+1; crawl_step()
	end
	if #cbdata == 0 then say("found room around bed " .. bpos.x .. " " .. bpos.y .. " " .. bpos.z.. ", room size " .. ccount) else say("no room found. try to fix holes in walls!") end
end

find_room(bpos)

end


self.remove()