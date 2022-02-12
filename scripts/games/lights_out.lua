--coroutine
--lights out, game by dopik, 2018?

if not init then init = true
	self.listen_punch(self.pos());
end

size = 5
pname = "dopik"
score = 1000 --highest score possible

function generateField()
	local tbl = {}
	for i = 1, size^2 do
		tbl[i] = math.random(0,1)
	end
	
	local field = {}
	for i = 1, size^2 do
		local x,z = (i-1) % size, math.floor((i-1) / size)
		local val = tbl[i]
		val = val + (x > 0 and tbl[(x-1) + (z*size) +1] or 0)
		val = val + (x+1 < size and tbl[(x+1) + (z*size) +1] or 0)
		val = val + (z > 0 and tbl[x + ((z-1)*size) +1] or 0)
		val = val + (z+1 < size and tbl[x + ((z+1)*size) +1] or 0)
		field[i] = val % 2
	end
	
	return field
end

function placeField(field)
	for i = 1, size^2 do
		local dx,dz = (i-1) % size +1, math.floor((i-1) / size) +1
		
		local pos = self.spawnpos()
		pos.x = pos.x + dx
		pos.z = pos.z + dz
		
		keyboard.set(pos, field[i]*4 + 1)
	end
end

function hitKey(pos)
	local c
	
	if keyboard.read(pos) == "basic_robot:buttonFFFFFF" then
		c = true
		keyboard.set(pos, 5)
	elseif keyboard.read(pos) == "basic_robot:button8080FF" then
		keyboard.set(pos, 1)
	end
	
	pos.x = pos.x - 1
	if keyboard.read(pos) == "basic_robot:buttonFFFFFF" then
		c = true
		keyboard.set(pos, 5)
	elseif keyboard.read(pos) == "basic_robot:button8080FF" then
		keyboard.set(pos, 1)
	end
	
	pos.x = pos.x + 2
	if keyboard.read(pos) == "basic_robot:buttonFFFFFF" then
		c = true
		keyboard.set(pos, 5)
	elseif keyboard.read(pos) == "basic_robot:button8080FF" then
		keyboard.set(pos, 1)
	end
	
	pos.x = pos.x - 1
	pos.z = pos.z - 1
	if keyboard.read(pos) == "basic_robot:buttonFFFFFF" then
		c = true
		keyboard.set(pos, 5)
	elseif keyboard.read(pos) == "basic_robot:button8080FF" then
		keyboard.set(pos, 1)
	end
	
	pos.z = pos.z + 2
	if keyboard.read(pos) == "basic_robot:buttonFFFFFF" then
		c = true
		keyboard.set(pos, 5)
	elseif keyboard.read(pos) == "basic_robot:button8080FF" then
		keyboard.set(pos, 1)
	end
	
	score = math.max(0, score - 1)
	
	if not c then
		return won()
	end
end

function won()
	for i = 1, size^2 do
		local pos = self.spawnpos()
		pos.x = pos.x + 1 + i % size
		pos.z = pos.z + 1 + math.floor(i / size)
		
		if keyboard.read(pos) == "basic_robot:button8080FF" then
			return false
		end
	end
	
	return win()
end

function win()
	puzzle.chat_send_player(pname, "\27(c@#ff0)###Lights Out###  \27(c@#fff)You won!")
	puzzle.chat_send_player(pname, string.concat({"\27(c@#ff0)###Lights Out###  \27(c@#fff)Your score is \27(c@#ff0) ", score}))
	
	for i = 1, size^2 do
		local dx,dz = (i-1) % size +1, math.floor((i-1) / size) +1
		
		local pos = self.spawnpos()
		pos.x = pos.x + dx
		pos.z = pos.z + dz
		
		puzzle.set_node(pos, {name="default:dirt"})
	end
	
	self.remove()
end

function init()
	local players = find_player(5, self.spawnpos())
	if not players then
		self.remove()
		return
	end
	
	pname = players[1]
	
	local field = generateField(size)
	placeField(field)
	
	puzzle.chat_send_player(pname, "\27(c@#ff0)###Lights Out###  \27(c@#fff)Game started")
	self.label("Turn all lights off (=white) to win\nPunch a light to switch it on/off")
	
	return main()
end

function main()
	local event = keyboard.get()
	local pos = self.spawnpos()
	
	if event  then
		if event.x <= pos.x + size and event.x > pos.x
				and event.z <= pos.z + size and event.z > pos.z
				and event.y == pos.y then
			hitKey({x=event.x,y=event.y, z=event.z})
		end
	end
	
	pause()
	return main()
end

init()