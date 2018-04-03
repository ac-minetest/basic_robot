-- rnd 2017
if not s then
	s=0
	player0 ="";
	reward = "default:gold_ingot 6"
	price =  "default:gold_ingot";
	self.spam(1)
end
if s==0 then
	local player = find_player(5);
	if player then 
   player=player[1]
		if player~=player0 then 
			self.label("Hello " .. player .. ". Please insert one gold ingot in chest to play.\nYou need to roll 6 on dice to win 6 gold.") 
			player0 = player
		end
	else 
		self.label(colorize("red","Come and win 6 gold!"))
	end
	if check_inventory.forward(price) then
		take.forward("default:gold_ingot");
		self.label("Thank you for your gold. rolling the dice!")
		s=1
	end
elseif s==1 then
	roll = math.random(6);
	if roll == 6 then
		self.label("#YOU WIN!")
		say("#WE HAVE A WINNER! get 6 gold in chest!")
		insert.forward(reward)
		s=2
	else
		self.label(":( you rolled " .. roll.. ". Put gold in to try again.")
		s=0
	end
elseif s==2 then
	if not check_inventory.forward(reward) then s=0 self.label("Please insert one gold to continue playing") end
end