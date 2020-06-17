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

math.randomseed(os.time())

NEWL = "\r\n"
IAC  = "\255"
WILL = "\251"
WONT = "\252"
ECHO = "\001"
AYT  = "\246"

-- Convert line endings from unix to telnet
config.server_info.motd = config.server_info.motd:gsub("NEWL", NEWL)
config.server_info.motd = config.server_info.motd:gsub("([^\r])(\n)", "%1\r\n")

server = socket.bind("*", config.server_info.port)

local ip, port = server:getsockname()
server:settimeout(0)

print(string.format("Bound to port %i!", port))

Object = require "object"
ser = require "world_save".ser
makeDb = require "filesystem_store"
db = makeDb(config.db_info.dataDir)
backupDb = makeDb(config.db_info.backupDataDir)

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
  out="in",
  aft="fore",
  fore="aft",
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
  [{"back","backward","backwards"}]="aft",
  [{"forewards","foreward"}]="fore",
}

function vecadd(v1,v2)
  return {v1[1]+v2[1], v1[2]+v2[2]}
end

-- TODO: Add 3rd dimension

dirvecs = {
  north = {0,1},
  west = {-1,0},
  east = {1,0},
  south = {0,-1},
}

for _, ns in pairs{"north", "south"} do
  for _, ew in pairs{"east", "west"} do
    dirvecs[ns..ew] = vecadd(dirvecs[ns], dirvecs[ew])
  end
end

function bfs(target, starting)
  local open = {starting}
  local vecs = {[starting] = {0,0}}
  local seen = {}
  while #open > 0 do
    local room = table.remove(open, 1)
    seen[room] = true
    for dir, other in pairs(room.exits) do
      if not seen[other] then
        local vec = dirvecs[dir]
        if vec then
          vec = vecadd(vec, vecs[room]) 
          vecs[other] = vec
          if vec[1] == target[1] and vec[2] == target[2] then
            return other
          end
          table.insert(open, other)
        end
      end
    end
  end
end

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
    print(tostring(sock:getpeername()).." has connected")
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
      object:call("onTick")
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
        backupDb.reload(obj)
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
