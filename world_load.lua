local t = {}

function files(dir)
	local s = io.popen("dir "..dir.." /b /a-d"):read("*all")

	return split(s)
end

--Door

--self.destination

--self.open
--	self.room.exits[self.dir] = self.destination

--self.close
--	self.room.exits[self.dir] = nil



function t.load_rooms()
	local rooms = {}
	local roomfiles = files("rooms")
	
	for i,v in ipairs(roomfiles) do
		if v:find("%.bak") then
			table.remove(roomfiles, i)
		end
	end
	
	local env = getfenv()
	
	-- For every file in the /rooms subdirectory
	for i, v in ipairs(roomfiles) do
		local filename = v
		
		local G = {}
		
		-- Load the file into a function
		local f = loadfile("rooms\\"..v)
		
		-- Set the environment of the function, so that every global function is saved into the 'G' table
		setfenv(f, G)
		f()
		
		-- For every global variable created in the room file
		for k,v in pairs(G) do
			-- If there is already a room with that identifier
			if rooms[k] then
				error("Room identifier conflict: "..k)
			end
			
			-- Add the room to the rooms table
			rooms[k] = v
			
			-- Store the room's identifier and filename for later reserialization
			v.identifier = k
			v.filename = filename
			
			v = Room.new(v)
			
			for key,val in pairs(v) do
				if type(val) == "string" then
					v[key] = val:gsub("\\NEWL", NEWL)
				end
			end
			
			--parse room for do_xxx_str 
		end
	end
	
	-- For every room
	for i,v in pairs(rooms) do
		for k,e in pairs(v.exits) do
			-- Try and load rooms by identifier. e.g. t.exits = { north = "some_identifier" }; t.exits["north"] = rooms["some_identifier"]
			local room = rooms[e]
			if not room then error("Room identifier not found: "..e) end
			print("Turned identifier "..e.." into room: "..room.name)
			v.exits[k] = room
		end
	end
	
	return rooms
end

return t