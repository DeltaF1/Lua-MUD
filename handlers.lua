-- ANSI colour names
local colours = {"red","green","yellow","blue","magenta","cyan"}

return {
	login1 = {
		f = function(player, data)
			-- Can't set player's name to a 0-length string
			if #data == 0 then
				return
			end
			
			if data == "new" then
				player:send("(OOC: type 'cancel' to exit character creation)")
				player:send("You find yourself in a vortex of sound and colour, arcane energies swirling all around. Before you is a small pocket of calm, an orb of clay floating in the center.")
				player:setMenu(unpack(menus.char_gender))
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
			player:setState "login2"
			player:sendRaw(IAC..WILL..ECHO)
			
		end,
		prompt = colour("%{green}Please enter your username (type 'new' to create a new character):")
	},
	login2 = {
		f = function(player, data)
			-- Get hash of player.name..data..salt
			
			--ADD SALT
			
			--FOR THE LOVE OF GOD DON'T USE MD5
			hash = md5.sumhexa(player.name..data)
			if users[hash] ~= player.name then
				player:send("Incorrect password!")
				player:send(IAC..WONT..ECHO)
				player:setState("login1")
				return
			end
			
			
			
			for k,v in pairs(players[player.identifier]) do
				if not contains({"sock", "prompt"}, k) then
					player[k] = v
				end
			end
			
			players[player.identifier] = player
			
			-- TODO: Move this to world_load
			if not player.cmdset then
				player.cmdset = cmdsets.Default
			end
			
			player.cmdset = CommandSet:new(player.cmdset)
			player.cmdset = player.cmdset:union(cmdsets.Default)
			
			--CommandSet:new(keys(verbs))
			-- Mainly for debugging, eventually colours will mean something. Maybe class/rank?
			player.colour = colours[math.random(#colours)]
			
			-- This should probably be adjustable for different spawnrooms or something
			player.room = player.room or rooms.starting
			-- We really need to setup an init function!
			
			table.insert(player.room.players, player)
			
			-- Counts as a newline!
			player:send(IAC..WONT..ECHO)
			player:send(player.room:do_look(player))
			
			-- Announce the player entering the server
			player.room:broadcast("With a small crack "..player.name.." appears, along with a brisk wind", player)
		--if player.state == "login2" then
			--get password
			--get hash
			--load player data from file
			
			player:setState "chat"
			
		end,
		prompt = colour("%{red}Please enter your password: ")
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
			
			newData = ""
			for i, part in ipairs(parts) do
		
				if part:sub(1,1) == "@" then
					print("Got an @")
					if part == "@me" then
						print("replacing @me!")
						part = player.name
					elseif part == "@here" then
						part = player.room.name
					end
					print(part)
					parts[i] = part
				end
				
				newData = newData..part.." "
			end
			
			data = newData:sub(1,#newData-1)
			
			
			-- First word sent
			local cmd = parts[1]
			
			-- Declare verb and name of verb
			local verb
			local key
			
			if player.room.cmdset and player.room.cmdset:find(cmd) then
				verb = player.room.cmdset:find(cmd)
			else
				verb = player.cmdset:find(cmd)
			end
			
			if verb then
				print("Got verb!")
				key = verb.name
				-- Run the verb, passing in the player, split parts, and original data string
				--
				-- If the player is puppeting, send with the puppeted NPC as the player argument
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
		prompt = "> "
	},
	menu = {
		f = function(player, data)
			player.menu(player, data)
		end,
		prompt = "menu> "
	},
	edit = {
		f = function(player, data)
			local parts = split(data)
			local key = parts[1]
			local val = table.concat(parts, " ", 2)
			print("key = "..tostring(key).." val = "..tostring(val))
			if not key then return end
			if key == "quit" then
				player._editing_obj = nil
				player:setState "chat"
				return
			end
			
			-- TODO: = loadstring(val)
			player._editing_obj[key] = val
		end,
		prompt = "edit> "
	},
	
	combat = {
		f = function(player, data)
			parts = split(data)
			
			local arena = player.arena
			
			local verb = parts[1]
			if not parts[2] then
				return player:send("Please supply a target to attack!")
			end
			if verb == "attack" then -- hard coded D:
				local target = player.room:search(parts[2])
				if contains(arena.mobiles, target) then
					if player.ap > 3 then -- hard coded D:
						player.ap = player.ap - 3
						target:damage(1) -- hard coded D:
					end
				else
					player:send("Invalid target!")
				end
			elseif verb == "quit" then
				player:setState("chat")
			end
		end,
		prompt = "combat> "
	}
	
	
}