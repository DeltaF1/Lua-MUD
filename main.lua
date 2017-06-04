socket = require "socket"
config = require "config"
md5 = require "md5"
colour = require "ansicolors"
require "utils"

math.randomseed(os.time())

NEWL = "\r\n"
IAC  = "\255"
WILL = "\251"
WONT = "\252"
ECHO = "\001"

server = socket.bind("*", config.port)

local ip, port = server:getsockname()
server:settimeout(0)

print("use telnet localhost "..port.." to connect!")

require "room"
require "mobile"
require "player"
require "object"
world_load = require "world_load"
world_save = require "world_save"

soundex = require "soundex"

rooms, objects, players = world_load.load()

types = {room = Room, player = Player, object = Object}

users = require "users"

clients = {}

helpfiles = {}

function loadHelpFiles()
	for _,v in ipairs(files("helpfiles")) do
		local f = io.open("helpfiles"..DIR_SEP..v)
		local key = f:read("*line")
		local content = f:read("*all"):gsub("\n", NEWL)
		
		-- preprocess, add colour codes?
		
		helpfiles[key] = content
	end
end
loadHelpFiles()

function broadcast(s)

	print("Broadcasting")
	for _,v in pairs(clients) do
		if v.state == "chat" then
			v:send(s)
		end
	end
end

oppdirs = {
	north="south",
	south="north",
	east="west",
	west="east",
	southeast="northwest",
	northwest="southeast",
	southwest="northeast",
	northeast="southwest",
	up="down",
	down="up",
	["in"]="out",
	out="in"
}

dirs = {
	[{"north", "n"}]="north",
	[{"south", "s"}]="south",
	[{"east", "e"}]="east",
	[{"west", "w"}]="west",
	[{"up","u"}]="up",
	[{"down", "d"}]="down",
	[{"southeast", "se"}]="southeast",
	[{"southwest", "sw"}]="southwest",
	[{"northeast", "ne"}]="northeast",
	[{"northwest", "nw"}]="northwest",
	[{"in"}]="in",
	[{"out"}]="out",
}

handlers = require "handlers"
verbs = require "verbs"
cmdsets = require "commandSets"
menus = require "menus"

updateHandlers = {}

function Update(dt)
	for i = 1,#updateHandlers do
		local handler = updateHandlers[i]
		if type(handler) == "table" then
			handler:update(dt)
		elseif type(handler) == "function" then
			handler(dt)
		end
	end
end

function main(dt)
	local status, err = pcall(function()
	local sock = server:accept()
	
	if sock then 
		--DEBUG REMOVE
		--sock:send(WILL)
		--sock:send(ECHO)
		local s = colour(config.motd..NEWL..handlers.login1.prompt)
		sock:send(s)
		print(s)
		sock:settimeout(1)
		print(tostring(sock).." has connected")
		local player = {["sock"]=sock, state="login1"} --send = function() add_to_queue (msg..NEWL) end
		player = Player:new(player)
		clients[sock] = player
	end
	end)
	
	if not status then
		error("There was an error trying to accept a new connection: "..NEWL..err)
	end
	
	Update(dt)
	
	local ready = socket.select(keys(clients), nil, 0.01)
	
	for i,sock in ipairs(ready) do
		local v = clients[sock]
		local data, err = v.sock:receive()
		if data then
			
			--print("Got Data from ("..tostring(v.name or v.sock)..") : "..data.." of length "..#data)
			
			data = stripControlChars(data)
			local handler = handlers[v.state]
			
			if handler then
				handler.f(v, data)
				-- state may have changed
				v:sendraw(v.prompt or handlers[v.state].prompt)
			end
		else
			if err == "closed" then
				verbs.quit.f(v)
			end
		end
	end
	return true
end

TIME = 0
DT = 0
prevTime = os.time()

while true do
	-- Why are we using socket.gettime in one place and os.time in another...
	curTime = socket.gettime()
	DT = curTime - prevTime
	
	TIME = TIME + DT
	prevTime = curTime
	status, err = pcall(main, DT)
	if not status then

		if string.match(err, "interrupted!") then
			print("Stopping program normally, just a Ctrl-C")
		elseif err:find("STOP COMMAND") then
			print("Stopping program normally, just a STOP command")
		else
			print("The program has halted in the middle of something, the world may be corrupted! Error: "..NEWL..err)
		end
				
		--save the world!
		
		--on player quit, save the player's data
		--	so, we only need to deal with currently connected players
		
		--also, save room/items
		--	serialize, keep do_xxx_str
		
		world_save.save()
		
		break
	end
	--if math.floor(TIME) % 10 == 0 then print("Time: "..TIME) end
end