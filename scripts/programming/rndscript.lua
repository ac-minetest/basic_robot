-- rnd 2017
-- call stack, subroutines, recursive subroutines, if jumps, loops, variables

if not cmd then
prog = "\n"..
"<fd M(loop) f NNOT(air)[<] G(loop)";

pause = 0

	self.label(prog)
	build = {};
	
	cmd = {
	["f"] = function() move.forward() end,
	["b"] = function() move.backward() end,
	["l"] = function() move.left() end,
	["r"] = function() move.right() end,
	["u"] = function() move.up() end,
	["d"] = function() move.down() end,
	
	["p"] = function() place.forward_down("default:dirt") end,
	["P"] = function() place.forward("default:dirt") end,
	["F"] = function() dig.forward() end,
	["L"] = function() dig.left() end,
	["R"] = function() dig.right() end,
	["U"] = function() dig.up() end,
	["D"] = function() dig.down() end,
	["<"] = function() turn.left() end,
	[">"] = function() turn.right() end,
	};
	
	build.debug =true;
	build.stackdepth = 16;
	
	build.ignored = {["]"]=true,["["]=true};
   
-- RESERVED: Ex(y)[A] : if x == y do A end, N(node)[A] : if read_node.forward()==node then do A end
-- G(label) .. GOTO  GR(label) .. CALL SUBROUTINE +a(b),-a(b),=a(b)

	set_routine = function(i) 
		local jr = string.find(prog,"%[",i+1)
		if not jr then say("error, missing [ after position " .. i+1); self.remove() end
		build.count = get_var(string.sub(prog,i+1,jr-1)) or 1
		local kr = string.find(prog,"]",jr+1);
		if not kr then say("error, missing ] after position " .. jr+1); self.remove() end
		return jr,kr --returns routine limits jr,kr
	end
	
	error_msg = function(i)
		local callstack = "";
		for _,v in pairs(build.callstack) do
			callstack = callstack.. call_marks[v].. ",";
		end
		
		return "ERROR: " ..string.sub(prog,i) .. "\nCALL STACK: " .. callstack
	end
	
	run_routine = function(i,jr,kr)
		local count = build.count;
		if count > 0 then
			if i == kr then 
				count = count - 1 i = jr+1
			end
			--say(" i " .. i .. " kr " .. kr)
			if count > 0 then
				c=string.sub(prog,i,i)
				if c == "G" then i=go_to(i); build.state  = 0 else -- exit routine
					if cmd[c] then cmd[c]() else 
						if not ignored[c] then
							self.label("run routine: invalid instruction at position " .. i .. "\n" .. error_msg(i)); 
							self.debug = false; build.state = -1
						end
						
					end
				end
			end
		else
			i=kr-- exit,jump to next instruction
			build.state = 0
			if build.debug then self.label("["..build.state .. "]" .. i .. "\nROUTINE EXIT") end
		end
		
		build.count = count
		return i -- return next execution address
	end
	
	push_callstack = function(val) -- addresses where to continue after function ends
		if #build.callstack > build.stackdepth then say("error: stack depth limit " .. build.stackdepth .. " exceeded "); self.remove() end
		build.callstack[#build.callstack+1] = val;
	end
	
	pop_callstack = function()
		local val = build.callstack[#build.callstack];
		build.callstack[#build.callstack] = nil;
		return val
	end
			
	go_to = function(i)
		local j = string.find(prog,"%(",i+1); local k = string.find(prog,"%)",j+1)
		local call = false;
		if string.sub(prog,i+1,j-1) == "R" then call = true push_callstack(k) end -- function call, save call exit address to return here
		
		local target =  string.sub(prog,j+1,k-1);
		if target == "" then -- marking end of routine
			i = pop_callstack(); 
			if build.debug then self.label("["..build.state .. "]" .. i .. "\nEXITING ROUTINE to " .. i ..  ", stack level " .. #build.callstack) end
		else
			i = go_to_mark[target]-1;
			if call == false then
				if build.debug then self.label("["..build.state .. "]" .. i .. "\nGOTO " .. target .. "=".. i ) end
			else 
				if build.debug then self.label("["..build.state .. "]" .. i .. "\nCALL SUBROUTINE " .. target .. "=".. i .. "\ncall stack = " .. string.gsub(_G.dump(build.callstack),"\n","")) end
			end
		end
	
		return i;
	end
	
	-- scan for go_to markers
	go_to_mark = {};
	call_marks = {}; -- OPTIONAL for nicer error messages
	scan_go_to = function()
		local i = 0;
		while ( i < string.len(prog)) do
			i=i+1;
			if string.sub(prog,i,i+1) == "M(" then
				local j = string.find(prog,"%(",i+1)
				local k = string.find(prog,"%)",j+1)
				local name = string.sub(prog,j+1,k-1);
				prog = string.sub(prog,1,i-1)..string.sub(prog,k+1)
				go_to_mark[name] = i;
			end
		end

		i=0 -- OPTIONAL call marks scanning
		while ( i < string.len(prog)) do
			i=i+1;
			if string.sub(prog,i,i+2) == "GR(" then
				local j = string.find(prog,"%(",i+1)
				local k = string.find(prog,"%)",j+1)
				local name = string.sub(prog,j+1,k-1);
				call_marks[k] = name;
			end
		end
	end
	
	get_var = function(s)
		local ns = tonumber(s);
		if _G.tostring(ns)==s then return ns else return build.var[s] end
	end
	
	prog = string.gsub(prog, " ", "") -- remove all spaces
	prog = string.gsub(prog, "\n", "") -- remove all newlines
	scan_go_to()
	build.n=string.len(prog)
	build.i=1;
	build.count = 1;
	build.state = 0;
	build.callstack = {};
	build.var = {};
	self.spam(1)
end

build.run = function()

	local i=build.i; -- get current execution address

	local jr,kr -- routine execution boundaries
	local jc, kc

	--i=i+1; if i>build.n then i = 1 end end

	c=string.sub(prog,i,i)

	if build.state == 0 then
		if c == "R" then 
			jr,kr=set_routine(i); i = jr;  -- set up execution point i=jr
			build.state = 1
		elseif c == "=" then
			jc = string.find(prog,"%(",i+1)
			kc = string.find(prog,"%)",jc+1)
			local var1 = string.sub(prog,i+1,jc-1);
			local var2 = get_var(string.sub(prog,jc+1,kc-1));
			build.var[var1]=var2
			i=kc
			
		elseif c == "+" then
			jc = string.find(prog,"%(",i+1)
			kc = string.find(prog,"%)",jc+1)
			local var1 = string.sub(prog,i+1,jc-1);
			local var2 = get_var(string.sub(prog,jc+1,kc-1));
			build.var[var1]=build.var[var1]+var2
			i=kc
		elseif c == "-" then
			jc = string.find(prog,"%(",i+1)
			kc = string.find(prog,"%)",jc+1)
			local var1 = string.sub(prog,i+1,jc-1);
			local var2 = get_var(string.sub(prog,jc+1,kc-1));
			build.var[var1]=build.var[var1]-var2
			i=kc
		elseif c == "E" then
			jc = string.find(prog,"%(",i+1)
			kc = string.find(prog,"%)",jc+1)
			local INOT = string.sub(prog,i+1,i+3) == "NOT";
			local trigger; local var1; local var2;
			
			if INOT then
				var1 = get_var(string.sub(prog,i+4,jc-1));
				var2 = get_var(string.sub(prog,jc+4,kc-1));
			else
				var1 = get_var(string.sub(prog,i+1,jc-1));
				var2 = get_var(string.sub(prog,jc+1,kc-1));
			end
			trigger = (var1 == var2)
		
			if (not INOT and trigger) or (INOT and not trigger)then 
				i=kc;
				jr,kr=set_routine(i);i=jr
				build.state = 1
			else 
				kc = string.find(prog,"]",kc+1)
				i = kc
			end		
		elseif c == "N" then
			jc = string.find(prog,"%(",i+1)
			kc = string.find(prog,"%)",jc+1)
			local node =  string.sub(prog,jc+1,kc-1) or "air";
			local INOT = string.sub(prog,i+1,jc-1) == "NOT";
			local trigger;
			trigger = read_node.forward() == node;

			if (not INOT and trigger) or (INOT and not trigger)then 
				i=kc;
				jr,kr=set_routine(i); i = jr
				build.state = 1
			else 
				kc = string.find(prog,"]",kc+1)
				i = kc
			end	
		elseif c == "G" then
			i=go_to(i);
		elseif c == "C" then
			jc = string.find(prog,"%(",i+1)
			kc = string.find(prog,"%)",jc+1)
			var = string.sub(prog,jc+1,kc-1);
			i = kc
			self.label(var .. "=" .. get_var(var))
		else
			if cmd[c] then cmd[c]() else 
				if not build.ignored[c] then
					self.label("run main: invalid instruction at position " .. i.. "\n" .. error_msg(i)); 
					build.state = -1; self.debug = false;
				end
			end
		end
	elseif build.state == 1 then -- routine
		jr = build.jr; kr = build.kr;
		i=run_routine(i,jr,kr)
	end

	
	i=i+1; if i>build.n then i = 1 end 
	
	build.i = i -- update execution address
    build.jr = jr;
	build.kr = kr;
	
end

if build.debug then self.label("["..build.state .. "]" .. build.i .. "\n" .. string.sub(prog,build.i)) end
build.run()