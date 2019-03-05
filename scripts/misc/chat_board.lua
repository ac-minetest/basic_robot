-- simple chat board by rnd
if not init then init = true

pos = self.pos()


write_text = function(text,size)
for x=0,size-1 do
  for y = size-1,0,-1 do
    local c = (string.byte(text, (size-1-y)*size+(x+1)) or 32)-97
    puzzle.set_node({x=pos.x+x+1,y=pos.y+y,z=pos.z},{name = "basic_robot:button_"..(97+c)})
  end
end
end

self.listen(1)

end

speaker,msg= self.listen_msg()
if msg then
 write_text(msg,15)
end