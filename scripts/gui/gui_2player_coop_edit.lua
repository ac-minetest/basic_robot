-- gui demo by rnd
-- 2 player cooperative editing of image with 2 colors

if not init then 
  _G.basic_robot.data[self.name()].obj:get_luaentity().timestep = 0.25
	init = true
	name = "rnd"
	otherrobotname = "rnd2" -- on other robot do name of this robot
	drawcolor = 3;  -- other robot has reversed colors
	otherdrawcolor = 4
	
	color = {"black","white","blue","green"}
	data = {};
	n = 20;

	for i = 1,n do
	data[i]={};
	--local y = math.floor(f(i));
	for j = 1,n do
	 data[i][j] = 1--(n-j>y) and 2 or 1
	end
	end

	get_form = function()
		local form  = "size[10,10] "; ret = {};

		for i = 1,n do 
		for j = 1,n do
		ret[#ret+1] = "image_button["..((i-1)*0.5)..","..((j-1)*0.5)..";0.7,0.63;wool_"..color[data[i][j]]..".png;"..((i-1)*n+j-1) .. ";] "
		end
		end
		return form .. table.concat(ret,"")
	end

	self.show_form(name,get_form())
	self.read_form()
end

sender,mail = self.read_mail()
if mail then
	local x = mail[1]; local y = mail[2];
	if data[x][y]==1 then data[x][y] = otherdrawcolor else data[x][y] = 1 end
	self.show_form(name,get_form())
end

sender,fields = self.read_form()
if fields then
	if fields.quit then self.remove() end
	local sel = 0;
	for k,v in pairs(fields) do
		if k ~="quit" then  sel = tonumber(k); break end
	end
	local x = 1+math.floor(sel/n); local y =  1+sel % n; 
	if data[x][y]==1 then data[x][y] = drawcolor else data[x][y] = 1 end
	self.send_mail(otherrobotname,{x,y})
	self.show_form(name,get_form())
end