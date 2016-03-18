local colours = {"red","green","yellow","blue","magenta","cyan"}
return {			
	login1 = {
		f = function(player, data)
			print("Setting name to "..data)
			if #data == 0 then
				return
			end
			player.name = data
			
			--set to login2
			player.state = "chat"
			
			player.colour = colours[math.random(#colours)]
			
			player.room = rooms.starting
			--We really need to setup an init function!
			
			table.insert(player.room.players, player)
			player:send(player.room:do_look(player))
			player.room:broadcast("With a small crack "..player.name.." appears, along with a brisk wind", player)
		--if player.state == "login2" then
			--get password
			--get hash
			--load player data from file
		end,
		prompt = "Please enter your username:"
	},
	chat = {
		f = function(player, data)
			
			local parts = split(data)
			--for w in data:gmatch("[^ ]+") do table.insert(parts, w) end
			
			-- replace parts like "@here" or "@me" with names of objects?
			
			
			
			local cmd = parts[1]
			local verb
			local key
			for k,v in pairs(verbs) do
				for _, a in ipairs(v.aliases) do
					if cmd:match("^"..a.."$") then
						verb = v
						key = k
						break
					end
				end
			end
			
			
			
			if verb then
				local res = verb.f(player, parts, data)
				
				if res and type(res) == "table" then
					if res[1] == "error" then
						player:send(res[2])
						player:send("Try 'help "..key.."'")
					end
				end
			end
		end,
		prompt = ">"
	}
}