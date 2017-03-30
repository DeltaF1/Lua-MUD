return {
	char_gender = {
	
		"What gender is your character? (m(ale)/f(emale)/n(eutral)/o(ther)): ",
		function(p,d,i)
			if i == 1 then p.pronouns = pronouns.male
			elseif i == 2 then p.pronouns = pronouns.female
			elseif i == 3 then p.pronouns = pronouns.neutral
			else
				-- Add this later!
				p:send("Whoops, don't have a menu for this yet, defaulting to female!!")
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
			if players[d] then
				p:send("(OOC) That name is taken!")
				return
			end
			p.name = d
			p.identifier = d
			p:send("The clay golem before you jerks, life filling its eyes as you utter its name. With a flash, you are looking through the eyes of the golem. As you look at your malformed limbs, the chaotic energies surround you, eating away, refining your features. The vortex swirls around you, and you feel yourself blink out of this hellscape, into an absolute darkness.")
			p:setMenu(unpack(menus.char_pass))
		end,
		{"%w+"}
	},
	
	char_pass = {
		"(OOC) What password would you like to use? ",
		function(p,d,i)
			-- p.password = d
			-- Add entry to hash table
			users[md5.sumhexa(p.name..d)] = p.name
			players[p.identifier] = p
			-- p:send("With a lurch in the pit of your stomach, you feel yourself materialize.")
			-- send back to login1?
			p:send("(OOC) You will now be asked to login with the credentials provided")
			p:setState("login1")
		end,
		{"."}
	},
	
	obj_name = {
		"What is the name of the object? ",
		function(p,d,i)
			p._editing_obj.name = d
			p:setMenu(unpack(menus.obj_desc))
		end,
		{"."}
	},
	
	obj_desc = {
		"What is the description of the object? ",
		function(p,d,i)
			p._editing_obj.desc = d
			
			p:setMenu(unpack(menus.obj_ident))
		end,
		{"."}
	},
	
	obj_ident = {
		"Set an identifier for this object (leave blank to generate one) ",
		function(p,d,i)
			if #d > 0 then
				p._editing_obj.identifier = d
			end
			
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
				table.insert(p.room.objects, p._editing_obj)
			else
				print("Adding player")
				-- players[p._editing_obj.identifier(or maybe p._editing_obj.name)] = p._editing_obj
				table.insert(p.room.players, p._editing_obj)
			end
			p._editing_obj = nil
			p:setState("chat")
		end,
		{"[%S]+"}
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