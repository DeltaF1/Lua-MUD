Room = {
	default = function() return {
		players = {},
		name = "",
		desc="",
		exits={},
		objects={}
	} end
}

Room.__index = Room

Room.do_look = function(self, player)
	local s = self.name..NEWL..NEWL..self.desc
	s = s..NEWL
	for i,v in ipairs(self.players) do
		if v ~= player then
			s = s..v.name.." is here. "
		end
	end
	return s
end

Room.do_move = function(self, player, dir)
	local destination = self.exits[dir]
	
	if destination then
		player.room = destination
		tremove(self.players, player)
		self:broadcast(colour("%{green}"..player.name).." leaves to the "..dir) --fix "leaves to the up"
		player:send(player.room:do_look(player))
		player.room:broadcast(colour("%{green}"..player.name).." enters from the "..oppdirs[dir])
		table.insert(player.room.players, player)
		
	else
		player:send("Can't go that way!")
	end
end

--Room.do_enter? Room.do_enter_msg? 

Room.broadcast = function(self, message, player)
	for i,v in ipairs(self.players) do
		if v ~= player then v:send(message) end
	end
end

Room.search = function(self, name)
	
	local name = string.lower(name)
	for i,v in ipairs(self.players) do
		if v.name:lower() == name or contains(v.aliases, name) then --aliases must be lower case... enforce this in an alias set command?
			return v
		end
	end
	
	for i,v in ipairs(self.objects) do
		if v.name:lower() == name or contains(v.aliases, name) then
			return v
		end
	end
end