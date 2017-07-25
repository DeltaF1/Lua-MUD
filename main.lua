socket = require "socket"

config = require "config"
md5 = require "md5"
colour = require "ansicolors"
require "utils"

sql = require "sql"
odbc = require "odbc"

do
	local logfile
	--TODO implement a non-positional arg system i.e. --logfile=/var/log/luamud.log
	if arg[1] then
		logfile = arg[1]
	else
		logfile = "/var/log/luamud.log"
	end
	
	
	
	LOG_F, err = io.open(logfile, "a")
	
	if not LOG_F then
		error(err)
	end
	
	_print = print
	print = function(...)
		_print(...)
		
		local timestamp = os.date("[%d-%b-%Y %H:%M:%S]")
		
		LOG_F:write(timestamp .." ".. ... .. "\r\n")
		LOG_F:flush()
	end
end

LOG_F:write(string.rep("=", 80).."\r\n")

print("Starting up server...")

-- Convert line endings from unix to telnet
config.motd = config.motd:gsub("([^\r])(\n)", "%1\r\n")

sql_pass = config.sql_pass

if not sql_pass then
	io.write("Enter SQL password: ")	
	sql_pass = io.read("*l")
end

DB_CON, err = odbc.connect("lua_mud", config.sql_user, sql_pass)

if not DB_CON then
	print(err)
	error(err)
end

print("Connected to database!")

math.randomseed(os.time())

NEWL = "\r\n"
IAC  = "\255"
WILL = "\251"
WONT = "\252"
ECHO = "\001"
AYT  = "\246"

server = socket.bind("*", config.port)

local ip, port = server:getsockname()
server:settimeout(0)

print(string.format("Bound to port %i!", port))

require "room"
require "mobile"
require "player"
require "object"
world_load = require "sql_world_load"
world_save = require "sql_world_save"

-- To get ser
require "world_save"

soundex = require "soundex"

rooms, objects, players = world_load.load()

types = {room = Room, player = Player, object = Object}

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

	-- print("Broadcasting")
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

function main()
	local dt = DT
	local status, err = pcall(function()
	local sock = server:accept()
	
	if sock then 
		sock:send(IAC..AYT)
		sock:send(IAC..WONT..ECHO)
		local s = colour(config.motd..NEWL..handlers.login1.prompt)
		sock:send(s)
		
		sock:settimeout(1)
		print(tostring(sock).." has connected")
		local user = {["sock"]=sock, state="login1"} --send = function() add_to_queue (msg..NEWL) end
		user.identifier = 0
		user = Player:new(user)
		user.name = nil
		user.user = nil
		clients[sock] = user
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
				v:send(v.prompt or handlers[v.state].prompt, "")
			end
		else
			if err == "closed" then
				if not v.state:find("login") then
					verbs.quit.f(v)
				else
					clients[v.sock] = nil
				end
			end
		end
	end
	return true
end

TIME = 0
DT = 0
prevTime = socket.gettime()

err_handler = function(err) 
	if string.match(err, "interrupted!") then
		print("SIGINT received, stopping server")
	elseif err:find("STOP COMMAND") then
		print("STOP command received in-game, stopping server")
	else
		print("The server ran into a problem. The world may be corrupted, review the error before restarting. Error: "..NEWL..err)
		print(debug.traceback())
	end
end

while true do
	curTime = socket.gettime()
	DT = curTime - prevTime
	
	TIME = TIME + DT
	prevTime = curTime
	
	status, err = xpcall(main, err_handler)
	if not status then
		
		world_save.save()
		print("Goodbye.")
		LOG_F:close()
		break
	end
end
