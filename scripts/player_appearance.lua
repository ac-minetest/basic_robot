if not init then
	self.set_properties({
		visual = "mesh", mesh = "character.b3d",
		textures = {"character.png"},
		visual_size = {x = 2, y = 2}
	});
	 move.up()
	init = 1;
	
	animation = {
	-- Standard animations.
	stand     = { x=  0, y= 79, },
	lay       = { x=162, y=166, },
	walk      = { x=168, y=187, },
	mine      = { x=189, y=198, },
	walk_mine = { x=200, y=219, },
	sit       = { x= 81, y=160, },
	}
	self.set_animation(animation.stand.x,animation.stand.y, 15, 0)
t=0
end