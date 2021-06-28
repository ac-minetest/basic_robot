	-- given position ibeg in string find next word, return it and then return position immediately after word.
	-- word is a sequence of alphanumeric characters
	-- example 'hello world', ibeg = 1. -> 'hello', 6

	get_next_word = function(code, ibeg,iend) -- attempt to return next word, starting from position ibeg. returns word, index after word
		if not ibeg or not iend then return end
		local j = string.find(code,"%w",ibeg); -- where is start of word?
		if not j or j>iend then return "", iend+1 end -- no words present
		ibeg = j;
		j = string.find(code,"%W",j);--where is end of word?
		if not j or j>iend then return string.sub(code,ibeg,iend-1),iend+1 end
		return string.sub(code,ibeg,j-1), j
	end

	text = [[
	hello world
	today
	day night
	]]
	ibeg = 1; iend = string.find(text,"\n",ibeg) or string.len(text) -- where is next new line
	say("INIT LINE " .. ibeg .. " " .. iend .. " LINE '" .. string.sub(text,ibeg,iend-1) .."'")

	
	for i = 1,10 do

	
	word, ibeg = get_next_word(text,ibeg,iend)
	say("word '" .. word.."', end " .. ibeg)
	if ibeg>=iend then  -- newline!
		--say("newline")
		local j = ibeg;
		iend = string.find(text,"\n", iend+1) -- find next newline
		
		if not iend then say("END") iend = string.len(text) break end -- end of text!
		say("LINE " .. ibeg .. " " .. iend .. " LINE '" .. string.sub(text,ibeg,iend-1) .."'")
	end

	end

	self.remove()