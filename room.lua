Room = {
	-- Return a table of default values, have to recreate it each time to avoid shared resources 'twixt instances
	default = function() return {
		players = {},
		name = "",
		desc="",
		exits={},
		objects={},
		flags = '0',
	} end
}

Room.__index = Room

Room.new = function(self,o)
	local o = o or {}
	
	for k,v in pairs(self.default()) do
		o[k] = o[k] or v
	end
	
	if not o.identifier then
		o.identifier = sql.get_identifier("rooms")
	end
	
	return setmetatable(o, self)
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
		if not player:eq(v) then
			s = s..v:message("standing")..". " -- Replace with v.messages.standing
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
-- ARCH:
-- Room.move(self, player, dir)
--   ARCH: check for keys/lock here?
--   if self:before_move(player, dir) == false then return end
--   moving logic
--   self:after_move(player, dir)

Room.do_move = function(self, player, dir)
	-- Get room at direction
	local destination = self.exits[dir]
	
	if destination then
		self:do_exit(player:proxy(), dir)
		player.room = destination
		tremove(self.players, player)
		 --fix "leaves to the up"
		
		-- Show the description of the destination
		table.insert(player.room.players, player)
		-- print("running player.room:do_enter")
		local f = player.room.do_enter
		
		f(player.room, player:proxy(),dir)
		--player.room:do_enter(player:proxy(), dir)
	else
		player:send("Can't go that way!")
	end
end

Room.do_enter = function(self, player, dir)
	self:broadcast(player.name.." enters from the "..oppdirs[dir], player)
	player:send(self:do_look(player))
end

Room.do_exit = function(self, player, dir)
	self:broadcast(player.name.." leaves to the "..dir, player)
end
--Room.do_enter? Room.do_enter_msg? 

Room.broadcast = function(self, message, player)
	for i,v in ipairs(self.players) do
		if not player or not player:eq(v) then v:send(message) end
	end
end

Room.search = function(self, name)
	
	if not name then return end
	-- Get lower case of search term
	local name = string.lower(name)
	
	parts = split(name, ".")
	name = parts[1]
	num = parts[2]

	if self.name:lower() == name then
		return self
	end
	
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

Room.setName = function(self, name)
	self.name = name	
end
