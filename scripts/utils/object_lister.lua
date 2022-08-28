-- minetest object listen in radius 100 around robot

if not init then init  = false

local objs = minetest.get_objects_inside_radius(self.pos(), 100);
local ret = {};

local round = function(x) return math.floor(x/5)*5 end
local ret = {};

for i = 1, #objs do
  local p = objs[i]:get_pos();
  local luaent = objs[i]:get_luaentity();
  local entname = ""
  if luaent then 
	--entname = serialize(luaent)
	entname = luaent.itemstring
	if entname == "robot" then entname = entname .. " " .. luaent.name end
	elseif objs[i]:is_player() then 
		entname = "PLAYER " .. objs[i]:get_player_name() 
	end
  
  local phash = round(p.x) .. " " .. round(p.y) .. " " .. round(p.z);
  if entname then ret[phash] = (ret[phash] or "") .. entname .. ", " end
end

local out = {};
for k,v in pairs(ret) do
	out[#out+1] = {k,v}
end

--table.sort(out, function(a,b) return a[2]>b[2] end) -- additional stuff here - optional
local res = {};
for i = 1, #out do
	res[#res+1] = out[i][1] .. " = " .. out[i][2]
end

self.label("#objects " .. #objs .. "\n" .. table.concat(res, "\n"))

--book.write(1,"",("#objects " .. #objs .. "\n" .. table.concat(res, "\n")))
--self.remove()



end