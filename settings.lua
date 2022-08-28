-- SETTINGS FOR BASIC_ROBOT
local b = basic_robot;

b.call_limit = {50,200,1500,10^9}; -- how many execution calls per script run allowed, for auth levels 0,1,2 (normal, robot, puzzle, admin)
b.count = {2,6,16,128} -- how many robots player can have

b.radius = 32; -- divide whole world into blocks of this size - used for managing events like keyboard punches
b.password = "raN___dOM_ p4S"; -- IMPORTANT: change it before running mod, password used for authentifications

b.admin_bot_pos = {x=0,y=1,z=0} -- position of admin robot spawner that will be run automatically on server start

b.maxoperations = 10; -- how many operations (dig, place,move,...,generate energy,..) available per run,  0 = unlimited
b.dig_require_energy = true; -- does robot require energy to dig?

b.bad_inventory_blocks = { -- disallow taking from these nodes inventories to prevent player abuses
    ["moreblocks:circular_saw"] = true,
	["craft_guide:sign_wall"] = true,
	["basic_machines:battery_0"] = true,
	["basic_machines:battery_1"] = true,
	["basic_machines:battery_2"] = true,
	["basic_machines:generator"] = true,
}

b.http_api = minetest.request_http_api(); 