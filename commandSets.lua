local t = {
	Default = CommandSet:new{
		"go",
		"look",
		"quit",
		"emote",
		"pose",
		"quit",
		"chat",
		"help",
		"dummymenu",
	},
	Builder = CommandSet:new{
		"inspect",
		"set",
		"create"
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