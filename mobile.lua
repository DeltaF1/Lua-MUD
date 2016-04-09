Mobile = {}

Mobile.__index = Mobile

Mobile.default = function()
	return {
		
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