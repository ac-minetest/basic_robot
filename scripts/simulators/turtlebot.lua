if not cmd then
	cmd = {
	["f"] = function() move.forward() end,
	["b"] = function() move.backward() end,
	["l"] = function() move.left() end,
	["r"] = function() move.right() end,
	["u"] = function() move.up() end,
	["d"] = function() move.down() end,
	["a"] = function() activate.forward(1) end,	
	["<"] = function() turn.left() end,
	[">"] = function() turn.right() end,
	}
	i=0;
	prog = read_text.right(); s=0
	prog = string.gsub(prog,"%s","");
	--say(prog)
	self.label("RUNNING PROGRAM: " .. prog);n=string.len(prog);
	if string.sub(prog,1,1) == " " then self.label("WRITE A PROGRAM FIRST!") s=1 end
	
end

if s == 0 then
	i=i+1; if i > n then self.label("PROGRAM ENDED");s=1 end;
	if s == 0 then
		c=string.sub(prog,i,i)
		if cmd[c] then cmd[c]() else self.label("INVALID PROGRAM INSTRUCTION : " .. c) s=1 end
	end
end