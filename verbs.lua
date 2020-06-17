local t = {
  who={
    f = function(player, parts)
      local s = "Online:"..NEWL
      for k,player in pairs(clients) do
        if not player.state:match("^login") then 
          if not player.user then
            print(ser(player))
          else
            s = s..player.user..NEWL
          end
        end
      end
      player:send(s, "")
    end
  },
  quit = {
    f = function(player, parts)
      player.__sock:send("Goodbye!"..NEWL)
      player.__sock:close()
      print(tostring(player.user or player.name or player.sock).." has disconnected")
      clients[player.__sock] = nil
      player.__loaded = false    
      if player.state == "chat" then
        player.room:broadcast(player.name.." vanishes in a puff of smoke. The scent of cinnamon lingers in the air", player)
      end
      if player:getRoom() then
        tremove(player.room.objects, player)
      end
      db.store_object(player)
    end,
    aliases = { "exit" }
  },
  look = {
    f = function(player, parts)
      local obj, name
      if #parts < 2 then
        obj = player.room
      else
        name = table.concat(parts, " ", 2)
        obj = player.room:search(name)[1]
      end
      if not obj then return player:send("Could not find "..name) end
      player:send(obj:getDesc(player))
    end,
    aliases = {
      "ex", "x", "examine"
    }
  },
  go = {
    f = function(player, parts)
      local dir = (parts[1]=="go" or parts[1]=="walk") and parts[2] or parts[1]
      dir = dirFromShort(dir)      
      
      if player.room.exits[dir] then
        player.room:doMove(player, dir)
      else
        player:send("Invalid direction!")
      end
    end,
    aliases = {
      "north", "n",
      "south", "s",
      "east", "e",
      "west", "w",
      "up", "u",
      "down", "d",
      "southeast", "se",
      "southwest", "sw",
      "northeast", "ne",
      "northwest", "nw",
      "walk"
    }
  },
  say = {
    f = function(player, parts, data)
      if #parts < 2 then
        return {"error", "Please supply a sentence to say"}
      end
      
      local msg = data:match("[^ ]+ (.+)")
      
      player.room:broadcast(player.name..' says "'..msg..'"', player)
      player:send('You say "'..msg..'"')
    end,
  },
  pose = {  
    f = function(player, parts, data)
      
      
      local msg = ""
      if not parts[1]:find("^%..+") then
        if #parts < 2 then
          return {"error", "Please supply a phrase to pose"}
        end
        msg = data:match("[^ ]+ (.+)")
      else
        msg = data
      end

      msg = msg
      
      msg = player.name.." "..msg
      
      for i,p in ipairs(player.room.objects) do
        local newmsg = msg:gsub("%.(%a+)", function(v)
          -- for verb in gmatch(%.%S+) do verb..s or verb[conjugations]
        
          -- ShinMojo @ sindome.org ([^aeiouy]|qu)y$"-> "$1ies" and (x|ch|ss|sh)$ -> "$1es"
          -- Adds an s. e.g. .walk briskly becomes "walks briskly"
          -- v = v:gsub(ShinMojo pattern (need RegEx or custom pattern builder))
          
          -- If pronouns.neutral and last used pronoun ~= nil
          if p == player then return v end -- secondPersonOfVerb(v)
          local cap = v:multimatch({"([^aeiouy]y)$","(quy)$"})
          if cap then
            return v:sub(1, #v-1).."ies"
          end
          cap = nil
          cap = v:multimatch({"(x)$", "(ch)$", "(ss)$","(sh)$"})
          
          if cap then
            return v.."es"
          end
          
          return v.."s"
        end):gsub("(\\?)(%a+)", function(except, v)
          if except ~= "" then return v end
          if p == player then return PRONOUNS.second[v:lower()] end
          return player.pronouns[v:lower()]
        end
        ):gsub(
          case_insensitive_pattern(p.name), "you"
        ):gsub(
          "([%.%?%!]) (%a)", function(punctuation, letter) return punctuation.." "..letter:upper() end
        ):gsub(
          "^%a", function(l) return l:upper() end
        )
        
        p:call("send", {newmsg})
      end
    end,
    aliases = {
      "%.", "%..+"
    }
  },
  emote = {
    f = function(player, parts, data)
      if #parts < 2 then
        return {"error", "Please supply a phrase to emote"}
      end
      player.room:broadcast(player.name.." "..data:match("%S+ (.+)"))
    end,
    aliases = {
      "/me"
    }
  },
  stop = {
    f = function(player, parts)
      player:setMenu("Are you sure you want to stop the server? ", function(p,_,i)
        if i == 1 then
          error("STOP COMMAND")
        else
          p:setState("chat")
        end
      end)
    end
  },
  set = {
    f = function(player, parts, data)
      if #parts < 2 then
        return {"error", "Please supply an object to modify"}
      elseif #parts < 3 then
        return {"error", "Please supply what value you want to change"}
      elseif #parts < 4 then
        return {"error", "Please supply a new value"}
      end
      
      local name = parts[2]
      
      obj = player.room:search(name)[1]
      
      if not obj then
        return "object not found!"
      end
      
      
      
      local key = parts[3]
      local obj, k = resolve(obj, key)
      if not obj then return player:send("Invalid keypath "..key) end
      print("Setting "..(obj.name or tostring(obj)).." at "..k)
      
      -- e.g. set hobo pronouns.myself "xirself"
      
      local payload_parts = {}
      for i = 4,#parts do
        payload_parts[#payload_parts+1] = parts[i]
      end
      
      local payload = table.concat(payload_parts, " ")
      
      payload = "return "..payload
      
      -- PLEASE SANDBOX THIS FOR THE LOVE OF GOD
      --local success, newval = pcall(loadstring(payload, {}))
      
      if not success then player:send(newval); return end
      
      if type(newval) == "function" then
        obj[k.."_str"] = payload
      end
      
      obj[k] = newval
    end
  },
  
  inspect = {
    f = function(player, parts)
      if #parts < 2 then
        return {"error", "Please supply an object to inspect"}
      end
      
      local name = parts[2]
      
      local obj = player.room:search(name)[1]
      obj = obj or db.get_or_load(tonumber(name))
      if not obj then return player:send("Object not found") end
      
      player:send(ser(obj, NEWL))
    end
  },
  social = {
    f = function(player, parts)
      
    end
  },
  save = {
    f = function(player, parts)
      for i, obj in pairs(objects) do
        db.store_object(obj)
      end
    end
  },
  help = {
    f = function(player, parts)
      if #parts < 2 then
        local s = "Available commands are:"..NEWL
        for k,v in pairs(player.cmdset) do
          -- If permitted(player, v)
          s = s .. k .. NEWL
        end
        return player:send(s)
      end
      
      local keyword = parts[2]
      
      local helpfile = helpfiles[keyword]
      
      if not helpfile then
        -- Log(player.name.." tried to find helpfile "..keyword)
        player:send("Helpfile '"..keyword.."' not found.")
        -- soundex it upppp!
        local s1 = soundex(keyword)
        
        -- Starting letter
        local l1 = s1:sub(1,1)
        -- Soundex number
        local n1 = s1:sub(2,4)
        
        local potential = {}
        
        for k,v in pairs(helpfiles) do
          -- TODO: add tags to helpfiles, soundex those as well
          local s2 = soundex(k)
          local l2 = s2:sub(1,1)
          local n2 = s2:sub(2,4)
          
          -- If the words start with the same letter
          if l1 == l2 then
            dif = math.abs(n1 - n2)
            if dif <= 5 then
              table.insert(potential, k)
            end
          end
        end
        
        
        if #potential == 1 then
          player:send("Showing helpfile for "..colour("%{yellow}"..potential[1]))
          helpfile = helpfiles[potential[1]]
        elseif #potential > 1 then
          local s = "Did you mean"
          for i,v in ipairs(potential) do
            s = s.." "..colour("%{yellow}"..v)..(i == #potential and "?" or ",")
          end
          
          player:send(s)
        end
      end
      
      
      if helpfile then
        player:send(helpfile)
      end
    end,
    aliases = {"?"}
  },
  create = {
    f = function(player, parts, data)
      if #parts < 2 then
        return {"error", "Please supply a type to create!"}
      end
      
      local t = parts[2]
      
      if not contains({"object","room","player", "scenery"}, t) then return player:send("Invalid type '"..t.."'") end
      
      local obj = Object:new()
      obj._type = t
      objects[obj.identifier] = obj
      player._editing_obj = obj
      player:setMenu(unpack(menus.obj_name))
    end
  },
  bore = {
    f = function(player, parts, data)
      if #parts < 2 then
        return {"error", "Please supply a direction"}
      end
      local dir = dirFromShort(parts[2])

      local room = {name="Blank", desc="Nothing here"}
      room.scripts = {
        "object",
        "room",
      }
      room = Object:new(room)
      db.store_object(room)
      objects[room.identifier] = room 

      player.room:attach(room, dir)
      player.room:doMove(player, dir)
    end,
  },
  reload = {
    f = function(player, parts, data)
      if #parts < 2 then
        return {"error", "Please specify an object"}
      end

      local name = parts[2]

      local obj = player.room:search(name)[1]

      if not obj then
        return {"error", "Object not found"}
      end

      db.reload(obj)
    end,
  },
  ["load"] = {
    f = function(player, parts, data)
      local id = tonumber(parts[2])

      if id then
        db.get_or_load(id)
      end
    end
  },
  attr_type = {
    f = function(player, parts, data)
      local obj
      if not parts[2] then
        return player:send("Missing object")
      end
      if not parts[3] then
        return player:send("Missing path")
      end
      
      obj = player.room:search(parts[2])[1]
      
      if not obj then
        return player:send("Couldn't find object")
      end
      
      local t, k = resolve(obj, parts[3])
      player:send(type(t[k]))
    end
  },
  edit = {
    f = function(player, parts, data)
      name = table.concat(parts, " ", 2)
      local obj = player.room:search(name)[1]
      obj = obj or db.get_or_load(tonumber(name))
      if obj then
        player._editing_obj = obj
        player:setState("edit")
        return
      elseif #parts < 2 then
        return {"error", "Please supply a type to edit, or the name of a visible object!"}
      elseif #parts < 3 then
        return {"error", "Please supply an identifier to use"}
      end
      
      local t = parts[2]
      local class = types[t]
      
      if not class then
        return player:send("Invalid type!")
      end
      
      local list = _G[t.."s"]
      
      player._editing_obj = list[tonumber(parts[3])]
      if not player._editing_obj then
        player:send(t.." #"..parts[3].." not found, creating new "..t)
        player._editing_obj = class:new()
        list[player._editing_obj.identifier] = player._editing_obj
        player:send(string.format("New %s created with identifier #%i", t, player._editing_obj.identifier))
      end
      
      player:setState("edit")
    end
  },
  attack = {
    f = function(player, parts)
      local target = player.room:search(parts[2])
      
      if target then
        -- check if it's a mobile?
        if target.hp then
          if player.room.flags:sub(1,1) == "1" then
            player:send("Cannot start a fight here!")
          elseif target.arena then
            target.arena:add(player)
          else
            local arena = Arena:new()
            arena:add(player)
            arena:add(target)
            target:setState("combat")
          end
          player:setState("combat")
        else
          player:send("That target is not combattable!")
        end
      elseif parts[2] then
        player:send(parts[2].." not found!")
      else
        return {"error", "Please provide a target to attack!"}
      end
    end
  },
  exits = {
    f = function(player, parts)
      player:send("The available exits are:")
      
      for k,v in pairs(player.room.exits) do
        player:send(k)
      end
    end
  },
  ident = {
    f = function(player, parts)
      if not parts[2] then
        obj = player.room
      else
        obj = player.room:search(parts[2])[1]
      end
      
      if obj then
        player:send(("Identifier of %q is %i"):format(obj.name, obj.identifier))
      else
        player:send("Object not found!")
      end
    end
  },
  manual = {
    f = function(player, parts)
      player:send(
[[INTRODUCTION

To interact with the world, type commands into the prompt in the following format

>command argument1 argument2 argument3 ...

e.g.

>walk north

Type 'help' to show a list of available commands, and type 'help command' to read a more detailed helpfile.
]])
    end
  },
  take = {
    f = function(player, parts)
      local obj = player.room:search(parts[2])[1]

      if obj then 
        if obj:getMovable(player) then
          player.room:remove(obj)
          player:add(obj)
          player:send(obj:call("onPickup") or obj:getName().." taken!")
        else
          player:send("Can't pick up "..obj:getName())
        end
      else
        player:send("Object not found")
      end
    end
  },
  drop = {
    f = function(player, parts)
      local obj = player:search(parts[2])[1]

      if obj and obj ~= player then
        player:remove(obj)
        player.room:add(obj)
        obj:call("onDrop", {player, player.room})
        player:send("Dropped "..obj.name)
      else
        player:send("Can't find object to drop")
      end
    end
  },
  tp = {
    f = function(player, parts)
      if #parts < 3 then
        return {"error", "Please supply two IDs"}
      end
      local obj, destination = db.get_or_load(tonumber(parts[2])), db.get_or_load(tonumber(parts[3]))

      if obj and destination then
        if obj:getRoom() then
          obj:getRoom():remove(obj)
        end
        obj.room = destination
        destination:add(obj)
      elseif not obj then
        player:send("Invalid object")
      else
        player:send("Invalid desination")
      end

    end
  },
  unlock = {
    f = function(player, parts)
      local dir = dirFromShort(parts[2])
      local locks = player.room:getLocks()
      if locks and locks[dir] then
        if locks[dir]:unlock(player) then
          player:send("Your key fits!")
          return
        else
          player:send("Your keys don't fit")
        end
      else
        player:send("Nothing to unlock")
      end
    end,
  },
  attach = {
    f = function(player, parts)
      local dir, dest, room
      if #parts < 2 then
        for _,dir in ipairs({"north", "south", "east", "west"}) do
          verbs.attach.f(player, {"attach ", dir})
        end
        return
      else
        dir = dirFromShort(parts[2])
        room = player.room
        if #parts == 2 then
          local target = dirvecs[dir]
          if target then
            dest = bfs(target, room)
          end
        else
          dest = db.get_or_load(tonumber(parts[3]))
        end
        if not dest then
          -- verbs should maybe return a string to be printed?
          player:send("Destination not found")
          return
        end
      end

      -- room:attach(dir, dest)
      room.exits[dir] = dest

      if oppdirs[dir] then
        local opp = oppdirs[dir]
        dest.exits[opp] = room
      end
    end,
  },
}

for k,v in pairs(t) do
  v.aliases = v.aliases or {}
  
  table.insert(v.aliases, k)
  
  v.name = k
end

return t
