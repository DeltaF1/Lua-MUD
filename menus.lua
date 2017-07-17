return {
	char_gender = {
	
		"What gender is your character? (m(ale)/f(emale)/n(eutral)/o(ther)): ",
		function(p,d,i)
			if i == 1 then p.pronouns = PRONOUNS.male
			elseif i == 2 then p.pronouns = PRONOUNS.female
			elseif i == 3 then p.pronouns = PRONOUNS.neutral
			else
				-- Add this later!
				p:send("Whoops, this feature hasn't been added yet, please choose one of the other options!")
				return
			end
			--TODO: Add some fluff
			p:send("The ball of clay begins to stretch and deform, tendrils of material extruding outwards to form crude limbs.")
			p:setMenu(unpack(menus.char_desc))
		end, 
		{"m","f","n","o"}
	},
	
	char_desc = {
		"What does your character look like?",
		function(p,d,i)
			p.desc = d
			-- TODO: Add some fluff
			p:send("The golem begins to take on more humanistic characteristics, and facial features push themself out of the surface of its head.")
			p:setMenu(unpack(menus.char_name))
		end,
		{"."}
	},
	
	char_name = {
		"What is your character's name? ",
		function(p,d,i)
			-- Check for name already existing!
			
			-- ARCH: Allow multple users to have the same name?
			-- TODO: implement name.# syntax for multiple objects w/ same name
			
			stmt = DB_CON:prepare("SELECT identifier FROM characters WHERE name=?")
			stmt:vbind_param_char(1,d)
			
			cur = stmt:execute()
			
			if cur:fetch() then
				p:send("(OOC) That name is taken!")
				return
			end
			p.name = d
			
			p:send("The clay golem before you jerks, life filling its eyes as you utter its name. With a flash, you are looking through the eyes of the golem. As you look at your malformed limbs, the chaotic energies surround you, eating away, refining your features. The vortex swirls around you, and you feel yourself blink out of this hellscape, into an absolute darkness.")
			p:send(IAC..WILL..ECHO)
			p:setMenu(unpack(menus.char_pass))
		end,
		{"%w+$"}
	},
	
	char_pass = {
		"(OOC) What password would you like to use? ",
		function(p,d,i)
			-- p.password = d
			-- Add entry to hash table
			
			-- TODO: Abstract login / user retrieval to a separate library, and remove password association with character
			-- TODO: Add password confirmation menu
			-- TODO: Remove user and Character association, allow single users to have multiple characters.
			users[md5.sumhexa(p.name..d)] = p.name
			players[p.identifier] = p
			p.user = p.name -- TODO: Change this to delink users and players
			print("[char_pass] p.identifier = "..tostring(p.identifier))
			world_save.update_player(p)
			
			p:send(IAC..WONT..ECHO)
			
			p:send("(OOC) You will now be asked to login with the credentials provided")
			p:setState("login1")
		end,
		{"."}
	},
	
	obj_name = {
		"What is the name of the object? ",
		function(p,d,i)
			p._editing_obj:setName(d)
			p:setMenu(unpack(menus.obj_desc))
		end,
		{"."}
	},
	
	obj_desc = {
		"What is the description of the object? ",
		function(p,d,i)
			p._editing_obj.desc = d
			
			print("Creating object of type "..p._editing_obj._type)
			local t = p._editing_obj._type
			p._editing_obj._type = nil
			if t == "room" then
				print("Adding room")
				rooms[p._editing_obj.identifier] = p._editing_obj
				p:setMenu(unpack(menus.room_dir))
				return
			elseif t == "object" then
				-- objects[p._editing_obj.identifier] = p._editing_obj
				print("Adding object")
				objects[p._editing_obj.identifier] = p._editing_obj
				table.insert(p.room.objects, p._editing_obj)
			else
				print("Adding character")
				-- players[p._editing_obj.identifier(or maybe p._editing_obj.name)] = p._editing_obj
				players[p._editing_obj.identifier] = p._editing_obj
				table.insert(p.room.players, p._editing_obj)
			end
			p._editing_obj = nil
			p:setState("chat")
		end,
		{"."}
	},
	
	room_dir = {
		"What exit should the room be placed at? ",
		function(p,d,i)
			p.room.exits[d] = p._editing_obj
			local oppdir = oppdirs[d]
			if oppdir then
				p._editing_obj.exits[oppdir] = p.room
			end
			p._editing_obj = nil
			p:setState("chat")
		end,
		{"."}
	}
}