--rnd music robot v12/10/2019, 22:00
--tuning by Jozet

--@F2 E D C G3 G F2 E D C G3 G F2 A A F E G G E D E F D C3 C

if not init then
  	_G.minetest.forceload_block(self.pos(),true)	
	song = nil
  self.listen(1)
	local ent = _G.basic_robot.data[self.name()].obj:get_luaentity();
	dt = 0.001
	ent.timestep = dt -- time step
	
	pitches = { -- definitions of note pitches
		0.59,
		0.62,
		0.67,
		0.7,
		0.74,
		0.79,
		0.845,
		0.89,
		0.945,
		1,
		1.05,
		1.12,
		1.19,
		1.25,
		1.34,
		1.41,
		1.48,
		1.58,
		1.68,
		1.78,
		1.88,
		2.0,
		2.15,
		2.28
	}	
	
	notenames = { -- definition of note names
		C  = 1,
		Db = 2,
		D = 3,
		Eb = 4,
		E = 5,
		F = 6,
		Gb = 7,
		G = 8,
		Ab = 9,
		A = 10,
		Bb = 11,
		B = 12,
		["2C"]  = 13,
		["2Db"] = 14,
		["2D"] = 15,
		["2Eb"] = 16,
		["2E"] = 17,
		["2F"] = 18,
		["2Gb"] = 19,
		["2G"] = 20,
		["2Ab"] = 21,
		["2A"] = 22,
		["2Bb"] = 23,
		["2B"] = 24	
	}

say("available notes : C Db D Eb E F Gb G Ab A Bb B 2C 2Db 2D 2Eb 2E 2F 2Gb 2G 2Ab 2A 2Bb 2B . example: @A5 A A A A10 A A A , number after note name denotes change of tempo. To replay last song do @R")


	songdata = {}
	t=0 -- current timer
	idx = 0 -- current note to play
	tempo = 1 -- default pause

	parse_song = function()
		songdata = {} -- reset song data
		for notepart in string.gmatch(song,"([^ ]+)") do -- parse song
			if notepart then
				local note,duration;
				note,duration = _G.string.match(notepart,"(%d*%a+)(%d*)")
				if not duration or duration == "" then duration = 0 end
				songdata[#songdata+1] = {notenames[note], tonumber(duration)}
			end
		end	
		tempo = 3; -- default tempo
		t=0 
		idx = 0 -- reset current idx
	end

	init = true

end

if not song then
	speaker,msg = self.listen_msg()
	if msg and string.find(msg,"@") then
		song = string.sub(msg,2)
		if song ~= "R" then -- R for replay 
			parse_song()
			self.label("playing song by " .. speaker.. ",  " .. song )
		else
			 idx = 0; t = 0; -- try play again!
		end
	end
elseif t<=1 then -- play next note!
	idx = idx+1
	if idx>#songdata then 
		self.label("song " .. song .. ". ended.")
		song = nil
	else 
		if songdata[idx][2]>0 then tempo = songdata[idx][2] end 
		t = tempo;
		self.sound( "piano",{
			pos = self.pos(), gain = 1000.0, pitch = pitches[ songdata[idx][1] ],
			max_hear_distance = 1000000 
			})
	end
else
	t=t-1
end