-- ANSI colour names
local colours = {"red","green","yellow","blue","magenta","cyan"}

return {
  login1 = {
    f = function(client, data)
      print((client.sock:getpeername() or "nil")..": Initial text: "..(data or "nil"))
      -- Can't set client's name to a 0-length string
      if #data == 0 then
        return
      end
      -- If there are any non alphanumeric characters in the data
      if data:find("%W") then
        client.sock:send("Invalid name, name must only contain alphanumeric characters (a-z, A-Z, 0-9)"..NEWL)
        return
      end
      
      if data == "new" then
        client:setState("newAccount1")
      else
        client.name = data
        client:setState("login2")
      end
    end,
    prompt = colour("%{green}Please enter your username (new to create a new account):")
  },
  newAccount1 = {
    f = function(client, data)
      if data:find("%W") then
        client.sock:send("Invalid name, name must only contain alphanumeric characters (a-z, A-Z, 0-9)"..NEWL)
      elseif db.get_user(data) or data == "new" then
        client.sock:send("Account with that name already exists!"..NEWL)
      else
        client.name = data
        client:setState("newAccount2")
      end
    end,
    prompt = "New account name: "
  },
  newAccount2 = {
    f = function(client, data)
      if #data < 8 then
        client.sock:send("Please enter a password that is at least 8 characters long"..NEWL)
      else
        client.password = data
        client:setState("newAccount3")
      end
    end,
    before = function(client) client:send(IAC..WILL..ECHO, "") end,
    prompt = "Enter your password (DO NOT REUSE ANY OTHER PASSWORDS): ",
  },
  newAccount3 = {
    f = function(client, data)
      if data == client.password then
        client.password = nil
        db.add_user(client.name, data)
        client:setState("login1")
      else
        client.sock:send("Password doesn't match!"..NEWL)
      end
    end,
    prompt = "Confirm your password: ",
    after = function(client) client:send(IAC..WONT..ECHO, "") end,
  },
  login2 = {
    before = function(client) client:send(IAC..WILL..ECHO, "") end,
    f = function(client, data)
    
      -- Get hash of user.name..data..salt
    
      --ADD SALT

      --FOR THE LOVE OF GOD DON'T USE MD5
      -- TODO use salt, and sha256

      userData = db.get_user(client.name)

      hash = md5.sumhexa(data)

      if not userData or userData.passhash:lower() ~= hash:lower() then
        client:send("Incorrect login!")
        client:setState("login1")
        return
      end
      
      for k,v in pairs(clients) do
        if v ~= client and v.name == client.name then
          v:close()
          clients[k] = nil
        end
      end

      client:setState("login3")
    end,
    after = function(client) client:send(IAC..WONT..ECHO, "") end,
    prompt = colour("%{red}Please enter your password: ")
  },
  login3 = {
    before = function(client)
      local characters = db.get_user(client.name).characters
      client.characters = {}
      for i = 1, #characters do
        local char = db.get_or_load(characters[i])
        client.characters[char.name] = char
      end
      
      if #characters > 0 then
        client:send(NEWL.."Your characters:")
        for k,v in pairs(client.characters) do
          client:send(colour("%{yellow}"..k))
        end  
      end
    end,
    f = function(client, data)
      if data == "quit" then
        clients[client.sock] = nil
        client:close()
        return
      end

      local player
      if data == "new" then
        user._editing_obj = Object:new()
        user._editing_obj.user = user.name
        user:pushMenu(unpack(menus.char_gender))
        return
        -- TODO: Drop into the world here
        --player = db.load_object(194)
        --player.identifier = nil
      else
        player = client.characters[data]
      end
      if not player then
        client:send("Invalid character name")
        return
      end

      client:puppet(player)
      
      -- TODO: Move this to world_load
      if not player.cmdset then
        player.cmdset = cmdsets.Default
      end

      player.cmdset = CommandSet:new(player.cmdset)
      player.cmdset = player.cmdset:union(cmdsets.Default)
      
      if player.user == config.admin_name then
        player.cmdset = player.cmdset:union(cmdsets.All)
      end

      player.__loaded = true

      player.colour = colours[math.random(#colours)]

      local STARTING_ROOM = db.get_or_load(tonumber(config.world_info.starting_room))
      player.room = player:getRoom() or STARTING_ROOM
      player.room:add(player)

      player:send(player.room:getDesc(player))

      -- Announce the player entering the server
      player.room:broadcast(player.name.." steps through the looking glass and appears here", player)

      client:setState("chat")
    end,
    prompt = "Select a character, or type 'new' or 'quit': "
  },
  chat = {
    f = function(client, data)
      local player = client.puppeting
      -- Don't do anything
      if #data == 0 then
        return
      end

      -- Get parts of data. e.g. "walk to the north" becomes {"walk", "to", "the", "north"}
      local parts = utils.split(data)
      
      -- replace parts like "@here" or "@me" with names of objects
      for i, part in ipairs(parts) do
        parts[i] = part:gsub("@([^ ]*)", {me=player.name, here=player.room.name})
      end
    
      -- First word sent
      local cmd = parts[1]
      if not cmd then return end
      
      -- verb object
      local verb
      -- if the text is an exit in this room then choose the "go" verb
      if player.room:getExit(cmd, player) then
        verb = player.cmdset:find("go")
      end

      -- if the text is a verb the player has access to,
      -- then do that instead, falling back on the "go" verb if no verbs match
      verb = player.cmdset:find(cmd) or verb

      if verb then
        local key = verb.name
        -- Run the verb, passing in the player, split parts, and original data string
        local res = verb.f(player, parts, data)

        -- Half-complete standardized error handling for verbs
        if res and type(res) == "table" then
          if res[1] == "error" then
            -- Send the error message
            player:send(res[2])

            if key ~= "help" then
              player:send("Try 'help "..key.."'")
            end
          end
        end
      else
        player:send("Verb not found")
      end
    end,
    prompt = "%{green}> %{reset}"
  },
  menu = {
    f = function(client, data)
      local player = client.puppeting
      client.__menu(player, data)
    end,
    prompt = "menu> "
  },
  edit = {
    f = function(client, data)
      local player = client.puppeting
      local parts = utils.split(data)
      local key = parts[1]
      if #parts < 1 then
        return
      elseif #parts == 1 then
        if key == "quit" or key == "save" then
          db.store_object(player._editing_obj)
          db.reload(db.get_or_load(player._editing_obj.identifier))
          player._editing_obj = nil
          player:setState("chat")
          return
        elseif key == "abort" then
          player._editing_obj = nil
          player:setState("chat")
          return
        end
      end
      
      local t, key = utils.resolve(player._editing_obj, key)
      local val
      if parts[2] == "append" and type(t[key]) == "table" then
        val = table.concat(parts, " ", 3)
        t = t[key]
        key = #t+1
      else
        val = table.concat(parts, " ", 2)
      end
      print("key = "..tostring(key).." val = "..tostring(val))
      if not key then return end
      
      if val:sub(1,1) == '"' then
        -- It's an explicit string, don't try and parse it further
        val = val:match('"(.*)"') or val
      elseif tonumber(val) then
        val = tonumber(val)
      elseif val == "nil" then
        val = nil
      elseif val:sub(1,1) == '[' then
        -- It's an identifier
        val = val:match('%[(.*)%]')
        if tonumber(val) then
          obj = db.get_or_load(tonumber(val))
        else
          obj = player.room:search(val)[1]
        end
        if not obj then
          player:send(("Identifier %q was not found, setting to nil..."):format(val))
        end
        val = obj
      elseif val:match("{.*}") then
        val = {}
        --[[
        for element in split(val:match("{.*}"), ",") do
          
        end
        ]]--
      end
      t[key] = val
    end,
    prompt = "edit> "
  },

  combat = {
    f = function(player, data)
      parts = utils.split(data)

      local arena = player.arena

      local verb = parts[1]
      if not parts[2] then
        return player:send("Please supply a target to attack!")
      end
      if verb == "attack" then -- hard coded D:
        local target = player.room:search(parts[2])
        if utils.contains(arena.mobiles, target) then
          if player.ap > 3 then -- hard coded D:
            player.ap = player.ap - 3
            target:damage(1) -- hard coded D:
          end
        else
          player:send("Invalid target!")
        end
      elseif verb == "quit" then
        player:setState("chat")
      end
    end,
    prompt = "combat> "
  }
}
