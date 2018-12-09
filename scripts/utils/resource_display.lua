-- SHOWS ACTIVE ROBOTS AND STATISTICS
if not init then init = true
	local data = _G.basic_robot.data;
	local ret = {};
	for k,v in pairs(data) do 
		if k~="listening" and v.obj then 
			local ent = v.obj:get_luaentity();
			local t = v.t or 0; if t< 100000 then t = math.floor(t * 10000)/10 else t = 0 end
			if ent then ret[#ret+1] = k .. "  " .. string.len(ent.code or "") .. " " .. string.len(_G.string.dump(v.bytecode) or "") .. "   ~   " .. t end
		end 
	end
	mem1 = _G.collectgarbage("count")
	self.label("memory used by lua (kbytes) ".. mem1 .. " ( delta " .. mem1 - (mem0 or 0) .. ")\n\nACTIVE ROBOTS\nrobot name | source code size | bytecode size |   ~  time (ms)\n" .. table.concat(ret,"\n"))
	mem0 = mem1
	init = false
end