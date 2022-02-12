-- calender by rnd, 30 minutes with bugfixes

dayofweek = function(y,m,d)
  local offsets = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
  if m<3 then y=y-1 end
  return (y+math.floor(y/4)-math.floor(y/100)+math.floor(y/400)+offsets[m]+d) % 7+1
end

y=2000
m=8
d=1
--say(dayofweek(y,m,d))



make_calender = function(y,m)
	local start_day = dayofweek(y,m,1)
	local months = {31,29,31,30,31,30,31,31,30,31,30,31};
	if y%4==0 and (y%100~=0 or y%400 == 0) then months[2]= 30 end -- feb has 30 days on leap year
	local out = minetest.colorize("red",m.."/"..y).."\nsun mon tue wed thu fri   sat\n"
	out = out .. string.rep("__   ",start_day-1)
	local i = start_day;
	local idx = 1;
	while idx<=months[m] do
		out = out .. string.format("%02d",idx) .. "   ";
		if i%7 ==0 then out = out .."\n" end
		idx = idx+1
		i=i+1
	end
	
	
	return out
end

ret = {}
for m = 1,12 do
	ret[#ret+1]=make_calender(y,m)
end

self.label(table.concat(ret,"\n\n"))