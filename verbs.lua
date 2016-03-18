local t = {
	who={
		f = function(player, parts)
			local s = "Online:"..NEWL
			for i,v in pairs(players) do
				if v.state == "chat" then
					s = s..v.name..NEWL
				end
			end
			player.sock:send(s)
		end
	},
	quit = {
		f = function(player, parts)
			player.sock:send("Goodbye!"..NEWL)
			player.sock:close()
			print(tostring(player.name or player.sock).." has disconnected")
			players[player.sock] = nil
			tremove(clients, player.sock)
			if player.state == "chat" then
				player.room:broadcast(player.name.." vanishes in a puff of smoke. The scent of cinnamon lingers in the air")
			end
			
			--save player data to file
		end
	},
	look = {
		f = function(player, parts)
			--use parts to get item to look at
			player.sock:send(player.room:do_look(player)..NEWL)
		end
	},
	go = {
		f = function(player, parts)
			local dir = parts[1]=="go" and parts[2] or parts[1]
			local ndir
			for k,v in pairs(dirs) do
				if contains(k, dir) then
					ndir = v
					break
				end
			end
			
			if ndir then
				player.room:do_move(player, ndir)
				
			else
				player:send("Invalid direction!")
			end
		end,
		aliases = {
			"north", "n",
			"south", "s",
			"east", "e",
			"west", "w",
			"up", "u",
			"down", "d",
			"southeast", "se",
			"southwest", "sw",
			"northeast", "ne",
			"northwest", "nw",
			"walk"
		}
	},
	chat = {
		f = function(player, parts, data)
			if #parts < 2 then
				return {"error", "Please supply a sentence to say"}
			end
			
			local msg = data:match("[^ ]+ (.+)")
			
			player.room:broadcast(player.name..' says "'..msg..'"')
		end,
		aliases = {
			"say"
		}
	},
	emote = {	
		f = function(player, parts, data)
			-- Add pronoun parsing!
			--
			-- for part in parts:
			-- 	part = player.pronouns[part] or part
			--
			-- pronouns = {I = "she", my = "her", mine = "hers"}
			
			local msg = ""
			if not parts[1]:find("^%..+") then
				if #parts < 2 then
					return {"error", "Please supply a phrase to emote"}
				end
			else
				msg = parts[1]:gsub("%.(%a+)", "%1s").." " --Adds an s. e.g. .walk briskly becomes "walks briskly"
			end
			
			if #parts >= 2 then
				msg = msg..data:match("[^ ]+ (.+)")
			end
			
			msg = msg:gsub("(%a+)", function(v) return player.pronouns[v] end)
			
			player.room:broadcast(player.name.." "..msg)
		end,
		aliases = {
			"%.", "/me",
			"e", "%..+"
		}
	},
	stop = {
		f = function(player, parts)
			error("STOP COMMAND")
		end
	},
	
	run = {
		f = function(player, parts, data)
			-- NOT SAFE
			local payload = data:match("[^ ]+ (.+)")
			
			-- OH GOD WHY
			local f = loadstring(payload)
			
			_print = print
			print = function(msg)
				_print(msg)
				player:send(tostring(msg))
			end
			
			-- THE HUMANITY
			local result, err = pcall(f)
			
			print = _print
			
			-- HAVE MERCY ON MY SOUL
			player:send(tostring(err or result))
		end
	}
}

for k,v in pairs(t) do
	v.aliases = v.aliases or {}
	
	table.insert(v.aliases, k)
end

return t