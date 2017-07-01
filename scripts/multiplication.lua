if not number then
	number = {};
	number.base = 10; -- what base: 2-10
	number.data = {};
	number.size = -1;
	
	function number:tostring()
		local ret = ""
		--say("tostring size " .. self.size)
		for i = self.size,1,-1 do ret = ret .. (self.data[i] or "X").."" end
		return ret
	end
	
	function number:new(data)
      local o = {};_G.setmetatable(o, self); o.data = {};
	  for i = 1,#data do o.data[i] = data[i] end -- do copy otherwise it just saves reference
      o.size = #data;
	  self.__index = self; return o
    end
	
	number.add = function (lhs, rhs,res) 
		local n1 = lhs.size;local n2 = rhs.size;local n = math.max(n1,n2);
		local carry=0, sum; local base = lhs.base;
		local out = false;
		if not res then res = number:new({}) out = true end
		local data = res.data
		for i = 1,n do
			sum = (lhs.data[i] or 0)+(rhs.data[i] or 0)+carry;
			if carry>0 then carry = 0 end
			if sum>=base then data[i]=sum-base; carry = 1 else data[i] = sum end
		end
		if carry>0 then data[n+1]=1 res.size = n+1 else res.size = n end
		if out then return res end
	end
	
	number.__add = add;
	
	function number:set(m)
		local data = self.data;
		local mdata = m.data;
		for i=1,#mdata do
			data[i]=mdata[i];
		end
		self.size = m.size;
	end
	
	-- 'slow' long multiply
	number.multiply = function (lhs, rhs, res)
		local n1 = lhs.size;local n2 = rhs.size;local n = n1+n2;
		--say("multiply sizes " .. n1 .. "," .. n2)
		local out = false;
		if not res then res = number:new({}); out = true end;
		res.size = n1+n2-1;
		res.data = {} -- if data not cleared it will interfere with result!
		local data = res.data;
		local c,prod,carry = 0; local base = lhs.base;
		for i=1,n1 do
			carry = 0;
			c = lhs.data[i] or 0;
			for j = 1,n2 do -- multiply with i-th digit and add to result
				prod = (data[i+j-1] or 0)+c*(rhs.data[j] or 0)+carry;
				carry = math.floor(prod / base);
				prod = prod % base;
				data[i+j-1] = (prod)%base;
			end
			if carry>0 then data[i+n2] = (data[i+n2] or 0)+ carry ;if res.size<i+n2 then res.size = i+n2 end end
		end
		if out then return res end
	end
	
	--TO DO
	number.karatsuba_multiply = function(lhs,rhs,res)
		local n1 = lhs.size;local n2 = rhs.size;
		local n0 = math.max(n1,n2); 
		if n0< 2 then  -- normal multiply for "normal" sized numbers
			number.multiply(lhs, rhs, res)
			return
		end
		
		n0 = math.floor(n0/2);
		local n = n1+n2;
		
		local a1 = number:new({});
		local tdata = a1.data;  local sdata = lhs.data;
		for i = 1,n0 do tdata[i] = sdata[i] or 0 end; a1.size = n0;
		local a2 = number:new({}); tdata = a2.data;
		for i = n0+1,n1 do tdata[i-n0] = sdata[i] or 0 end; a2.size = n1-n0;
		
		local b1 = number:new({});
		local tdata = b1.data;  sdata = rhs.data;
		for i = 1,n0 do tdata[i] = sdata[i] or 0 end; b1.size = n0;
		local b2 = number:new({}); tdata = b2.data;
		for i = n0+1,n1 do tdata[i-n0] = sdata[i] or 0 end; b2.size = n1-n0;
		
		--say("a1 " .. a1:tostring())
		--say("a2 " .. a2:tostring())
		
		--say("b1 " .. b1:tostring())
		--say("b2 " .. b2:tostring())
		
		
		local A = number:new({}); number.karatsuba_multiply(a1,b1,A);
		local B = number:new({}); number.karatsuba_multiply(a2,b2,B);
		local C = number:new({}); number.karatsuba_multiply(a1+a2,b1+b2,C);
		--== C-A-B
		--TODO minus, reassemble together..
		
	end
	
	karatsuba_multiply_test = function()
		--local in2 = number:new({2,1,1})
		--local in1 = number:new({2,1,1})
		local res = number:new({});
		local in1 = number:new({3,1,4}); --413 
		local in2 = number:new({7,2,5}); -- 527
		number.karatsuba_multiply(in1,in2,res)
	end
	
	karatsuba_multiply_test()
	
	
	multiply_test = function()
		--local in2 = number:new({2,1,1})
		--local in1 = number:new({2,1,1})
		local res = number:new({});
		local in1 = number:new({4})
		number.multiply(in1,in1,res)
		say("mult check 1 " .. res:tostring())
		--say("mult check 2 " .. number.multiply(in1,in2):tostring())
		
	end
	--multiply_test()
	
	number.__mul = number.multiply;
	
	number.power = function(n,power_) -- calculate high powers efficiently - number of steps is log_2(power)
		local power = power_;
		local input = number:new(n.data);
		local out = number:new({});
		
		local count = 0;
		
		local r; local powerplan = {}; -- 0: just square a->a^2, 1 = square and multiply a-> a*a^2
		while (power>0) do
			r=power%2; powerplan[#powerplan+1] = r; power = (power-r)/2
		end
		
		for i = #powerplan-1,1,-1 do
			
			number.multiply(input,input,out); 
			
			if powerplan[i] == 1 then
				input,out = out, input;
				number.multiply(input,n,out); count = count + 2
			else count = count + 1;
			end
			
			input,out = out, input;
		end
		
		return input
	end
	
	split = function(s,k)
		local ret = "";
		local j=1,length; length = string.len(s)/k
		for i = 1, length do
			j = (i-1)*k+1;
			ret = ret .. string.sub(s,j,j+k-1) .. "\n"
		end
		--say("j " .. j)
		if j>1 then j = j+k end
		ret = ret .. string.sub(s,j)
		return ret
	end
	
	self.spam(1)
	
	-- little endian ! lower bits first ..

	--n = number:new({7,1,0,2}); local power = 2017;
	--self.label(split(n:tostring().."^"..power .. " = " .. number.power(n,power):tostring(),100))
	--2017^2017  = 3906...
end