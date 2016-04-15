Mobile = {}

Mobile.__index = Mobile

Mobile.default = function()
	return {
		name = "",
		aliases = {},
		messages = {},
		filename = "misc.lua",
		hp = 5
	}
end

Mobile.new = function(self,o)
	-- Either create a new object, or turn existing table into an instance
	local o = o or {}
	
	-- Fill in missing values
	for k,v in pairs(self.default()) do
		o[k] = o[k] or v
	end
	
	setmetatable(o.messages, messages)
	
	return setmetatable(o, self)
end

Mobile.damage = function(self, num)
	self.hp = self.hp - num
	
	if self.hp <= 0 then
		self:send("You died!")
		-- TP home? Delete character?
	end
end