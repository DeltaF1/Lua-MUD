local t = {}

function split(s, sep)
	local t = {}
	local sep = sep or " "
	for i in string.gmatch(s, "%S+") do print("adding part "..i);table.insert(t, i) end
	return t
end

function files(dir)
	print("Listing files in "..dir)
	local s = io.popen("dir "..dir.." /b /a-d"):read("*all")
	print("s = "..s)
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
	
	local env = getfenv()
	
	
	
	
	for i, v in ipairs(roomfiles) do
		local filename = v
		local G = {}
		print("file = "..v)
		--v = string.match(v, "%w+")
		print("v = "..v)
		
		
		local f = loadfile("rooms\\"..v)
		setfenv(f, G)
		f()
		
		for k,v in pairs(G) do
			print("Loading room of identifier "..k)
			if rooms[k] then
				error("Room identifier conflict: "..k)
			end
			
			rooms[k] = v
			v.identifier = k
			v.filename = filename
			
			for defk,def in pairs(Room.default()) do
				v[defk] = v[defk] or def
			end
			
			setmetatable(v, Room)
			
			print("Set metatable of "..k)
			
			--parse room for do_xxx_str 
		end
	end
	
	
	
	for i,v in pairs(rooms) do
		for k,e in pairs(v.exits) do
			local room = rooms[e]
			if not room then error("Room identifier not found: "..e) end
			print("Turned identifier "..e.." into room: "..room.name)
			v.exits[k] = room
		end
	end
	
	return rooms
end

return t