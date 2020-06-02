socket = require "socket"

config = require "config"
md5 = require "md5"
colour = require "ansicolors"
require "utils"

do
	local logfile
	--TODO implement a non-positional arg system i.e. --logfile=/var/log/luamud.log
	if arg[1] then
		logfile = arg[1]
	else
		logfile = "luamud.log"
	end
	
	LOG_F, err = io.open(logfile, "a")
	
	if not LOG_F then
		error(err)
	end
	
	_print = print
	print = function(...)
		_print(...)
		
		local arg = {...}
		
		for i = 1,#arg do
			arg[i] = tostring(arg[i])
		end
		
		local timestamp = os.date("[%d-%b-%Y %H:%M:%S]")
		
		LOG_F:write(timestamp .." ".. (unpack(arg) or "nil") .. "\r\n")
		LOG_F:flush()
	end
end

LOG_F:write(string.rep("=", 80).."\r\n")

print("Starting up server...")

-- Convert line endings from unix to telnet
config.server_info.motd = config.server_info.motd:gsub("([^\r])(\n)", "%1\r\n")

math.randomseed(os.time())

NEWL = "\r\n"
IAC  = "\255"
WILL = "\251"
WONT = "\252"
ECHO = "\001"
AYT  = "\246"

server = socket.bind("*", config.server_info.port)

local ip, port = server:getsockname()
server:settimeout(0)

print(string.format("Bound to port %i!", port))

Object = require "object"
ser = require "world_save".ser
makeDb = require "filesystem_store"
db = makeDb("data")
backupDb = makeDb("data.bak")

soundex = require "soundex"

objects = {}

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

short_dirs = {
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

function dirFromShort(dir)
  for shortnames,longname in pairs(short_dirs) do
    if contains(shortnames, dir) then
      return longname
    end
	end
  return dir
end

PRONOUNS = {
	male = {
		i = "he",
		my = "his",
		mine = "his",
		myself = "himself"
	},
	female = {
		i = "she",
		my = "her",
		mine = "hers",
		myself = "herself"
	},
	neutral = {
		i = "they",
		my = "their",
		mine = "theirs",
		myself = "themself"
	},
	second = {
		i = "you",
		my = "your",
		mine = "yours",
		myself = "yourself"
	}
}

handlers = require "handlers"
verbs = require "verbs"
cmdsets = require "commandSets"
menus = require "menus"

function main()
	local dt = DT
	local status, err = pcall(function()
	local sock = server:accept()
	
	if sock then 
		sock:send(IAC..AYT)
		sock:send(IAC..WONT..ECHO)
		local s = colour(config.server_info.motd..NEWL..handlers.login1.prompt)
		sock:send(s)
		
		sock:settimeout(1)
		print(tostring(sock).." has connected")
		local user = {__sock=sock, state="login1"}
    user.scripts = {
      "object",
      "socket",
      "playerState",
      "highlight"
    }
		user.identifier = 0
		user = Object:new(user)
    user.name = nil
		user.user = nil
		clients[sock] = user
	end
	end)
	
	if not status then
		error("There was an error trying to accept a new connection: "..NEWL..err)
	end
	
	local ready = socket.select(keys(clients), nil, 0.01)
	
	for i,sock in ipairs(ready) do
		local v = clients[sock]
		local data, err = sock:receive()
		if data then
			
			--print("Got Data from ("..tostring(v.name or v.sock)..") : "..data.." of length "..#data)
			
			data = stripControlChars(data)
			local handler = handlers[v.state]
			
			if handler then
        for i, obj in pairs(objects) do
          backupDb.store_object(obj)
        end
        -- Run command
				handler.f(v, data)
				-- state may have changed
				v:send(v:getPrompt() or handlers[v.state].prompt, "")
			end
		else
			if err == "closed" then
				if not v.state:find("login") then
					verbs.quit.f(v)
				else
					clients[v.__sock] = nil
				end
			end
		end
	end
	-- Do game ticks
  
  for id, object in pairs(objects) do
		-- only tick objects that are not lazy loaded
    if not object.__id then
      local tick = object.onTick
      if tick then
    	  tick(object)
      end
    end
	end
	-- sleep
	socket.select(nil,nil,0.1)
	return true
end

TIME = 0
DT = 0
prevTime = socket.gettime()

err_handler = function(err) 
	if string.match(err, "interrupted!") then
		print("SIGINT received, stopping server")
    loop = false
	elseif err:find("STOP COMMAND") then
		print("STOP command received in-game, stopping server")
    loop = false
	else
		print("The server ran into a problem. The world may be corrupted, review the error before restarting. Error: "..NEWL..err)
		print(debug.traceback())
    for i, obj in pairs(objects) do
      if not obj.__id then
        local sock = obj:get__sock()
        backupDb.reload(obj)
        obj.__sock = sock
      end
    end
	end
end

loop = true
while loop do
	curTime = socket.gettime()
	DT = curTime - prevTime
	
	TIME = TIME + DT
	prevTime = curTime
	
	status, err = xpcall(main, err_handler)
end

for i, object in pairs(objects) do
  db.store_object(object)
end
print("Goodbye.")
LOG_F:close()
