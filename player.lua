Player = {}

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
	
}

Player.__index = Player

Player.default = function()
	return {
		name = "",
		aliases = {},
		colour = "green",
		pronouns = 
	}
end

Player.new = function(o)
	local o = o or {}
	for k,v in pairs(Player.default()) do
		o[k] = o[k] or v
	end
	return setmetatable(o, Player)
end

Player.send = function(self, msg)
	self:sendraw(msg..NEWL)
end

Player.sendraw = function(self, msg)
	
	local newmsg = string.gsub(msg, "([%w_]+)", function(v)
		local obj = self.room:search(v)
		if obj then
			return colour("%{"..(obj.colour or "green").."}"..v)
		end 
	end)
	self.sock:send(newmsg)
end