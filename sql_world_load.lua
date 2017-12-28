local t = {}

local colours = {"red","green","yellow","blue","magenta","cyan"}

function t.load()
	local rooms, objects, players = {}, {}, {}

	
	-- Cleanup leftover calls to sql.get_identifier
	for i, table in ipairs({"characters", "rooms", "objects"}) do
		res, err = DB_CON:execute(string.format("DELETE FROM %s WHERE name='__new'", table))
	end
	DB_CON:execute("DELETE FROM pronouns WHERE i='__new'")
	
	PRONOUNS = {}
	
	for identifier, i, myself, mine, my in sql.rows(DB_CON, "SELECT * FROM pronouns") do
		PRONOUNS[identifier] = {
			i=i,
			myself=myself,
			mine=mine,
			my=my,
			}
	end
	
	PRONOUNS.male = PRONOUNS[1]
	PRONOUNS.female = PRONOUNS[2]
	PRONOUNS.neutral = PRONOUNS[3]
	PRONOUNS.second = PRONOUNS[4]
	
	for identifier, desc, name, flags, exits in sql.rows(DB_CON, 'SELECT * FROM rooms') do
		
		room = {
			name = name,
			desc = desc,
			identifier = identifier,
			flags = num2bin(flags),
			}
		-- need to replace in with "in"
		exits = loadstring("return {"..exits.."}")()
		room.exits = exits
		room = Room:new(room)
		
		rooms[identifier] = room
		
	end
	
	for identifier, room in pairs(rooms) do
		for direction, exit in pairs(room.exits) do
			room.exits[direction] = rooms[exit] or nil
		end
	end
	
	rooms.starting = rooms[1]
	
	for identifier, user, name, state, room, desc, colour, cmdset, pronouns, hp in sql.rows(DB_CON, "SELECT * FROM characters") do
		character = {
			identifier = identifier,
			name = name,
			state = state,
			desc = desc,
			-- colour = colour,
			hp = hp,
			user = user,
			}
		character.room = rooms[room]
		
		character.colour = colours[math.random(#colours)]
		
		if character.user == "__NPC" then
			table.insert(character.room.players, character)	
			character.state = "chat"
		end
		character.pronouns = PRONOUNS[pronouns]
		
		
		player = Player:new(character)
		
		players[player.identifier] = player
	end
	
	for identifier, name, desc, container, container_t in sql.rows(DB_CON, "SELECT * FROM objects") do
		local object = {
			identifier = identifier,
			name = name,
			desc = desc
			}
		
		object = Object:new(object)
		
		
		-- TODO: Deal with players holding objects, objects holding other objects
		if container_t ==  0 then
			local room = rooms[container]
			
			table.insert(room.objects, object)
			
			object.container = room
		end
	end
	
	for identifier, obj_type, key, body in sql.rows(DB_CON, "SELECT * FROM user_scripts") do
		local tbl
		if obj_type == 0 then
			tbl = rooms
		elseif obj_type == 1 then
			tbl = players
		else
			tbl = objects
		end
		local obj = tbl[identifier]
		if not obj then
			print(("Orphaned user script found for identifier %d, table %q"):format(identifier, ({"rooms", "players", "objects"})[obj_type+1]))
		else
			-- SUUUUPER SECURE
			
			local chunk = loadstring(body)
			
			setfenv(chunk, {})
			
			local f = chunk()
			
			-- TODO: Create a safe env table
			-- TODO: Update to 5.3 environments
			setfenv(f, _G)
			
			obj[key] = f
		end
		
	end
	
	return rooms, objects, players
end

return t