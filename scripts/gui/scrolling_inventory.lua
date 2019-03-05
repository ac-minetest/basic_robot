if not init then
text = " hello world "
name = "rnd"
m = 8;
idx = 0;
n = string.len(text)

player = puzzle.get_player(name)
inv = player:get_inventory()
inv:set_list("main",{})
init = true

end

for i = 1, m do
	local j = (idx+i)%n + 1
	local c = string.byte(text,j)-97;
	if c<0 or c>30 then c = -97 end
	inv:set_stack("main", i,puzzle.ItemStack("basic_robot:button_" ..(97+c)))
end

idx = (idx + 1) % n
--self.remove()