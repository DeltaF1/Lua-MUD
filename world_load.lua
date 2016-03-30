local t = {}

--Door

--self.destination

--self.open
--	self.room.exits[self.dir] = self.destination

--self.close
--	self.room.exits[self.dir] = nil

function t.load()
	local rooms, objects, players = {}, {}, {}
	
	for dir,tbl in pairs{["rooms"]={rooms, Room}, ["objects"]={objects, Object}, ["players"]={players, Player}} do
		local filelist = files("world"..DIR_SEP..dir)
		
		for i,v in ipairs(filelist) do
			if v:find("%.bak") then
				table.remove(filelist, i)
			end
		end
		
		for i,filename in ipairs(filelist) do
			loadFileInto("world"..DIR_SEP..dir..DIR_SEP..filename, tbl[1], tbl[2])
		end
	end
	
	for _, tbl in ipairs{rooms, objects, players} do
		for i,v in pairs(tbl) do
			
			if v.exits then
				for k,e in pairs(v.exits) do
					-- Try and load rooms by identifier. e.g. t.exits = { north = "some_identifier" }; t.exits["north"] = rooms["some_identifier"]
					local room = rooms[e]
					if not room then error("Room identifier not found: "..e) end
					
					v.exits[k] = room
				end
			end
			if v.objects then
				print("Loading objects into "..v.identifier)
				for j,o in ipairs(v.objects) do
					local object = objects[o]
					assert(object, "Object identifier not found: "..o)
					v.objects[j] = object
				end
			end
			if v.room then
				local room = rooms[v.room]
				assert(room, "Room identifier not found: "..v.room)
				v.room = room
			end
		end
	end

	--[[
	for k,v in pairs(objects) do 
		print(ser(v))
	end
	
	for k,v in pairs(rooms) do
		print(ser(v))
	end
	--]]
	return rooms, objects, players
end

function t.load_rooms()
	local rooms = {}
	local roomfiles = files("world"..DIR_SEP.."rooms")
	
	for i,v in ipairs(roomfiles) do
		if v:find("%.bak") then
			table.remove(roomfiles, i)
		end
	end
	
	-- For every file in the /rooms subdirectory
	for i, v in ipairs(roomfiles) do
		local filename = v
		
		local G = {}
		
		-- Load the file into a function
		local path = "world"..DIR_SEP.."rooms"..DIR_SEP..v
		print("Getting file at path "..path)
		local f = loadfile(path)
		
		-- Set the environment of the function, so that every global function is saved into the 'G' table
		setfenv(f, G)
		f()
		
		-- For every global variable created in the room file
		for k,room in pairs(G) do
			-- If there is already a room with that identifier
			if rooms[k] then
				error("Room identifier conflict: "..k)
			end
			
			-- Add the room to the rooms table
			rooms[k] = room
			
			-- Store the room's identifier and filename for later reserialization
			room.identifier = k
			room.filename = filename
			
			room = Room.new(room)
			
			for _,object in ipairs(room.objects) do
				-- set equal to objects[object]
				Object.new(object)
			end
			
			for key,val in pairs(room) do
				if key:match("do_") then
					print("Loading function!")
					room[key.."_str"] = val
					
					print("val = "..val)
					local f = loadstring(val)
					room[key] = f()
					
					print("type("..key..") = "..type(room[key]))
				elseif type(val) == "string" then
					-- print("Checking string '"..key.."' for \\NEWL")
					room[key] = val:gsub("\\NEWL", function()
						-- print("subbing newl")
						return NEWL
					end)
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

-- Rehashing of above function, to load into objects/rooms/players
function loadFileInto(filename, tbl, class)	
	print("loading file "..filename)
	local func = loadfile(filename)
	local G = {}
	
	setfenv(func, G)
	func()
	
	for k, object in pairs(G) do
		if tbl[k] then error("Identifier conflict: "..k,2) end
		
		tbl[k] = object
		
		object.identifier = k
		object.filename = filename:match(DIR_SEP.."([^"..DIR_SEP.."]+%..+)$")
		
		class.new(object)
		
		for key,val in pairs(object) do
			if key:match("do_") then
				print("Loading function!")
				object[key.."_str"] = val:gsub("\\NEWL", NEWL)
				
				print("val = "..val)
				local f = loadstring(val)
				object[key] = f()
				
				
			elseif type(val) == "string" then
				-- print("Checking string '"..key.."' for \\NEWL")
				object[key] = val:gsub("\\NEWL", NEWL)
			end
		end
	end
	
end

--[[
	-- For every object, replace identifiers with 
	for key,val in pairs(object) do
			if key == "exits" then
				for key2,v in pairs(val) do
					val[key2] = rooms[v]
				end
			elseif key == "objects" then
				for key2,v in pairs(val) do
					val[key2] = objects[v]
				end
			elseif key == "room" then
				object[key] = rooms[val]
			end
		end
]]

return t