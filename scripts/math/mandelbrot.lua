-- mandelbrot by rnd,2022 , made in 30 mins
if not init then init = true

n=100
local itermin = 10; -- check quicker if diverge!
local itermax = 250; -- max iterations
local delta = 0.00001^2; -- convergence difference

nodes = {
"white","yellow","orange","red",
"magenta","purple","blue","cyan",
"green","dark_green","brown","tan",
"light_grey","medium_grey","dark_grey","black"
}
for i = 1,#nodes do nodes[i] = "basic_robot:button"..nodes[i] end

get_pixel = function()
	local iter = 0
	local zr=0 ; local zi=0 ;
	for i = 1, itermin do
		local zrn=zr^2-zi^2+cr;
		local zin=2*zr*zi+ci
		zr=zrn
		zi=zin
	end
	if zr^2+zi^2>1 then return -1 end

	local zrn=zr^2-zi^2+cr;
	local zin=2*zr*zi+ci
	if (zrn-zr)^2+(zin-zi)^2< delta then return 1 end
	
	for i = 1, itermax do
		local zrn=zr^2-zi^2+cr;
		local zin=2*zr*zi+ci
		if (zrn-zr)^2+(zin-zi)^2< delta then return i-1 end
		zr=zrn
		zi=zin
	end
	return itermax-1
end

pos = self.pos()
local nnodes = #nodes
for x=1,n do
for y=1,n do
cr=2*x/n-1; ci=2*y/n-1
local col = get_pixel()
if col>0 then 
	col = math.floor(nnodes*col/itermax)
	minetest.swap_node({x=pos.x+x,y=pos.y,z=pos.z+y},{name = nodes[col+1]}) 
end
end
end

self.remove()

end


