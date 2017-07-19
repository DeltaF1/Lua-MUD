	-- ANSI colour names
	local colours = {"red","green","yellow","blue","magenta","cyan"}

	return {
		login1 = {
			f = function(user, data)
				-- Can't set user's name to a 0-length string
				if #data == 0 then
					return
				end

				-- If there are any non alphanumeric characters in the data
				if data:find("%W") then
					user.sock:send("Invalid name, name must only contain alphanumeric characters (a-z, A-Z, 0-9)")
					return
				end

				user.name = data


				user:setState "login2"


			end,
			prompt = colour("%{green}Please enter your username:")
		},
		login2 = {
			before = function(user) user:send(IAC..WILL..ECHO, "") end,
			f = function(user, data)

				stmt = DB_CON:prepare("SELECT password FROM users WHERE username=?")
				stmt:vbind_param_char(1, user.name)

				cur = stmt:execute()

				pass = cur:fetch()
				
				cur:close()
				-- Get hash of user.name..data..salt
			
				--ADD SALT

				--FOR THE LOVE OF GOD DON'T USE MD5
				hash = md5.sumhexa(data)

				if pass ~= hash then
					user:send("Incorrect password!")
					user:setState("login1")
					return
				end


				-- TODO: Keep a list of users connected separate from characters
				for k,v in pairs(clients) do
					if v ~= user and ((v.state:find("login3") and v.name == user.name) or (v.user and v.user == user.name)) then
						user:send("Error: Already logged in!")
						user:setState("login1")

						return
					end
				end



				user:setState "login3"
			end,
			after = function(user) user:sendRaw(IAC..WONT..ECHO) end,
			prompt = colour("%{red}Please enter your password: ")
		},
		login3 = {
			before = function(user)

				stmt = DB_CON:prepare("SELECT identifier FROM characters WHERE user=?")
				stmt:vbind_param_char(1, user.name)

				-- cur = stmt:execute()

				user.characters = {}

				for identifier in sql.rows(stmt) do
					player = players[identifier]
					user.characters[player.name] = player
				end

				user:send()
				for k,v in pairs(user.characters) do
					user:send(colour("%{yellow}"..k))	
				end	
			end,
			f = function(user, data)
				if data == "quit" then
					verbs.quit.f(user)
				end

				if data == "new" then
					user:send("You find yourself in a vortex of sound and colour, arcane energies swirling all around. Before you is a small pocket of calm, an orb of clay floating in the center.")
					user._editing_obj = Player:new()
					user:setMenu(unpack(menus.char_gender))
					return
				end

				player = user.characters[data]

				if not player then
					user:send("Invalid character name")	
					return
				end

				-- player.user = user
				player.sock = user.sock
				clients[user.sock] = player

				-- TODO: Move this to world_load
				if not player.cmdset then
					player.cmdset = cmdsets.Default
				end

				player.cmdset = CommandSet:new(player.cmdset)
				player.cmdset = player.cmdset:union(cmdsets.Default)

				if player.name == "Delta" then
					player.cmdset = player.cmdset:union(cmdsets.All)
				end

				--CommandSet:new(keys(verbs))
				-- Mainly for debugging, eventually colours will mean something. Maybe class/rank?
				player.colour = colours[math.random(#colours)]

				-- This should probably be adjustable for different spawnrooms or something
				player.room = player.room or rooms.starting
				-- We really need to setup an init function!

				table.insert(player.room.players, player)


				player:send(player.room:do_look(player))

				-- Announce the player entering the server
				player.room:broadcast("With a small crack "..player.name.." appears, along with a brisk wind", player)

				-- To make sure the prompt is properly updated
				user:setState "chat"
				player.state = "login3"
				player:setState "chat"
			end,
			prompt = "Select the character to play, type 'new' to make a new one: "
		},
		chat = {
			f = function(player, data)

				-- Don't do anything
				if #data == 0 then
					return
				end

				-- replace parts like "@here" or "@me" with names of objects
				data = data:gsub("@([^ ]*)", {me=player.name, here=player.room.name})


				-- Get parts of data. e.g. "Why is the rum always gone?" will become {"Why", "is", "the", "rum", "always", "gone?"}
				local parts = split(data)

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