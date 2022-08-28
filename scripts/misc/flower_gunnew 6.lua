if not name then
	name = "rnd"
	player = minetest.get_player_by_name(name)

	texs = {
	"flowers_chrysanthemum_green.png",
	"flowers_dandelion_white.png",
	"flowers_dandelion_yellow.png",
	"flowers_geranium.png",
	"flowers_mushroom_brown.png",
	"flowers_mushroom_red.png",
	"flowers_rose.png",
	"flowers_tulip.png",
	"flowers_tulip_black.png",
	"flowers_viola.png",
	}
	local ent = _G.basic_robot.data[self.name()].obj:get_luaentity();
	ent.timestep = 0.25
	_G.minetest.forceload_block(self.pos(),true)
	
	add_part = function(pos)
		local vdir = player:get_look_dir()
		local speed = 8
		vdir.x=vdir.x*speed
		vdir.y=vdir.y*speed
		vdir.z=vdir.z*speed
		
		minetest.add_particle(
		{
			pos = {x=pos.x, y=pos.y+1.5, z=pos.z},
			velocity = vdir, --{x=0, y=0, z=0},
			acceleration = {x=0, y=-1, z=0},
			expirationtime = 15,
			size = 10,
			collisiondetection = true,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = texs[math.random(#texs)],
			glow = 0
		})
	end
	p1 = player:getpos();
end

p2 = player:getpos()
local dist = ((p2.x-p1.x)^2+(p2.y-p1.y)^2+(p2.z-p1.z)^2)^0.5
if player:get_wielded_item():to_string()=="flowers:dandelion_yellow" then add_part(p2) end

--if dist>1 then p1 = player:getpos() add_part(p1) end
