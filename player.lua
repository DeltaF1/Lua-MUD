
-- CommandSet, a container for what verbs are available to the player at any given time
--
-- CommandSet.new(t)
--   Creates a CommandSet out of a list of verb objects

-- CommandSet.find(t)
-- CommandSet.union(c)
-- CommandSet.sub(c)
-- CommandSet.intersect(c)
CommandSet = {}

CommandSet.__index = CommandSet

function CommandSet:new(t)
	-- If it is an array
	if t and isArray(t) then
		print("t is an array!")
		local arr = t
		t = {}
		for i = 1,#arr do
			t[arr[i]] = verbs[arr[i]]
		end
	else
		t = shallowcopy(t) or {}
	end
	
	return setmetatable(t, self)
end

function CommandSet:find(name)
	name = name:lower()
	local verb = self[name]
	if verb then
		return verb
	end
	for _,v in pairs(self) do
		for _, alias in ipairs(v.aliases) do
			if name:match("^"..alias.."$") then return v end
		end
	end
end

function CommandSet:intersect(c)
	local t = CommandSet:new(self)
	for k,v in pairs(c) do
		if not self[k] then
			t[k] = nil
		end
	end
	return t
end

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
		self[k] = nil
	end
	return t
end

messages = {
	standing = "{name} is standing here"
}

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

Player.default = function()
	return {
		name = "",
		aliases = {},
		colour = "green",
		desc = "A person with no distinguishing features, their blank face devoid of any human emotions",
		pronouns = pronouns.female,
		messages = {}
	}
end

Player.new = function(o)
	-- Either create a new object, or turn existing table into an instance
	local o = o or {}
	
	-- Fill in missing values
	for k,v in pairs(Player.default()) do
		o[k] = o[k] or v
	end
	
	setmetatable(o.messages, messages)
	
	return setmetatable(o, Player)
end

Player.message = function(self, message)
	assert(self.messages[message], "Invalid message '"..message.."'")
	return self:sub(self.messages[message])
end

Player.sub = function(self, s)
	return s:gsub("{([^}]+)}", function(key)
		local t,k = resolve(self, key)
		if not t then
			print("Invalid key "..key)
			
		end
		return t[k]
	end)
end

Player.do_look = function(self, player)
	return self.desc
end

Player.send = function(self, msg)
	self:sendraw(msg..NEWL)
end

Player.sendraw = function(self, msg)
	
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
		{"name", "desc", "send", "message"},
		{
			
		}
	)
end

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