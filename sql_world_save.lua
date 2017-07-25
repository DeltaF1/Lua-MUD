local t = {}

update_room = DB_CON:prepare("UPDATE rooms SET name=?,description=?,flags=?,exits=? WHERE identifier=?")

update_player = DB_CON:prepare("UPDATE characters SET name=?,state=?,room=?,description=?,colour=?,cmdset=?,pronouns=?,hp=?,user=? WHERE identifier=?")

get_pronoun, err = DB_CON:prepare("SELECT identifier FROM pronouns WHERE `i`=? AND `myself`=? AND `mine`=? AND `my`=?")

if not get_pronoun then print(err) end

function t.update_player(player)
	
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
	
	cur = get_pronoun:execute()
	
	identifier = cur:fetch()
	
	cur:close()
	
	if identifier then
		update_player:vbind_param_ulong(7, identifier)
	else
		update_player:vbind_param_ulong(7,1)
	end
	
	update_player:vbind_param_ulong(8, player.hp)
	update_player:vbind_param_char(9, player.user)
	
	update_player:vbind_param_ulong(10, player.identifier)

	res, err = update_player:execute()

	if not res then
		error(err)
	end
end

function t.update_room(room)
	
	exits = ""
	for direction, exit in pairs(room.exits) do
		if direction == "in" then direction = '"in"' end
		exits = exits..direction..'='..tostring(exit.identifier)..','
	end


	update_room:vbind_param_char(1,room.name)
	update_room:vbind_param_char(2,room.desc)
	update_room:vbind_param_ulong(3,tonumber(room.flags, 2))
	update_room:vbind_param_char(4,exits)


	update_room:vbind_param_ulong(5,room.identifier)

	res, err = update_room:execute()

	if not res then
		error(err)
	end
	
	return room
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
	
end

return t