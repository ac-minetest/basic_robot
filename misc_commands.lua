//lua minetest.get_player_by_name("rnd"):set_properties({visual_size = {x=1,y=1}})

local name = "rnd"; local player = minetest.get_player_by_name(name); player:set_properties({visual = "upright_sprite"});player:set_properties({textures={"default_tool_diamondpick.png"}})


// change to robot
local name = "rnd"; local player = minetest.get_player_by_name(name); player:set_properties({visual = "cube"});player:set_properties({textures={"arrow.png^[transformR90","basic_machine_side.png","basic_machine_side.png","basic_machine_side.png","face.png","basic_machine_side.png"}});player:set_properties({collisionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5}})

//LawnGreen

local name = "rnd"; local player = minetest.get_player_by_name(name); player:set_properties({visual = "sprite"});player:set_properties({textures={"farming_bottle_ethanol.png"}});player:set_properties({collisionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5}});player:set_properties({visual_size = {x=2,y=2}})

//farming_blueberry_muffin
local name = "rnd"; local player = minetest.get_player_by_name(name); player:set_properties({visual = "cube"});player:set_properties({textures={"farming_pumpkin_face_off.png","farming_pumpkin_face_off.png","farming_pumpkin_face_off.png","farming_pumpkin_face_off.png","farming_pumpkin_face_off.png","farming_pumpkin_face_off.png"}});player:set_properties({collisionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5}})

--nyan cat
//lua local name = "rnd"; local player = minetest.get_player_by_name(name); player:set_properties({visual = "cube"});player:set_properties({textures = {"nyancat_side.png", "nyancat_side.png", "nyancat_side.png","nyancat_side.png", "nyancat_front.png", "nyancat_back.png"}});player:set_properties({collisionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5}})



local name = "rnd1"; local player = minetest.get_player_by_name(name); player:set_nametag_attributes({text = "Friend of Giorge"});

//lua local player = minetest.get_player_by_name("pro2");minetest.sound_play("nyan",{object = player,gain = 1.0,max_hear_distance = 8,loop = false})


//lua local player = minetest.get_player_by_name("rnd");player:set_properties({visual = "mesh",textures = {"mobs_spider.png"},mesh = "mobs_spider.x",visual_size = {x=7,y=7}})


//lua local player = minetest.get_player_by_name("rnd");player:set_properties({visual = "mesh",textures = {"mobs_dungeon_master.png"},mesh = "mobs_dungeon_master.b3d",visual_size = {x=1,y=1}})

//lua local player = minetest.get_player_by_name("best");player:set_properties({visual = "mesh",textures = {"zmobs_mese_monster.png"},mesh = "zmobs_mese_monster.x",visual_size = {x=1,y=1}})

//lua local player = minetest.get_player_by_name("rnd1");player:set_properties({visual = "mesh",textures = {"mobs_oerkki.png"},mesh = "mobs_oerkki.b3d",visual_size = {x=1,y=1}})

//lua local player = minetest.get_player_by_name("rnd1");player:set_properties({visual = "mesh",textures = {"mobs_stone_monster.png"},mesh = "mobs_stone_monster.b3d",visual_size = {x=1,y=1}})


mesh = "zmobs_lava_flan.x",
	textures = {
		{"zmobs_lava_flan.png"},
		{"zmobs_lava_flan2.png"},
		{"zmobs_lava_flan3.png"},
	},
----------------------------------------------


	
//lua local player = minetest.get_player_by_name("towner");player:set_physics_override({speed=0.05})






