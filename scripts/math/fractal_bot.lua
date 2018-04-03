-- robot can construct classic fractals like menger sponge, jerusalem cube,  sierpinski triangles,..
-- use: build a pattern at position 1,1,1 relative to robot. when run robot will analyse pattern and construct fractal
if not init then
	minetest.forceload_block(self.pos(),true)
	init = true; local spos = self.spawnpos(); 

	offsets = {["default:dirt"] = 0, ["default:wood"] = -1, ["default:cobble"] = 1}
	
	read_form = function(fractal) -- read shape from world
		local form = {}; local i = 0;
		local spos = self.spawnpos(); spos.x = spos.x+1;spos.y = spos.y+1;spos.z = spos.z+1;
		local nx = 0; local ny = 0; local nz = 0;
		fractal.form = {}
		
		for x = 0,fractal.nx-1 do
			for y = 0,fractal.ny-1 do
				for z = 0,fractal.nz-1 do
					local node = _G.minetest.get_node({x=spos.x+x,y=spos.y+y,z=spos.z+z}).name;
					local offset = offsets[node] or 0;
					if node~= "air" then
						form[i] = {x,y,z,offset}; i=i+1
						if nx<x then nx = x end
						if ny<y then ny = y end
						if nz<z then nz = z end
					end
				end
			end
		end
		
		form[0] = nil;
		fractal.form = form;
		fractal.nx = nx+1; fractal.ny = ny+1; fractal.nz = nz+1;
	end
	
	
	iterate = function(fractal)
		local m = #sponge;
		local nx = fractal.nx;
		for j = 1, #sponge do
			local scoords = sponge[j];
			for i = 1, #(fractal.form) do
				local coords = (fractal.form)[i];
				sponge[#sponge+1] = {scoords[1] + (coords[1]+coords[4]/nx)*sidex, scoords[2] + coords[2]*sidey, scoords[3] + coords[3]*sidez};
			end	
		end
		sidex = sidex * fractal.nx;
		sidey = sidey * fractal.ny;
		sidez = sidez * fractal.nz;
	end
	
	make = function(fractal, iter)
		sidex = 1;sidey = 1;sidez = 1;
		sponge = {{0,0,0}};
		for i = 1, iter do
			iterate(fractal)
		end
	end
	
	build = function(sponge)
		
		local grid = 2^2;
		local spos = self.spawnpos(); spos.x = spos.x+1;spos.y = spos.y+1;spos.z = spos.z+1;
		for j = 1, #sponge do
			local scoords = sponge[j];
			--local color = (math.floor(scoords[1]/grid) + math.floor(scoords[3]/grid)) % 2;
			local nodename = "default:stonebrick"
			--if color == 0 then nodename = "default:goldblock" else nodename = "default:diamondblock" end
			minetest.swap_node({x=spos.x+scoords[1],y=spos.y+scoords[2],z=spos.z+scoords[3]},{name = nodename})
		end
	end
	
	clear = function()
		
		local grid = 2^2;
		local spos = self.spawnpos(); spos.x = spos.x+1;spos.y = spos.y+1;spos.z = spos.z+1;
		for j = 1, #sponge do
			local scoords = sponge[j];
			minetest.swap_node({x=spos.x+scoords[1],y=spos.y+scoords[2],z=spos.z+scoords[3]},{name = "air"})
		end
	end
	
	
	fractal0 = { nx = 5, ny = 5, nz = 5, form = {} }
	read_form(fractal0)
	self.label("form count: " .. 1+#fractal0.form .. " dim " .. fractal0.nx .. " " .. fractal0.ny .. " " .. fractal0.nz)

	make(fractal0,3);
	build(sponge)

end

--self.remove()