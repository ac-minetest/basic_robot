-- maze generation by rnd

-- http://en.wikipedia.org/wiki/Maze_generation_algorithm#Depth-first_search, recursive backtracker
-- representation of node coordinate (row,coloumn)=(i,j) -> (i-1)*n+j, i=1..n, j=1...m
-- representation of walls: below node k --> k, left of node k --> k+m.n

-- good overview of maze generation algorithms using javascript/html5
-- http://www.jamisbuck.org/presentations/rubyconf2011/index.html#recursive-backtracker

-- helper functions
--stack in lua
local stack={};
function stack.push(s,e) s[#s+1]=e end
function stack.pop(s) local r = s[#s];s[#s]=nil;return r end
--function table2string(s) local r = ""; for i,v in pairs(s) do r = r.. " ["..i.."]=".. v ; end return r end

function maze_deep_first_search(m,n,start,seed) -- returns a table of strings representing line renders

    local steps,maxsteps; steps= 0; maxsteps = 999999;
    local maze = {}
    maze.m = m; maze.n = n;
    maze.unvisited = {};maze.stack = {}; maze.walls = {};
    maze.free = maze.m*maze.n; 
    local i,j,k
    local nb,wall -- unvisited neighbbors, walls

    --init structures
    for i=1,maze.m do 
      for j =1,maze.n do
        k=(i-1)*maze.n+j;maze.unvisited[k]=true -- initially all cells unvisited
        maze.walls[k]=true;maze.walls[k+maze.n*maze.m]=true; -- walls are there
      end
    end

    _G.math.randomseed(seed)
    maze.current = start
    maze.unvisited [ maze.current ] = false;
    maze.free = maze.free-1; maze.stack[1+#maze.stack] = maze.current

    while maze.free>0 and steps<maxsteps do -- main loop
      steps=steps+1
      -- check current node neighbors
      k=maze.current
      j = k % maze.n;i=math.ceil(k/maze.n); -- get coords back from index
      if j==0 then j = maze.n end
      --print("coords current node "..k .. " = " .. i .. " " ..j)

      nb={};wall={}-- check unvisited neighbors & wall removals

      if i>1 then -- down 
        k=(i-2)*maze.n+j; if maze.unvisited[k] then wall[#wall+1]=k+maze.n;nb[#nb+1]=k end
      end
      if i<maze.m then -- up
        k=(i)*maze.n+j; if maze.unvisited[k] then wall[#wall+1]=k;nb[#nb+1]=k end
      end
      if j<maze.n then --right
        k=(i-1)*maze.n+j+1; if maze.unvisited[k] then wall[#wall+1]=k+maze.n*maze.m; nb[#nb+1]=k end
      end
      if j>1 then --left
        k=(i-1)*maze.n+j-1; if maze.unvisited[k] then wall[#wall+1]=k+1+maze.n*maze.m;nb[#nb+1]=k end
      end

      --print("           unvisited neighbors " .. table2string(nb))
      if (#nb)>0 then -- if unvisited neighbors, choose random one as next current node
        stack.push(maze.stack,maze.current) -- remember previous current node
        k=math.random(#nb); -- pick random unvisited neighbor
        maze.walls[wall[k]]=false; -- remove wall
        --print("      removed wall ".. wall[k])
        k=nb[k];
        maze.current = k; -- new current cell
        maze.unvisited[k]=false; maze.free =  maze.free-1 -- one less unvisited
        --print("new explore " .. k);

      elseif (#maze.stack)~=0 then -- no unvisited neighbors, backtrack using stack

        maze.current = stack.pop(maze.stack)
        --print("backtrack to "..maze.current)

      else -- even stack is empty, just pick random unvisited cell
        k = math.random(maze.free);	j=1;
        for i =1,maze.m*maze.n do
          if maze.unvisited[i] then
            if j==k then k=i; break end -- pick node
            j=j+1
          end
        end
        --print(" stack empty, random pick " ..k)
        maze.current=k;maze.unvisited[k]=false; maze.free = maze.free -1;
      end
    end -- of do

    -- render maze with chars, row by row
    maze.ret = {};
    local hor;local vert;
    local wall = "1"

    for i=1,maze.m do
      hor="";vert="";
      k= (i-1)*maze.n;
      -- horizontal
      for j = 1, maze.n do 
        k=k+1;		
        --    if maze.walls[k+maze.n*maze.m] then vert=vert.."X." else vert=vert.. "0." end
        --    if maze.walls[k] then hor=hor.."XX" else hor=hor.."X0" end
        if maze.walls[k+maze.n*maze.m] then vert=vert..wall.."0" else vert=vert.. "00" end
        if maze.walls[k] then hor=hor..wall..wall else hor=hor..wall.."0" end
      end
      maze.ret[1+#maze.ret]=hor..wall;maze.ret[1+#maze.ret]=vert..wall;
    end
    maze.ret[1+#maze.ret] = string.rep(wall,2*maze.n+1)
    return maze.ret
  end

-- RUN PROGRAM
  local maze=maze_deep_first_search(10,30,1,2015)
  --for _,v in pairs(maze) do print(v) end
  
  
  
make_maze = function(m,n,start,seed)  
	local pos =  self.spawnpos();pos.y=pos.y+1
	local p
	local maze=maze_deep_first_search(m,n,start,seed) -- m,n,start,seed
	local i,j,k;local p = {x=pos.x,y=pos.y,z=pos.z};
	for i,v in pairs(maze) do 
		p.x = pos.x+i
		for k = 1,string.len(v) do
			p.z=pos.z+k
				if string.sub(v,k,k)=="1" then
					minetest.set_node(p,{name="default:brick"})
					else minetest.set_node(p,{name="air"})
				end
			end
	end
end

make_maze(10,10,1,1)
self.remove()