-- BRAINFUCK interpreter by rnd, 2017
-- https://en.wikipedia.org/wiki/Brainfuck

if not ram then
	prog = "+++.>++++++.<[->+<]>."
	ramsize = 10
	maxsteps = 100;	step=0; -- for RUN state only
	
	n = string.len(prog);ram = {};for i = 1, ramsize do ram[i]=0 end -- init ram
	pointer = 1 -- ram pointer
	instruction = 1 -- instruction pointer
	self.spam(1)
	
	RUNNING = 1; END = 2; RUN = 3;
	state = RUNNING
	
	get_ram = function() msg = "" for i = 1,ramsize do msg = msg .. ram[i] .. "," end return msg end
	
	cmdset = {
		[">"] = function() pointer = pointer + 1; if pointer > ramsize then pointer = 1 end end,
		["<"] = function() pointer = pointer - 1; if pointer > ramsize then pointer = 1 end end,
		["+"] = function() ram[pointer]=ram[pointer]+1 end,
		["-"] = function() ram[pointer]=ram[pointer]-1 end,
		["."] = function() say(ram[pointer]) end,
		[","] = function() ram[pointer] = tonumber(read_text.forward("infotext") or "") or 0 end,
		["["] = function() 
			if ram[pointer] == 0 then 
				local lvl = 0 
				for j = instruction, n, 1 do
					if string.sub(prog,j,j) == "]" then lvl = lvl - 1 if lvl == 0 then 
						self.label("JMP " .. j ) instruction = j return 
					end end
					if string.sub(prog,j,j) == "[" then lvl = lvl + 1 end
				end
			end 
		end,
		["]"] = function() 
			if ram[pointer] ~= 0 then 
				local lvl = 0
				for j = instruction, 1, -1 do
					if string.sub(prog,j,j) == "]" then lvl = lvl - 1 end
					if string.sub(prog,j,j) == "[" then lvl = lvl + 1 if lvl == 0 then 
						self.label("JMP " .. j ) instruction = j return 
					end end
				end
			end 
		end,
	}
end

-- EXECUTION
if state == RUNNING then
	c = string.sub(prog,instruction,instruction) or "";
	if c and cmdset[c] then cmdset[c]() end
	self.label("ins ptr " .. instruction .. ", ram ptr " .. pointer .. ": " .. ram[pointer] .. "\n" .. string.sub(prog, instruction).."\n"..get_ram())
	instruction = instruction + 1; if instruction > n then state = END end

-- RUN THROUGH
elseif state == RUN then
	while (step<maxsteps) do
		step = step + 1
		c = string.sub(prog,instruction,instruction) or "";
		if c and cmdset[c] then cmdset[c]() end
		instruction = instruction + 1; if instruction > n then self.label("ram : " .. get_ram()) step = maxsteps state = END end
	end
end