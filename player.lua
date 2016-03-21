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
			if obj then
				return colour("%{"..(obj.colour or "green").."}"..v)
			end 
		end)
	end
	
	self.sock:send(msg)
end