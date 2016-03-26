Room = {
	-- Return a table of default values, have to recreate it each time to avoid shared resources 'twixt instances
	default = function() return {
		players = {},
		name = "",
		desc="",
		exits={},
		objects={},
		filename="misc.lua"
	} end
}

Room.__index = Room

Room.new = function(o)
	local o = o or {}
	
	for k,v in pairs(Room.default()) do
		o[k] = o[k] or v
	end
	
	return setmetatable(o, Room)
end

Room.do_look = function(self, player)

	-- NAME
	--
	-- DESC
	local s = colour("%{green}"..self.name)
	s = s..NEWL..NEWL
	s = s..self.desc
	
	-- If there are players here, add a newline to separate from the player list
	if #self.players > 1 then
		s = s..NEWL
	end
	
	for i,v in ipairs(self.players) do
		if v ~= player then
			s = s..v:message("standing").."." -- Replace with v.messages.standing
		end
	end
	return s
end

-- Attach one room to another. e.g. Closet:attach(rooms.lobby, "out")
function Room.attach(self, room, dir)
	local oppdir = oppdirs[dir]
	
	self.exits[dir] = room
	
	if oppdir then
		room.exits[oppdir] = self
	else
		-- Log("Added room at non-cardinal direction: "..dir)
		return
	end
end

function Room.detach(self, dir)
	local oppdir = oppdirs[dir]
	
	if oppdir and self.exits[dir] then
		self.exits[dir].exits[oppdir] = nil
	end
	
	self.exits[dir] = nil
end

Room.do_move = function(self, player, dir)
	-- Get room at direction
	local destination = self.exits[dir]
	
	if destination then
		player.room = destination
		tremove(self.players, player)
		self:broadcast(player.name.." leaves to the "..dir) --fix "leaves to the up"
		
		-- Show the description of the destination
		player:send(player.room:do_look(player))
		player.room:broadcast(player.name.." enters from the "..oppdirs[dir])
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
	
	-- Get lower case of search term
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