if not s then
	s=0
	t=0
	option = {"A","B","C","D","E"}
	generate_question = function()
		local a = math.random(10)+0;
		local b = math.random(10)+0;
		local c = math.random(20)-10;
		local d = a*b+c;
		msg = "To get out solve the math problem\n";
		msg = msg .. colorize("LawnGreen",a.." * "..b.." + "..c .. " = ?\n\n")
		problem = a.."*"..b.."+"..c .. " = ?";
		correct = math.random(5);
		local frm = "";
		
		for i =1,5 do
			local offset = 0;
			if i~=correct then offset = math.random(10)-5; if offset == 0 then offset = -1 end end
			frm = frm .. "button_exit[".. -0.1+(i-1)*1.25 ..",0.75;1.25,1;" .. i .. ";".. d + offset .. "]"
		end
	
		local form = "size[6,1.25]" .. "label[0.05,-0.3;".. msg.."] "..frm .. "button_exit[4.9,-0.25;1.2,1;cancel;cancel]";
		return form, correct
	end

	selection = 1;
	question = "";
	problem = "";
end


if t%4 == 0 then 
	t = 0; form,selection = generate_question();
	for _,obj in pairs(_G.minetest.get_objects_inside_radius({x=2,y=2,z=0}, 1)) do
		if obj:is_player() then
			local pname = obj:get_player_name();
			self.show_form(pname,form)
		end
	end
end
t=t+1;


sender,fields = self.read_form()
if sender then
	player = _G.minetest.get_player_by_name(sender);
	if player then
		
		answer = 0;
		for i = 1,5 do if fields[_G.tostring(i)] then answer = i end end
		
		if answer == correct then 
			player:setpos({x=0,y=2,z=3})
			--inv = player:get_inventory(); inv:add_item("main", "default:apple")
			--_G.minetest.chat_send_player(sender,"<MATH ROBOT> congratulations, here is an apple.")
		elseif answer ~= 0 then
			player:setpos({x=0,y=-6,z=-1})
			say(sender .. " failed to solve the problem " .. problem)
			self.show_form(sender, "size[1.25,0.5] label[0,0; WRONG]")
		end
	end
end