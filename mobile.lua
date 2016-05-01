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

Arena = {}

Arena.__index = Arena

Arena.default = function()
	return {
		mobiles = {},
		timer = 0,
		maxTime = 7
	}
end

Arena.new = function(self, o)
	local o = o or {}
	
	for k,v in pairs(self.default()) do
		o[k] = o[k] or v
	end
	
	--table.insert(Arenas, self)
	table.insert(updateHandlers, o)
	
	return setmetatable(o, self)
end

Arena.update = function(self, dt)
	self.timer = self.timer - dt
	if self.timer <= 0 then
		for i= 1,#self.mobiles do
			-- Reset Action points of each member of the arena
			self.mobiles[i].ap = self.mobiles[i].maxap
		end
		self.timer = self.maxTime
	end
end

Arena.add = function(self, mob)
	table.insert(self.mobiles, mob)
	mob.arena = self
end

Arena.remove = function(self, mob)
	tremove(self.mobiles, mob)
end