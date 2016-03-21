socket = require "socket"
config = require "config"
md5 = require "md5"
colour = require "ansicolors"
require "utils"

math.randomseed(os.time())

NEWL = "\r\n"

server = socket.bind("*", config.port)

local ip, port = server:getsockname()
server:settimeout(0)

print("use telnet localhost "..port.." to connect!")

require "room"
require "player"
world_load = require "world_load"
world_save = require "world_save"

soundex = require "soundex"

rooms = world_load.load_rooms()

clients = {}
players = {}

contains = function (t, i)
	for j,v in ipairs(t) do
		if v == i then return true end
	end
	return false
end

tremove = function(t, i)
	for j = #t, 1, -1 do
		if t[j] == i then table.remove(t, j) end
	end
	return t
end

function broadcast(s)

	print("Broadcasting")
	print("Wher is backup? D:")
	for _,v in pairs(players) do
		if v.state == "chat" then
			v.sock:send(s..NEWL)
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
}

handlers = require "handlers"
verbs = require "verbs"


function main()
	local sock = server:accept()
	
	if sock then 
		--DEBUG REMOVE
		local s = colour("%{green}Welcome to the text-chat-test-server-o-matic-9000"..NEWL.."Please enter your username: ")
		sock:send(s)
		print(s)
		sock:settimeout(1)
		print(tostring(sock).." has connected")
		local player = {["sock"]=sock, state="login1"} --send = function() add_to_queue (msg..NEWL) end
		player = Player.new(player)
		players[sock] = player
		table.insert(clients, sock)
	end
	
	local ready = socket.select(clients, nil, 0.5)
	
	for i,sock in ipairs(ready) do
		local v = players[sock]
		local data, err = v.sock:receive()
		if data then
			
			print("Got Data from ("..tostring(v.name or v.sock)..") : "..data.." of length "..#data)
			--set state for login1, login2 etc. to get user/password
			--maybe extend for in-combat, selecting options, etc.?
			--   i.e Are you sure? (Y/n) (v.state="confirm")
			local handler = handlers[v.state]
			
			if handler then
				handler.f(v, data)
				-- state may have changed
				v:sendraw(handlers[v.state].prompt)
			end
		else
			--print(err)
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
	curTime = socket.gettime()
	DT = curTime - prevTime
	
	TIME = TIME + DT
	prevTime = curTime
	status, err = pcall(main)
	if not status then

		if string.match(err, "interrupted!") then
			print("Stopping program normally, just a Ctrl-C")
		elseif err:find("STOP COMMAND") then
			print("Stopping program normally, just a STOP command")
		else
			print("The program has halted in the middle of something, the world may be corrupted! Error: "..err)
		end
				
		--save the world!
		
		--on player quit, save the player's data
		--	so, we only need to deal with currently connected players
		
		--also, save room/items
		--	serialize, keep do_xxx_str
		
		world_save.save_rooms(rooms)
		
		break
	end
	--if math.floor(TIME) % 10 == 0 then print("Time: "..TIME) end
end