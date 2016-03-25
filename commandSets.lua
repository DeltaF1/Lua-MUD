local t = {
	Default = CommandSet:new{
		"go",
		"look",
		"quit",
		"emote",
		"pose",
		"quit",
		"chat",
		"dummymenu"
	},
	Builder = CommandSet:new{
		"inspect",
		"set",
		"create"
	},
	Moderator = CommandSet:new{
		"kick",
		"ban",
		"mute"
	},
	Admin = CommandSet:new{
		"stop",
		"run",
		"set-priv"
	}
}

t.Admin = t.Admin:union(t.Builder):union(t.Moderator)

return t