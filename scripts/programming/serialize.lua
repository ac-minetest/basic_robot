local serialize = function(tab) -- helper function
    local out = {};
    for k,v in pairs(tab) do
      if type(v)~= "table" then 
        out[#out+1] = ""..k .." = " ..v
      else
        out[#out+1] = ""..k .. " = " .. serialize(v)
      end
    end
    
    return "{"..table.concat(out,", ").."}"
end
