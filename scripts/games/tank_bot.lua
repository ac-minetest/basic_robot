-- rnd 2017
-- instructions: put 7 buttons around bot(top one left empty)
-- clockwise: empty, green, yellow,blue, red, blue,yellow,green.
-- those buttons serve as controls

	if not s then
		name = self.name();
		direction = 1;
		s=0;
		self.label("TANK ROBOT. control with colored buttons")
		user=find_player(4); if user then user = user[1] end
		
		speed = 7 + math.random(7);turn.angle(math.random(360));
		pitch = 0
		
		gravity = 1+math.random(2);
		if user then
			say("TANK ROBOT, ready. ".. user .. " in control")
		else
			say("no player found nearby. deactivating"); self.remove()
			s=-1
		end
		pos = self.spawnpos();
	end

	ppos =  player.getpos(user); ppos.x=ppos.x-pos.x;ppos.y=ppos.y-pos.y;ppos.z=ppos.z-pos.z;
	if ppos.x^2+ppos.y^2+ppos.z^2>10 then
		local obj = _G.minetest.get_player_by_name(user);
		if obj then say("deserter " .. user .. " killed for abandoning the tank!") obj:set_hp(0) end
		self.remove()
	else 
		local obj = _G.minetest.get_player_by_name(user);
		if obj then
			if obj:get_hp() == 0 then 
				say("TANK DESTROYED!")
				self.remove() 
			end
		end
	end

	if s == 0 then
		event = keyboard.get();
		if event and event.puncher==user then
			--self.label(event.x-pos.x .. " " .. event.y-pos.y .. " " .. event.z-pos.z .. " T " .. event.type)
			event.x = event.x-pos.x;event.y = event.y-pos.y;event.z = event.z-pos.z;
			if event.x == 0 and event.y == 0 and event.z == 1 then
				self.fire(speed, pitch,gravity)
				s=1;self.label("BOOM")
				_G.minetest.sound_play("tnt_explode",{pos = self.pos(), max_hear_distance = 256, gain = 1})
			elseif event.x == direction*1 and event.y == 0 and event.z == direction*1 then
				turn.angle(2)
			elseif event.x == -1*direction and event.y == 0 and event.z == 1*direction then
				turn.angle(-2)
			elseif event.x == 1*direction and event.y == 0 and event.z == 0 then
				turn.angle(40)
			elseif event.x == -1*direction and event.y == 0 and event.z == 0 then
				turn.angle(-40)
			elseif event.x == 1*direction and event.y == 0 and event.z == -1*direction then
				pitch  = pitch + 5; if pitch> 85 then pitch = 85 end
				self.label("pitch " .. pitch)
			elseif event.x == -1*direction and event.y == 0 and event.z == -1*direction then
				pitch  = pitch - 5; if pitch<-10 then pitch = -10 end
				self.label("pitch " .. pitch)
			end
		end
	end

	if s == 1 then
		local pos = self.fire_pos();
		if pos then 
			self.label("HIT")
			msg = "";
			_G.minetest.sound_play("tnt_explode",{pos = pos, max_hear_distance = 256, gain = 1})
			
			local objs=_G.minetest.get_objects_inside_radius(pos, 4);
			for _,obj in pairs(objs) do 
				if obj:is_player() then
					obj:set_hp(0)
					msg = msg .. obj:get_player_name() .. " is dead, "
				end
			end
			s = 0 
			if msg~="" then say(msg) end
		end
	end