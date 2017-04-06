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

Object.setName = function(self, name)
	self.name = name
	for i, str in ipairs(split(name)) do
		table.insert(self.aliases, str)
	end
end

Object.do_look = function(self, player)
	return self.desc
end