local t = {}

--update_room = DB_CON:prepare("UPDATE rooms SET name=?,description=?,flags=?,exits=? WHERE identifier=?")

--update_player = DB_CON:prepare("UPDATE characters SET name=?,state=?,room=?,description=?,colour=?,cmdset=?,pronouns=?,hp=?,user=? WHERE identifier=?")

--update_object = DB_CON:prepare("UPDATE objects SET name=?,description=?,container=?,container_t=? WHERE identifier=?")

--get_pronoun, err = DB_CON:prepare("SELECT identifier FROM pronouns WHERE `i`=? AND `myself`=? AND `mine`=? AND `my`=?")

--if not get_pronoun then print(err) end

function t.update_player(player)
	
	--[[
	update_player:vbind_param_char(1, player.name)
	update_player:vbind_param_ulong(2, 0) -- TODO: Create an ordered array of keys of handlers.lua.
	update_player:vbind_param_ulong(3, player.room and player.room.identifier or nil)
	update_player:vbind_param_char(4, player.desc)
	update_player:vbind_param_ulong(5, 0) -- TODO: Colour table
	update_player:vbind_param_ulong(6, 0) -- TODO: Figure out cmdsets...
	
	get_pronoun:vbind_param_char(1,player.pronouns.i)
	get_pronoun:vbind_param_char(2,player.pronouns.myself)
	get_pronoun:vbind_param_char(3,player.pronouns.mine)
	get_pronoun:vbind_param_char(4,player.pronouns.my)
	]]--

	local cur = sql.execute("SELECT identifier FROM pronouns WHERE `i`=%q AND `myself`=%q AND `mine`=%q AND `my`=%q",
	player.pronouns.i, player.pronouns.myself, player.pronouns.mine, player.pronouns.my)
	
	local pronoun_identifier = tonumber(cur:fetch())
	
	cur:close()
	
	--[[
	if identifier then
		update_player:vbind_param_ulong(7, identifier)
	else
		update_player:vbind_param_ulong(7,1)
	end
	
	update_player:vbind_param_ulong(8, player.hp)
	update_player:vbind_param_char(9, player.user)
	
	update_player:vbind_param_ulong(10, player.identifier)
	]]--
	
	local room_identifier = player.room and player.room.identifier or 1
	
	-- print("type(room_identifier)",type(room_identifier))
	
	res, err = sql.execute("UPDATE characters SET name=%q,state=%i,room=%i,description=%q,colour=%i,cmdset=%i,pronouns=%i,hp=%i,user=%q WHERE identifier=%i",
		player.name, 0, room_identifier, player.desc, 0, 0, pronoun_identifier or 1, player.hp, player.user, player.identifier)

	if not res then
		error(err)
	end
end

function t.update_room(room)
	
	local exits = ""
	for direction, exit in pairs(room.exits) do
		if direction == "in" then direction = '"in"' end
		exits = exits..direction..'='..tostring(exit.identifier)..','
	end


	-- update_room:vbind_param_char(1,room.name)
	-- update_room:vbind_param_char(2,room.desc)
	-- update_room:vbind_param_ulong(3,tonumber(room.flags, 2))
	-- update_room:vbind_param_char(4,exits)


	-- update_room:vbind_param_ulong(5,room.identifier)

	-- res, err = update_room:execute()
	
	res, err = sql.execute("UPDATE rooms SET name=%q,description=%q,flags=%i,exits=%q WHERE identifier=%i", room.name, room.desc, tonumber(room.flags, 2), exits, room.identifier)

	if not res then
		error(err)
	end
	
	return room
end

function t.update_object(object)
	
	--[[
	update_object:vbind_param_char(1,object.name)
	update_object:vbind_param_char(2,object.desc)
	update_object:vbind_param_ulong(3,object.container.identifier)
	]]--
	
	--TODO: support players, objects holding other objects
	
	local container_t = 0
	
	if getmetatable(object.container) == Object then
		container_t = 2
	end
	
	--[[
	update_object:vbind_param_utinyint(4,container_t)
	
	update_object:vbind_param_ulong(5,object.identifier)
	--]]
	
	res, err = sql.execute("UPDATE objects SET name=%q,description=%q,container=%i,container_t=%i WHERE identifier=%i", object.name, object.desc, object.room.identifier, container_t, object.identifier)
	
	if not res then
		error(err)
	end
	
	return object
end

function t.save()
	print("Saving the world...")
	-- Store rooms
	for identifier, room in pairs(rooms) do
		t.update_room(room)
	end
	
	for identifier, player in pairs(players) do
		t.update_player(player)
	end
	
	for identifier, object in pairs(objects) do
		t.update_object(object)
	end
	
end

return t
