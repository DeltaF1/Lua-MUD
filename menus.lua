return {
	char_gender = {
	
		"What gender is your character? (m(ale)/f(emale)/n(eutral)/o(ther)): ",
		function(p,d,i)
			obj = p._editing_obj
			if i == 1 then obj.pronouns = PRONOUNS.male
			elseif i == 2 then obj.pronouns = PRONOUNS.female
			elseif i == 3 then obj.pronouns = PRONOUNS.neutral
			else
				p:setMenu(unpack(menus.char_gender_other))
				return
			end
			
			p:send("The ball of clay begins to stretch and deform, tendrils of material extruding outwards to form crude limbs.")
			p:setMenu(unpack(menus.char_desc))
		end, 
		{"m","f","n","o"}
	},
	char_gender_other = {
		"Enter your pronouns here, in the format i/myself/mine/my\
		e.g. she/herself/hers/her: ",
		function(p,d,i)
			obj = p._editing_obj
			parts = split(d, '/')
		  
      obj.pronouns = {}

			obj.pronouns.i=parts[1]
			obj.pronouns.myself=parts[2]
			obj.pronouns.mine=parts[3]
			obj.pronouns.my=parts[4]
			
			p:send("The ball of clay begins to stretch and deform, tendrils of material extruding outwards to form crude limbs.")
			p:setMenu(unpack(menus.char_desc))
		end,
		{"%w+/%w+/%w+/%w+$"}
	},
	
	char_desc = {
		"What does your character look like? ",
		function(p,d,i)
			obj = p._editing_obj
			
			obj.desc = d
			
			p:send("The golem begins to take on more humanistic characteristics, and facial features push themself out of the surface of its head.")
			p:setMenu(unpack(menus.char_name))
		end,
		{"."}
	},
	
	char_name = {
		"What is your character's name? ",
		function(p,d,i)
			-- Check for name already existing!
			
			-- ARCH: Allow multple characters to have the same name?
			-- TODO: implement name.# syntax for multiple objects w/ same name
			
			if contains({"quit"}, d) then
				p:send("(OOC) Invalid name!")
			end
			
			-- stmt = DB_CON:prepare()
			-- stmt:vbind_param_char(1,d)
			
      if p.characters[d] then		
				p:send("(OOC) That name is taken!")
				return
			end
			
			obj = p._editing_obj
			
			obj.name = d
			
			-- TODO: Edit flavor text
			p:send("The clay golem before you jerks, life filling its eyes as you utter its name. With a flash, you are looking through the eyes of the golem. As you look at your malformed limbs, the chaotic energies surround you, eating away, refining your features. The vortex swirls around you, and you feel yourself blink out of this hellscape, into an absolute darkness.")
			
			p:setMenu(unpack(menus.char_confirm))
		end,
		{"%w+$"}
	},
	
	char_confirm = {
		"Create character? (Y/N)",
		function(p,d,i)
			p:send("")
			if i == 1 then
				local obj = p._editing_obj
				
				obj.user = p.name
				print("obj.pronouns = "..tostring(obj.pronouns))
        obj.scripts = {
          "object",
          "player",
          "socket",
          "highlight",
        }
        obj:updateScripts()
        objects[db.store_object(obj)] = obj
        db.add_character(obj.user, obj)
			else
				p:send("Cancelling character creation...")
				
				p._editing_obj = nil
			end
			p:setState("login3")
		end,
		{"[Yy].*$", "[Nn].*$"}
	},
	
	--[[
	char_pass = {
		"(OOC) What password would you like to use? ",
		function(p,d,i)
			-- p.password = d
			-- Add entry to hash table
			
			
			-- TODO: Add password confirmation menu
			users[md5.sumhexa(d)] = p.name
			players[p.identifier] = p
			p.user = p.name
			
			world_save.update_player(p)
			
			p:send(IAC..WONT..ECHO)
			
			p:send("(OOC) You will now be asked to login with the credentials provided")
			p:setState("login1")
		end,
		{"."}
	}, --]]
	
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
			
			print("Creating object of type "..p._editing_obj._type)
			local obj = p._editing_obj
			local t = obj._type
			obj._type = nil
      if t == "room" then
        obj.scripts[#obj.scripts + 1] = "room"
      elseif t == "scenery" then
        obj.scenery = true
      end
      obj:updateScripts()
      objects[obj.identifier] = obj
      if t == "room" then
				print("Adding room")
				p:setMenu(unpack(menus.room_dir))
				return
			else
				print("Adding object")
				obj.room = p.room
        p.room:add(obj)
			end
      db.store_object(obj)
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
