-- ANSI colour names
local colours = {"red","green","yellow","blue","magenta","cyan"}

return {
	login1 = {
		f = function(player, data)
			-- Can't set player's name to a 0-length string
			if #data == 0 then
				return
			end
			
			-- If there are any non alphanumeric characters in the data
			if data:find("%W") then
				player.sock:send("Invalid name, name must only contain alphanumeric characters (a-z, A-Z, 0-9)"..NEWL)
				return
			end
			
			player.name = data
			player.identifier = "player_"..player.name
			-- TBD add a "login2" state for password
			player.state = "chat"
			
			-- Mainly for debuggin, eventually colours will mean something. Maybe class/rank?
			player.colour = colours[math.random(#colours)]
			
			-- This should probably be adjustable for different spawnrooms or something
			player.room = rooms.starting
			-- We really need to setup an init function!
			
			table.insert(player.room.players, player)
			player:send(player.room:do_look(player))
			
			-- Announce the player entering the server
			player.room:broadcast("With a small crack "..player.name.." appears, along with a brisk wind", player)
		--if player.state == "login2" then
			--get password
			--get hash
			--load player data from file
		end,
		prompt = colour("%{green}Please enter your username:")
	},
	chat = {
		f = function(player, data)
			
			-- Don't do anything
			if #data == 0 then
				return
			end
			
			-- Get parts of data. e.g. "Why is the rum always gone?" will become {"Why", "is", "the", "rum", "always", "gone?"}
			local parts = split(data)
			
			-- replace parts like "@here" or "@me" with names of objects?
			
			-- First word sent
			local cmd = parts[1]
			
			
			
			-- Declare verb and name of verb
			local verb
			local key
			
			
			-- For every verb
			for k,v in pairs(verbs) do
				-- For every alias
				for _, a in ipairs(v.aliases) do
					-- Check if the command matches the command aliases, aliases can be patterns
					if cmd:match("^"..a.."$") then
						verb = v
						key = k
						break
					end
				end
			end
			
			if verb then
				-- Run the verb, passing in the player, split parts, and original data string
				local res = verb.f(player, parts, data)
				
				if res and type(res) == "table" then
					if res[1] == "error" then
						-- Send the error message
						player:send(res[2])
						
						if key ~= "help" then
							player:send("Try 'help "..key.."'")
						end
					end
				end
			end
		end,
		prompt = ">"
	}
}