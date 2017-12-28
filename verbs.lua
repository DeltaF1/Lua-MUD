local t = {
	who={
		f = function(player, parts)
			local s = "Online:"..NEWL
			for i,v in pairs(players) do
				if v.state == "chat" then
					s = s..v.user..NEWL
				end
			end
			player:send(s, "")
		end
	},
	quit = {
		f = function(player, parts)
			player.sock:send("Goodbye!"..NEWL)
			player.sock:close()
			print(tostring(player.user or player.name or player.sock).." has disconnected")
			clients[player.sock] = nil
			
			if player.state == "chat" then
				player.room:broadcast(player.name.." vanishes in a puff of smoke. The scent of cinnamon lingers in the air", player)
			end
			if player.room then
				tremove(player.room.players, player)
			end
			world_save.update_player(player)
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
			local dir = (parts[1]=="go" or parts[1]=="walk") and parts[2] or parts[1]
			local ndir
			for k,v in pairs(dirs) do
				if contains(k, dir) then
					ndir = v
					break
				end
			end
			
			if not ndir then
				ndir = player.room.exits[dir] and dir
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
			
			player.room:broadcast(player.name..' says "'..msg..'"', player)
		end,
		aliases = {
			"say"
		}
	},
	pose = {	
		f = function(player, parts, data)
			
			
			local msg = ""
			if not parts[1]:find("^%..+") then
				if #parts < 2 then
					return {"error", "Please supply a phrase to pose"}
				end
				msg = data:match("[^ ]+ (.+)")
			else
				msg = data
			end

			msg = msg
			
			msg = player.name.." "..msg
			
			for i,p in ipairs(player.room.players) do
				local newmsg = msg:gsub("%.(%a+)", function(v)
					-- for verb in gmatch(%.%S+) do verb..s or verb[conjugations]
				
					-- ShinMojo @ sindome.org ([^aeiouy]|qu)y$"-> "$1ies" and (x|ch|ss|sh)$ -> "$1es"
					-- Adds an s. e.g. .walk briskly becomes "walks briskly"
					-- v = v:gsub(ShinMojo pattern (need RegEx or custom pattern builder))
					
					-- If pronouns.neutral and last used pronoun ~= nil
					if p == player then return v end -- secondPersonOfVerb(v)
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
					if p == player then return PRONOUNS.second[v:lower()] end
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
			"/me"
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
			
			obj = player.room:search(name)
			
			if not obj then
				return "object not found!"
			end
			
			
			
			local key = parts[3]
			local obj, k = resolve(obj, key)
			if not obj then return player:send("Invalid keypath "..key) end
			print("Setting "..(obj.name or tostring(obj)).." at "..k)
			
			-- e.g. set hobo pronouns.myself "xirself"
			
			local payload_parts = {}
			for i = 4,#parts do
				payload_parts[#payload_parts+1] = parts[i]
			end
			
			local payload = table.concat(payload_parts, " ")
			
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
			
			local name = parts[2]
			
			local obj = player.room:search(name)
			
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
				for k,v in pairs(player.cmdset) do
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
					-- TODO: add tags to helpfiles, soundex those as well
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
				player:send(player:sub(helpfile)..NEWL)
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
			player._editing_obj = types[t]:new({})
			player._editing_obj._type = t
			player:setMenu(unpack(menus.obj_name))
		end
	},
	attr_type = {
		f = function(player, parts, data)
			local obj
			if not parts[2] then
				return player:send("Missing object")
			end
			if not parts[3] then
				return player:send("Missing path")
			end
			
			obj = player.room:search(parts[2])
			
			if not obj then
				return player:send("Couldn't find object")
			end
			
			local t, k = resolve(obj, parts[3])
			player:send(type(t[k]))
		end
	},
	edit = {
		f = function(player, parts, data)
			if player.room:search(parts[2]) then
				player._editing_obj = player.room:search(parts[2])
				player:setState "edit"
				return
			elseif #parts < 2 then
				return {"error", "Please supply a type to edit, or the name of a visible object!"}
			elseif #parts < 3 then
				return {"error", "Please supply an identifier to use"}
			end
			
			local t = parts[2]
			local class = types[t]
			
			if not class then
				return player:send("Invalid type!")
			end
			
			local list = _G[t.."s"]
			
			player._editing_obj = list[tonumber(parts[3])]
			if not player._editing_obj then
				player:send(t.." #"..parts[3].." not found, creating new "..t)
				player._editing_obj = class:new()
				list[player._editing_obj.identifier] = player._editing_obj
				player:send(string.format("New %s created with identifier #%i", t, player._editing_obj.identifier))
			end
			
			player:setState "edit"
		end
	},
	attack = {
		f = function(player, parts)
			local target = player.room:search(parts[2])
			
			if target then
				-- check if it's a mobile?
				if target.hp then
					if player.room.flags:sub(1,1) == "1" then
						player:send("Cannot start a fight here!")
					elseif target.arena then
						target.arena:add(player)
					else
						local arena = Arena:new()
						arena:add(player)
						arena:add(target)
						target:setState("combat")
					end
					player:setState("combat")
				else
					player:send("That target is not combattable!")
				end
			elseif parts[2] then
				player:send(parts[2].." not found!")
			else
				return {"error", "Please provide a target to attack!"}
			end
		end
	},
	exits = {
		f = function(player, parts)
			player:send("The available exits are:")
			
			for k,v in pairs(player.room.exits) do
				player:send(k)
			end
		end
	},
	ident = {
		f = function(player, parts)
			if not parts[2] then
				obj = player.room
			else
				obj = player.room:search(parts[2])
			end
			
			if obj then
				player:send(("Identifier of %q is %i"):format(obj.name, obj.identifier))
			else
				player:send("Object not found!")
			end
		end
	},
	manual = {
		f = function(player, parts)
			player:send(
[[INTRODUCTION

To interact with the world, type commands into the prompt in the following format

>command argument1 argument2 argument3 ...

e.g.

>walk north

Type 'help' to show a list of available commands, and type 'help command' to read a more detailed helpfile.
]])
		end
	}
}

for k,v in pairs(t) do
	v.aliases = v.aliases or {}
	
	table.insert(v.aliases, k)
	
	v.name = k
end

return t
