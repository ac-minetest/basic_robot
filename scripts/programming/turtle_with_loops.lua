-- simple turtlebot with loops, rnd, 30 mins

if not init then
init = true
 commands = {
 ["f"] = function() move.forward() end,
 ["l"] = function() move.left() end,
 ["r"] = function() move.right() end,
 ["u"] = function() move.up() end,
 ["d"] = function() move.down() end,
 [">"] = function() turn.right() end,
 ["<"] = function() turn.left() end,
 ["p"] = function() place.down("default:dirt") end,
 ["P"] = function() place.forward_down("default:dirt") end,
}

  program = "R3[Pfu]<"
  loop = {start = 1, quit = 1, count = 1};
  
  step = 1
end
 
c = string.sub(program,step,step)
if c == "R" then -- loop
	local i = string.find(program,"%[",step+1);
	loop.count = tonumber(string.sub(program,step+1, i-1)) or 1;
	loop.start = i+1;
	i = string.find(program,"]",i+1);
	loop.quit = i-1
	step = loop.start-1
else -- normal command
	command = commands[c];
	if command then 
		command() 
	elseif step>string.len(program) then 
		step = 0 
	end 
end


self.label(step)
step = step +1
if loop.count>0 then -- are we in loop?
	if step>loop.quit then loop.count = loop.count - 1; step = loop.start end
	if loop.count == 0 then step = loop.quit + 2 end
end