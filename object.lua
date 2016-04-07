Object = {}

Object.__index = Object

Object.default = function()
	return {
		name = "",
		aliases = {},
		desc = "A boring object",
		filename = "misc.lua"
	}
end

Object.new = function(self,o)
	-- Either create a new object, or turn existing table into an instance
	local o = o or {}
	
	-- Fill in missing values
	for k,v in pairs(self.default()) do
		o[k] = o[k] or v
	end
	
	return setmetatable(o, self)
end

Object.do_look = function(self, player)
	return self.desc
end