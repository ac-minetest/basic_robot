--wordle game by rnd (2022), made in 15 minutes

-- 5 letter word is picked randomly
-- you have 6 tries to guess the word, write it in and it will color letters:
-- green = correct letter, correct place, yellow = correct letter, wrong place, 
-- gray =  letter not in word!

if not init then init = true
	
	-- load this from file..
	wordlist = {
		"pulse", "audio", "solar", "bacon", "laser", "pizza", "maybe", "guess", "stuff",
		"seven", "world", "about", "again", "heart", "water", "happy", "sixty", "board", 
		"month", "angel", "death", "green", "music", "fifty", "three", "party", "piano", 
		"mouth", "woman", "sugar", "amber", "dream", "apple", "laugh", "tiger", "faith", 
		"earth", "river", "money", "peace", "forty", "words", "smile", "abate", "house",
		"alone", "watch", "lemon", "south", "erica", "anime", "after", "santa", "admin", 
		"jesus", "china", "blood", "megan", "thing", "light", "david", "cough", "story", 
		"power", "india", "point", "today", "anger", "night", "glory", "april", "candy", 
		"puppy", "above", "phone", "vegan", "forum", "irish", "birth", "other", "grace", 
		"queen", "pasta", "plant", "smart", "knife", "magic", "jelly", "black", "media", 
		--100
		"honor", "cycle", "truth", "zebra", "train", "bully", "brain", "mango", "under",
		"dirty", "robot", "eight", "fruit", "panda", "truck", "field", "bible", "radio", 
		"dance", "voice", "smith", "sorry", "paris", "being", "lover", "never", "royal", 
		"venus", "metal", "penny", "honey", "color", "cloud", "scarf", "state", "value", 
		"mouse", "north", "bread", "daily", "paper", "beard", "alive", "place", "chair", 
		"badge", "worth", "crazy", "photo", "dress", "table", "cross", "clear", "white",
		"march", "ocean", "belly", "ninja", "young", "range", "maria", "great", "sweet",
		"karen", "scent", "beach", "space", "clock", "allah", "peach", "sound", "fever", 
		"youth", "union", "daisy", "plate", "eagle", "human", "start", "funny", "right", 
		"molly", "guard", "witch", "dough", "think", "image", "album", "socks", "catch", 
		--200
		"sleep", "below", "organ", "peter", "cupid", "storm", "silly", "berry", "rhyme", 
		"carol", "olive", "leave", "whale", "james", "brave", "asian", "every", "arrow",
		"there", "ebola", "later", "bacon", "local", "graph", "super", "obama", "brown", 
		"onion", "simon", "globe", "alley", "stick", "spain", "daddy", "scare", "quiet", 
		"touch", "clean", "liver", "lucky", "given", "lunch", "child", "clone", "glove", 
		"meter", "nancy", "plain", "solid", "uncle", "shout", "bored", "early", "video", 
		"brian", "cheer", "texas", "often", "sushi", "chaos", "tulip", "alien", "apart", 
		"fight", "coach", "force", "trust", "angle", "beast", "craft", "chess", "skull", 
		"order", "judge", "swing", "drive", "shine", "stand", "stage", "oscar", "ember", 
		"worry", "drama", "raven", "sight", "short", "botox", "unity", "horse", "trout", 
		--300
		"devil", "spoon", "clown", "grand", "gnome", "binge", "paula", "award", "quick", 
		"cause", "close", "scout", "snail", "purse", "topic", "teeth", "sauce", "share", 
		"along", "worse", "movie", "reach", "giant", "quack", "shark", "first", "count",
		"agent", "shelf", "grape", "drink", "skate", "wrong", "cream", "snake", "heavy",
		"tooth", "heard", "idiot", "scary", "chain", "break", "valve", "agony", "salad", 
		"shell", "scope", "tupac", "track", "final", "crown", "group", "wagon", "doing", 
		"robin", "false", "small", "block", "brush", "salsa", "grain", "wings", "arian", 
		"allow", "habit", "stove", "tower", "stars", "total", "plane", "comet", "tweet", 
		"abide", "frown", "roman", "grant", "ready", "blast", "treat", "poppy", "biome", 
		"oasis", "roger", "ghost", "abode", "abort", "court", "petal", "flood", "cider", 
		--400
		"orion", "extra", "pearl", "gator", "rough", "koala", "melon", "price", "alpha", 
		"smell", "chase", "fresh", "quest", "store", "grove", "round", "sense", "chest", 
		"fancy", "loose", "match", "pluto", "sport", "sheep", "crime", "grade", "pride", 
		"lance", "billy", "virus", "twerp", "kenya", "model", "ledge", "tired", "level", 
		"juice", "quart", "amish", "flame", "event", "offer", "twist", "actor", "maple",
		"hinge", "proud", "boone", "nasty", "hyper", "paint", "press", "patch", "mercy", 
		"baker", "broom", "rhino", "putin", "greed", "inter", "curve", "giver", "flute",
		"class", "hyena", "stock", "sting", "fable", "loved", "chant", "focus", "bench", 
		"birds", "brand", "otter", "goose", "ought", "boron", "dodge", "sloth", "eager", 
		"serve", "fella", "cover", "genre", "cable", "apron", "worst", "tommy", "egypt"
		--500
	}
	
	word = wordlist[math.random(#wordlist)];
	letters = {}
	for i = 1,string.len(word) do letters[string.sub(word,i,i)] = true end
	responses = {};
	maxtries = 6
	self.label("GUESSWORD " .. word)
	self.label("WORDLE GAME\n\nINSTRUCTIONS:\ntry to guess 5 letter word by typing it in chat like\n\n:guess\n\nyou have " .. maxtries .. " tries.\n"..
	"gray color indicates letter is not in word, yellow color indicates letter is\nin word but not in correct position. green color indicates correct letter at\ncorrect position")
	self.listen(1)
end

speaker,msg = self.listen_msg()

if #responses == maxtries then 
	responses[#responses+1] = minetest.colorize("red","GAME OVER! correct word was " .. word)
	self.label(table.concat(responses,"\n"))
end

if msg and #responses<maxtries and string.sub(msg,1,1)==":" and string.len(msg)-1 == string.len(word) then
	
	msg = string.sub(msg,2)
	local out = {}
	local guessed = true
	
	for i = 1,string.len(word) do
		local c = string.sub(msg,i,i)
		local color = "white"
		if not letters[c] then 
			color = "gray"
			elseif c == string.sub(word,i,i) then 
				color = "green"
			else color = "yellow"
		end
		if color ~= "green" then guessed = false end
		out[#out+1] = minetest.colorize(color, c)
	end
	responses[#responses+1] = (#responses+1) .. ". " .. table.concat(out)
	if guessed == true then 
		responses[#responses+1] = "YOU WIN!"
		for i = 1,maxtries-#responses do responses[#responses+1] = " " end
	end
	
	self.label(table.concat(responses,"\n"))
	
end