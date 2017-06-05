
-- CommandSet, a container for what verbs are available to the player at any given time
--
-- CommandSet.new(t)
--   Creates a CommandSet out of a list of verb objects

-- CommandSet.find(t)
-- CommandSet.union(c)
-- CommandSet.sub(c)
-- CommandSet.intersect(c)

-- TODO: Move CommandSet out of player.lua
CommandSet = {}

CommandSet.__index = CommandSet

function CommandSet:new(t)
	-- If it is an array
	if t and isArray(t) then
		local arr = t
		t = {}
		-- For every verb in the array
		for i = 1,#arr do
			-- Add to our list
			t[arr[i]] = verbs[arr[i]]
		end
	else
		-- If the table is a CommandSet, set ourselves to a copy of its
		t = shallowcopy(t) or {}
	end
	
	return setmetatable(t, self)
end

-- Return a verb object from a name
function CommandSet:find(name)
	name = name:lower()
	local verb = self[name]
	if verb then
		return verb
	end
	for _,v in pairs(self) do
		for _, alias in ipairs(v.aliases) do
			-- Check to see if name matches pattern. e.g. "x" matches "^x$", ".slap" matches "^%.%w+$"
			if name:match("^"..alias.."$") then return v end
		end
	end
end


-- Get all commands that are common between two command sets
function CommandSet:intersect(c)
	-- Duplicate of self
	local t = CommandSet:new(self)
	for k,v in pairs(c) do
		-- If one of our keys is not present in the other command set
		if not self[k] then
			-- remove it from the clone
			t[k] = nil
		end
	end
	return t
end

-- Combine two command sets
function CommandSet:union(c)
	local t = CommandSet:new(self)
	for k,v in pairs(c) do
		t[k] = v
	end
	return t
end

function CommandSet:sub(c)
	local t = CommandSet:new(self)
	for k,v in pairs(c) do
		t[k] = nil
	end
	return t
end

-- TODO: Make local?
messages = {
	standing = "{name} is standing here"
}

-- messages is a metatable
messages.__index = messages

pronouns = {
	male = {
		i = "he",
		my = "his",
		mine = "his",
		myself = "himself"
	},
	female = {
		i = "she",
		my = "her",
		mine = "hers",
		myself = "herself"
	},
	neutral = {
		i = "they",
		my = "their",
		mine = "theirs",
		myself = "themself"
	},
	second = {
		i = "you",
		my = "your",
		mine = "yours",
		myself = "yourself"
	}
}

Player = {}

Player.__index = Player

setmetatable(Player, Mobile)

Player.default = function()
	return {
		name = "",
		aliases = {},
		colour = "green",
		desc = "A person with no distinguishing features, their blank face devoid of any human emotions",
		pronouns = pronouns.female,
		messages = {},
		filename = "misc.lua",
		hp = 5,
		ap = 0,
		maxap = 5,
	}
end

Player.message = function(self, message)
	assert(self.messages[message], "Invalid message '"..message.."'")
	return self:sub(self.messages[message])
end


-- Replace elements of a string with the value of the player at that key
-- e.g. "The coat that belongs to {name}" is turned into "The coat that belongs to Alice"
Player.sub = function(self, s)
	return s:gsub("{([^}]+)}", function(key)
		local t,k = resolve(self, key)
		if not t then
			print("Invalid key "..key)
		end
		return t[k]
	end)
end

-- Equality function, to be used in place of == when dealing with proxies
-- e.g. if proxy.eq(room.players[1]) then ...
Player.eq = function(self, o2)
	return self == o2
end

Player.do_look = function(self, player)
	return self.desc
end

-- TODO: Rewrite Player.send to do colour substitution, have optional argument "concat" by default set to
-- NEWL, then sendRaw can be for actually sending raw :P
Player.send = function(self, msg, concat)
	if concat == nil then
		concat = NEWL
	end
	self:sendRaw(msg..concat)
end

Player.sendRaw = function(self, msg)
	
	if self.room then
		msg = string.gsub(msg, "([%w_]+)", function(v)
			-- For every word, search the room for an object with that name
			local obj = self.room:search(v)
			
			-- If that name means an object, highlight it
			if obj and obj.colour then
				return colour("%{"..(obj.colour).."}"..v)
			end 
		end)
	end
	
	self.sock:send(msg)
end

Player.proxy = function(self)
	return makeProxy(self,
		{eq=true, name=true, desc=true, send=true, message=true}
		-- No set usage yet
	)
end

-- ARCH: Should any of this be offloaded into the menu handler instead?
Player.setMenu = function(self, prompt, f, input)
	input = input or {"y","n"}
	self.state = "menu"
	self.prompt = prompt
	self.menu = function(player, data)
		print("Got data in menu of "..data)
		for i = 1, #input do
			patt = "^"..input[i]
			print("Does the data match '"..patt.."'?")
			if data:match(patt) then
				print("Running the menu command!")
				f(player, data, i)
				return
			end
		end
		player:send("Invalid option!")
	end
end

Player.setState = function(self, state)
	self.prompt = nil
	self.state = state
end