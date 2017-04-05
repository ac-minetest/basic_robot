-- 1. MEMORY MANAGEMENT using array with addresses
-- note: this is all done "automatic" in c with malloc

mem = {};
mem.size = 10; -- how many available addresses in memory for each of internally used arrays
mem.freestk = {}; -- stack of free addresses in memory
mem.stkidx = mem.size;
for i = 1,mem.size do mem.freestk[i]=mem.size-i+1 end -- so: freestk = {memsize, memsize-1,...., 2, 1 } and head is at last one

mem.allocate = function()  -- pop free spot from stack
	if mem.stkidx>0 then
		mem.stkidx = mem.stkidx -1
		return mem.freestk[mem.stkidx+1]
	end
end

mem.free = function(addr) -- release spot and mark it as free
	if mem.stkidx>=mem.size then -- cant release anymore, all is free
		return
	end
	mem.stkidx = mem.stkidx +1;
	mem.freestk[mem.stkidx ] = addr;
end


-- 2. BALANCED BINARY SEARCH TREES USING POINTERS created with above MEMORY MANAGEMENT

idx = mem.allocate();

tree = {};
tree.data = { root = 0, count = 0, -- current root, element count
	left = {0}, parent = {0}, right = {0}, -- links
	key = {0}, -- value
	heightl =  {0}, heightr = {0} -- needed for balancing
	}; 
-- root: idx of root element, count: how many elements in tree
-- 6 arrays with data for node stored at address i in memory: 
-- left[i] == left child, right[i] = right child, parent[i] = parent, key[i] = stored value, if value left[i]== 0 then no left child...
-- heightl[i] = height of left subtree, heightr[i] = height of right subtree
-- NOTE: initially a root node is added

tree.insert = function (value)
	local data = tree.data;
	local idx = data.root;
	if data.count == 0 then data.key[idx] = key; data.count = 1 return true end -- just set root key and exit
	
	local key; 
	local cidx; -- child idx

	
	while (true) do -- insert into tree by walking deeper and doing comparisons
		
		key = data.key[idx];
		if value<key then 
			cidx = data.left[idx];
		else
			cidx = data.right[idx];
		end
		
		if cidx == 0 then -- we hit nonexistent child, lets insert here
			cidx = mem.allocate();
			if not cidx then return "out of space" end
			data.count = data.count+1
			data.key[cidx] = value;
			data.parent[cidx]=idx;data.left[cidx]=0;data.right[cidx]=0;
			data.heightl[cidx]=0;data.heightr[cidx]=0;
			
			-- update all heights for parents and find possible violation of balance property
			local vidx = 0; -- index where violation happens
			local vdir = 0; -- type of violation:  1: in left tree , 2: in right tree
			while (idx~=0) do
				if data.left[idx] == cidx then
					data.heightl[idx]=data.heightl[idx]+1
				else
					data.heightr[idx]=data.heightr[idx]+1;
				end
				
				if data.heightl[idx]>data.heightr[idx]+1 then 
					vidx = idx; vdir = 1 
				elseif data.heightr[idx]>data.heightl[idx]+1 then
					vidx = idx; vdir = 2
				end
				
				cidx = idx; -- set new child
				idx = data.parent[idx]; -- set new parent
			end
			if vidx~=0 then
				say("violation vidx " .. vidx .. " direction " .. vdir)
				-- TO DO: apply internal tree rotation to restore balance
				if vdir == 1 then -- left violation
					--[[ need to reconnect 3 nodes:
						  D <- vidx     C
						 / \           / \
						C   E   =>    A   D
					   / \               / \
					  A   B             B   E
					CHANGES: 
						C: new parent is old parent of D, new children are A,D
						B: new parent D, 
						D: new parent is C, new children are B,E
					--]]
					local Didx = vidx; local Dpar = data.parent[Didx];
					local Cidx = data.left[Didx];
					local Bidx = data.right[Cidx];
					local Aidx = data.left[Cidx];
					
					data.parent[Cidx] = Dpar;data.left[Cidx] = Aidx;data.right[Cidx] = Didx;
					data.parent[Bidx] = Didx;
					data.parent[Didx] = Cidx;data.left[Didx] = Bidx;
					
					
				else -- right violation
										--[[ need to reconnect 3 nodes:
						  B  <-vidx     C
						 / \           / \
						A   C   =>    B   E
					       / \       / \
					      D   E     A   D
					CHANGES: 
						B: new parent C, new children A,D
						C: new parent is old parent of B, new children are B,E
						D: new parent is B
					--]]
					local Bidx = vidx; local Bpar = data.parent[Bidx];
					local Cidx = data.right[Bidx];
					local Didx = data.left[Cidx];
					
					data.parent[Bidx] = Cidx;data.right[Bidx] = data.left[Cidx] 
					data.parent[Cidx] = Bpar;data.left[Cidx] = Bidx;
					data.parent[Didx] = Bidx;
				end
			end
			
		else
		-- we go deeper
			idx = cidx;
		end
	
	end
	
	tree.find = function(value)
		local idx = data.root;
		while (idx~=0) do
			key = data.key[idx];
			if key == value then return idx end
			if value<key then 
				idx = data.left[idx];
			else
				idx = data.right[idx];
			end
		end
	end
	
	tree.next = function(idx)
		local right = data.right[idx]; 
		local nidx = 0;
		if right~=0 then 
			--TO DO: smallest idx in right subtree
		else
			if data.parent[idx]==0 then
				return 0
			end
		end
	end
	
	tree.remove = function(idx)
		--TO DO :
		-- 1.find next element
		-- put it where idx was and move subtree..
	end
	
	
	
	
end