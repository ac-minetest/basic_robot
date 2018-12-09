-- gui demo by rnd

if not init then 
	init = true
	name = "rnd"
	color = {"white","black"}
	data = {};
	n = 20;

	f = function(x) return 7*(1+math.sin(x/2)) end

	for i = 1,n do
	data[i]={};
	local y = math.floor(f(i));
	for j = 1,n do
	 data[i][j] = (n-j>y) and 2 or 1
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

sender,fields = self.read_form()
if fields then
	if fields.quit then self.remove() end
	local sel = 0;
	for k,v in pairs(fields) do
		if k ~="quit" then  sel = tonumber(k); break end
	end
	local x = 1+math.floor(sel/n); local y =  1+sel % n; 
	data[x][y] = 3 - data[x][y]
	--self.label(x .. " " .. y)
	self.show_form(name,get_form())
end