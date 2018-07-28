--ENIGMA emulator by rnd
-- programming ~30 mins, total 3hrs 30 minutes with debugging - cause of youtube video with missing
-- key detail - reflector!

-- REFERENCES:
-- 1. https://en.wikipedia.org/wiki/Enigma_machine
-- 2. http://users.telenet.be/d.rijmenants/en/enigmatech.htm#reflector
-- 3. https://www.youtube.com/watch?src_vid=V4V2bpZlqx8&v=G2_Q9FoD-oQ

-- default settings
settings = {}
settings.set = function(reflector, plugboard, rotors)
settings.reflector = reflector or 2017
settings.plugboard = plugboard or 2017
settings.rotors = {}
if rotors then
  table.insert(settings.rotors, rotors[1])
  table.insert(settings.rotors, rotors[2])
  table.insert(settings.rotors, rotors[3])
  table.insert(settings.rotors, rotors[4])
else
  table.insert(settings.rotors, 0)
  table.insert(settings.rotors, 0)
  table.insert(settings.rotors, 0)
  table.insert(settings.rotors, 2018)
  table.insert(settings.rotors, 2017)
  table.insert(settings.rotors, 2020)
end
--if not enigma_encrypt then
if true then
   scramble = function(input,password,sgn) -- permutes text randomly, nice after touch to stream cypher to prevent block analysis
      _G.math.randomseed(password);
      local n = #input;
      local permute = {}
      for i = 1, n do permute[i] = i end --input:sub(i, i)
      for i = n,2,-1 do
         local j = math.random(i-1);
         local tmp = permute[j];
         permute[j] = permute[i]; permute[i] = tmp;
      end
      local out = {};
      if sgn>0 then -- unscramble
         for i = 1,n   do out[permute[i]] = string.sub(input,i,i) end
      else -- scramble
         for i = 1,n   do out[i] = string.sub(input,permute[i],permute[i]) end
      end
      return table.concat(out,"")
   end

   local permutation = function(n,password,sgn)  -- create random permutation of numbers 1,...,n
      _G.math.randomseed(password);
      local permute = {}
      for i = 1, n do permute[i] = i end
      for i = n,2,-1 do
         local j = math.random(i-1);
         local tmp = permute[j];
         permute[j] = permute[i]; permute[i] = tmp;
      end
      return permute;
   end

   -- produces permutation U such that U^2 = 1; modified fisher-yates shuffle by rnd
   local reflector = function(n,password)
      _G.math.randomseed(password)
      local permute = {}
      local used = {};
      for i = 1, n do permute[i] = i end
      local rem = n;
      
      for i = n,2,-1 do
         if not used[i] then
            local j = math.random(rem);
            -- now we need to find j-th unused idx
            local k = 1; local l = 0; -- k position, l how many we tried
            while l < j do
               if not used[k] then l=l+1; end
               k=k+1
            end
            j=k-1;
            
            used[i]=true; used[j] = true;
            local tmp = permute[j];
            permute[j] = permute[i]; permute[i] = tmp;
            rem = rem - 2;
         end
         
      end
      return permute;
   end


   local inverse_table = function(tbl)
      local ret = {};
      for i = 1,#tbl do
         ret[ tbl[i] ] = i;
      end
      return ret;
   end

   local rotors = {}; -- { permutation, work index }}
   local invrotors = {}; -- reversed tables

   -- SETUP REFLECTOR, ROTORS AND PLUGBOARD!
   local enigma_charcount = 127-32+1; -- n = 96
   local enigma_charstart = 32;
   local reflector = reflector(enigma_charcount,settings.reflector); -- this is permutation U such that U^2 = id --

   local plugboard = permutation(enigma_charcount,settings.plugboard,1); -- setup plugboard for enigma machine
   local invplugboard = inverse_table(plugboard);

   for i = 1,3 do rotors[i] = {rotor = permutation(enigma_charcount,settings.rotors[3 + i],1), idx = 0} end -- set up 3 rotors together with their indices
   for i = 1,3 do invrotors[i] = {rotor =  inverse_table(rotors[i].rotor)} end -- set up 3 rotors together with their indices

   -- how many possible setups:
   --[[
      n = charcount;
      rotors positions:  n^3
      plugboard wiring : n!
      reflector wiring: n! / (2^n * (n/2)!)
      TOTAL: (n!)^2*n^3 / ( 2^n * (n/2)! ) ~ 6.4 * 10^77
      rotor positions & plugboard wiring: (n!)*n^3 ~ 4.8 * 10^57 (n=43)
   --]]
   
   -- END OF SETUP

   local rotate_rotor = function(i)
      local carry = 1;
      for j = i,1,-1 do
         local idx = rotors[j].idx;
         idx = idx + 1;
         if idx>=enigma_charcount then
            carry = 1;
         else
            carry = 0;
         end
         rotors[j].idx = idx % enigma_charcount;
         if carry == 0 then break end
      end
   end

   local enigma_encrypt_char = function(x) -- x : 1 .. enigma_charcount
      -- E = P.R1.R2.R3.U.R3^-1.R2^-1.R1^-1.P^-1, P = plugboard, R = rotor, U = reflector
      x = plugboard[x];
      for i = 1,3 do
         local idx = rotors[i].idx;
         x = rotors[i].rotor[((x+idx-1) % enigma_charcount)+1];
      end
      
      x = reflector[x];
      
      for i = 3,1,-1 do
         local idx = rotors[i].idx;
         x = invrotors[i].rotor[x];
         x = ((x-1-idx) % enigma_charcount)+1
         
      end
      
      x = invplugboard[x];
      -- apply rotation to rotor - and subsequent rotors if necessary
      rotate_rotor(3)
      return x;
   end


  --enigma_encrypt = function(input)
   settings.encrypt = function(input)
      -- rotor settings!
      rotors[1].idx = settings.rotors[1]
      rotors[2].idx = settings.rotors[2]
      rotors[3].idx = settings.rotors[3]
      
      local ret =  "";
      for i = 1,#input do
         local c = string.byte(input,i) - enigma_charstart +1;
         --say(i .. " : " .. c)
         if c>=1 and c<=enigma_charcount then
            c = enigma_encrypt_char(c);
         end
         ret = ret .. string.char(enigma_charstart+c-1);
      end
      return ret

   end
  settings.decrypt = settings.encrypt
end

end

msg = self.listen_msg()
   if msg then
      msg = minetest.strip_colors(msg)
      local mark = string.find(msg,"@e") -- delimiter in chat
      if mark then
         msg = string.sub(msg,mark+2);
         msg = minetest.colorize("yellow",enigma_encrypt(msg))
         say(minetest.colorize("red","#decrypted : ") .. msg)
      end
   end

msg = self.sent_msg()
if msg then
   local msg = enigma_encrypt(msg);
say("@e" .. msg,true)
--   minetest.show_formspec("encrypted_text", "size[4,4] textarea[0,-0.25;5,5;text;;".. "@e" .. minetest.formspec_escape(msg) .. "]")
end


