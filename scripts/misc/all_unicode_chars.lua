--ALL UNICODE by rnd, 2021

-- range to 32-1550, then 7400-10000
--cyrillic 0410-042F: 1040-1071
--cyrilic 0430-044F: 1072-1103
if not  init then init = true

function utf8(decimal)
	local bytemarkers = { {0x7FF,192}, {0xFFFF,224}, {0x1FFFFF,240} }
    if decimal<128 then return string.char(decimal) end
    local charbytes = {}
    for bytes,vals in ipairs(bytemarkers) do
      if decimal<=vals[1] then
        for b=bytes+1,2,-1 do
          local mod = decimal%64
          decimal = (decimal-mod)/64
          charbytes[b] = string.char(128+mod)
        end
        charbytes[1] = string.char(vals[2]+decimal)
        break
      end
    end
    return table.concat(charbytes)
  end
 
ret= {"ALL UNICODE\n0 = "}

for i = 1550, 4000 do 
if i%25==0 then ret[#ret+1] = "\n"..(i).. " = "  end
ret[#ret+1] = utf8(i)
end
self.label(table.concat(ret))


end