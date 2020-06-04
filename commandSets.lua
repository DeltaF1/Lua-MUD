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

local t = {
	Default = CommandSet:new{
		"go",
		"look",
		"quit",
		"emote",
		"pose",
		"quit",
		"say",
		"help",
		"dummymenu",
		"attack",
		"exits",
		"manual",
    "take",
    "drop",
    "unlock",
	},
	Builder = CommandSet:new{
		"inspect",
		"set",
		"create",
		"ident",
	},
	Moderator = CommandSet:new{
		"kick",
		"ban",
		"mute",
		"save"
	},
	Admin = CommandSet:new{
		"stop",
		"run",
		"set-priv"
	},
	All = CommandSet:new(
		keys(verbs)
	)
}

t.Admin = t.Admin:union(t.Builder):union(t.Moderator):union(t.All)

return t
