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
			clients[player.sock] = nil
			
			if player.state == "chat" then
				player.room:broadcast(player.name.." vanishes in a puff of smoke. The scent of cinnamon lingers in the air", player)
			end
			if player.room then
				tremove(player.room.players, player)
			end
			--save player data to file
		end
	},
	look = {
		f = function(player, parts)
			local obj
			if #parts < 2 then
				obj = player.room
			else
				obj = player.room:search(parts[2])
			end
			if not obj then return player:send("Could not find "..parts[2]) end
			player:send(obj:do_look(player))
		end,
		aliases = {
			"ex", "x", "examine"
		}
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
	pose = {	
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
					return {"error", "Please supply a phrase to pose"}
				end
				msg = data:match("[^ ]+ (.+)")
			else
				msg = data
			end
			--[[
			if #parts >= 2 then
				msg = msg..data:match("[^ ]+ (.+)")
			end
			--]]
			msg = msg
			
			msg = player.name.." "..msg
			
			for i,p in ipairs(player.room.players) do
				local newmsg = msg:gsub("%.(%a+)", function(v)
					-- for verb in gmatch(%.%S+) do verb..s or verb[conjugations]
				
					-- ShinMojo @ sindome.org ([^aeiouy]|qu)y$"-> "$1ies" and (x|ch|ss|sh)$ -> "$1es"
					--Adds an s. e.g. .walk briskly becomes "walks briskly"
					-- v = v:gsub(ShinMojo pattern (need RegEx or custom pattern builder))
					
					-- If pronouns.neutral and last used pronoun ~= nil
					if p == player then return v end-- secondPersonOfVerb(v)
					local cap = v:multimatch({"([^aeiouy]y)$","(quy)$"})
					if cap then
						return v:sub(1, #v-1).."ies"
					end
					cap = nil
					cap = v:multimatch({"(x)$", "(ch)$", "(ss)$","(sh)$"})
					
					if cap then
						return v.."es"
					end
					
					return v.."s"
				end):gsub("(\\?)(%a+)", function(except, v)
					if except ~= "" then return v end
					if p == player then return pronouns.second[v:lower()] end
					return player.pronouns[v:lower()]
				end
				):gsub(
					case_insensitive_pattern(p.name), "you"
				):gsub(
					"([%.%?%!]) (%a)", function(punctuation, letter) return punctuation.." "..letter:upper() end
				):gsub(
					"^%a", function(l) return l:upper() end
				)
				
				p:send(newmsg)
				--player:send(msg)
			end
		end,
		aliases = {
			"%.", "%..+"
		}
	},
	emote = {
		f = function(player, parts, data)
			if #parts < 2 then
				return {"error", "Please supply a phrase to emote"}
			end
			player.room:broadcast(player.name.." "..data:match("%S+ (.+)"))
		end,
		aliases = {
			"e", "/me"
		}
	},
	stop = {
		f = function(player, parts)
			player:setMenu("Are you sure you want to stop the server? ", function(p,_,i)
				if i == 1 then
					error("STOP COMMAND")
				else
					p:setState("chat")
				end
			end)
		end
	},
	--[[
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
	},--]]
	set = {
		f = function(player, parts, data)
			if #parts < 2 then
				return {"error", "Please supply an object to modify"}
			elseif #parts < 3 then
				return {"error", "Please supply what value you want to change"}
			elseif #parts < 4 then
				return {"error", "Please supply a new value"}
			end
			
			local name = parts[2]
			if name == "@here" then
				obj = player.room
			elseif name == "@me" then
				obj = player
			else
				obj = player.room:search(name)
			end
			if not obj then
				return "object not found!"
			end
			
			-- set hobo pronouns.myself "xirself"
			
			local key = parts[3]
			local obj, k = resolve(obj, key)
			if not obj then return player:send("Invalid keypath "..key) end
			print("Setting "..(obj.name or tostring(obj)).." at "..k)
			
			local payload = data:match("%S+ %S+ %S+ (.+)")
			
			payload = "return "..payload
			
			-- PLEASE SANDBOX THIS FOR THE LOVE OF GOD
			local success, newval = pcall(loadstring(payload))
			
			if not success then player:send(newval); return end
			
			if type(newval) == "function" then
				obj[k.."_str"] = payload
			end
			
			obj[k] = newval
		end
	},
	
	inspect = {
		f = function(player, parts)
			if #parts < 2 then
				return {"error", "Please supply an object to inspect"}
			end
			local obj
			
			local name = parts[2]
			if name == "@here" then
				obj = player.room
			elseif name == "@me" then
				obj = player
			else
				obj = player.room:search(name)
			end
			
			if not obj then return player:send("Object not found") end
			
			player:send(ser(obj, NEWL))
		end
	},
	social = {
		f = function(player, parts)
			
		end
	},
	save = {
		f = function(player, parts)
			for _,v in pairs(players) do
				v:send("Saving world...")
			end
			world_save.save()
		end
	},
	help = {
		f = function(player, parts)
			if #parts < 2 then
				local s = "Available commands are:"..NEWL
				for k,v in pairs(verbs) do
					-- If permitted(player, v)
					s = s .. k .. NEWL
				end
				return player:send(s)
			end
			
			local keyword = parts[2]
			
			local helpfile = helpfiles[keyword]
			
			if not helpfile then
				-- Log(player.name.." tried to find helpfile "..keyword)
				player:send("Helpfile '"..keyword.."' not found.")
				-- soundex it upppp!
				local s1 = soundex(keyword)
				
				-- Starting letter
				local l1 = s1:sub(1,1)
				-- Soundex number
				local n1 = s1:sub(2,4)
				
				local potential = {}
				
				for k,v in pairs(helpfiles) do
					local s2 = soundex(k)
					local l2 = s2:sub(1,1)
					local n2 = s2:sub(2,4)
					
					-- If the words start with the same letter
					if l1 == l2 then
						dif = math.abs(n1 - n2)
						if dif <= 5 then
							table.insert(potential, k)
						end
					end
				end
				
				
				if #potential == 1 then
					player:send("Showing helpfile for "..colour("%{yellow}"..potential[1]))
					helpfile = helpfiles[potential[1]]
				elseif #potential > 1 then
					local s = "Did you mean"
					for i,v in ipairs(potential) do
						s = s.." "..colour("%{yellow}"..v)..(i == #potential and "?" or ",")
					end
					
					player:send(s)
				end
			end
			
			
			if helpfile then
				player:send(player:sub(helpfile))
			end
		end,
		aliases = {"?"}
	},
	create = {
		f = function(player, parts, data)
			if #parts < 2 then
				return {"error", "Please supply a type to create!"}
			end
			
			local t = parts[2]
			
			if not contains({"object","room","player"}, t) then return player:send("Invalid type '"..t.."'") end
			player._editing_obj = types[t].new({})
			player._editing_obj._type = t
			player:setMenu(unpack(menus.obj_name))
		end
	},
	attr_type = {
		f = function(player, parts, data)
			local obj
			if parts[2] == "@here" then
				obj = player.room
			else
				obj = player.room:search(parts[2])
			end
			local t, k = resolve(obj, parts[3])
			player:send(type(t[k]))
		end
	},
	edit = {
		f = function(player, parts)
			if #parts < 2 then
				return {"error", "Please supply a type to edit!"}
			elseif #parts < 3 then
				return {"error", "Please supply an identifier to use"}
			end
			
			local t = parts[2]
			local list = _G[t.."s"]
			player._editing_obj = list[parts[3]]
			if not player._editing_obj then
				player:send(parts[3].." not found, creating it...")
				player._editing_obj = class.new({identifier = parts[3]})
			end
			
			player:setState "edit"
		end
	}
}

for k,v in pairs(t) do
	v.aliases = v.aliases or {}
	
	table.insert(v.aliases, k)
	
	v.name = k
end

return t