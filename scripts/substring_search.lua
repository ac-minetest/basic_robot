-- Rabin–Karp substring s search in string t
-- https://en.wikipedia.org/wiki/Rabin%E2%80%93Karp_algorithm


-- rnd 2017
-- ALGORITHM: 
-- 1.) loop compute hashes of all substrings of t of length |s| using rolling hash idea
-- 2.) if some hash matches hash of s check more closely ( waste |s| time here, so this should only occur with probability < O(1)/|s| so expected waste is O(1))

-- how to do 1) rolling hash: how does hash of string change if you remove first character and add new last character? ... dont need to recompute whole hash!

-- summary: we end up using O(|t|+|s| + (number of needed hits)*O(1)) time (if you want more than 1 hit..)
-- this is big improvement compared to O(|t|*|s|) when doing naive substring search

-- improvement: we could also precompute all substring hashes of length |s| and then compute hash of some string of same length and
-- do quick lookups for that hash ( hash of hash :) )

if not hash then

	hash = function(s,p)
		local length = string.len(s);
		local h = 0 ;
		for i = 1, length do
			h=(256*h + string.byte(s,i))%p
		end
		return h%p
	end

	getpower = function(p,k) -- safe computation of power 256^k in mod p arithmetic
		local r=1; for i = 1,k do r=(256*r) % p	end; return r
	end
	
	karpin_rabin = function(t,s)
		local ls = string.len(s);
		local lt = string.len(t);
		if lt<ls then return nil end
		
		local p = 10011;
		local hs = hash(s,p);
		local rht = hash(string.sub(t,1,ls),p); -- rolling hash
		
		if hs == rht then
			if s == string.sub(t,1,ls) then return 1 end -- match at position 1!		
		end
		local power256 = getpower(p,ls-1);
		
		for i = 2,lt-ls+1 do
			local c1 = string.byte(t,i-1); local c2 = string.byte(t,i+ls-1);
			rht = (256*(rht - c1*power256)+c2)%p; -- update rolling hash to hash of next substring; this is ok since: a===b then also a*c===b*c
			if hs == rht then
				if s == string.sub(t,i,i+ls-1) then return i end -- match at position i!		
			end
		end
		return nil
	end

	local t = "The Rabin–Karp algorithm is inferior for single pattern searching to Knuth–Morris–Pratt algorithm, Boyer–Moore string search algorithm and other faster single pattern string searching algorithms because of its slow worst case behavior. However, it is an algorithm of choice for multiple pattern search.";
	local s = "inferior";
	local chk = karpin_rabin(t,s)
	if chk then say("found '" .. s .. "' in text pos. " .. chk .." : ..." .. string.sub(t,chk,chk+50) .. "...") 
		else say("could not find '"..s.."' in text")
	end
	
end