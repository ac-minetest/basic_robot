-- return minetest object count for 5x5x5 blocks

if not init then init  = true

local objs = minetest.get_objects_inside_radius(self.pos(), 30000);
local ret = {};

local round = function(x) return math.floor(x/5)*5 end
local ret = {};

for i = 1, #objs do
  local p = objs[i]:get_pos();
  local phash = round(p.x) .. " " .. round(p.y) .. " " .. round(p.z);
  ret[phash] = (ret[phash] or 0) + 1
end

local out = {};
for k,v in pairs(ret) do
	out[#out+1] = {k,v}
end

table.sort(out, function(a,b) return a[2]>b[2] end)
local res = {};
for i = 1, #out do
	res[#res+1] = out[i][1] .. "=" .. out[i][2]
end

self.label("#objects " .. #objs .. "\n" .. table.concat(res, "\n"))



end