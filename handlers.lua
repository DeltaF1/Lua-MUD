-- ANSI colour names
local colours = {"red","green","yellow","blue","magenta","cyan"}

return {
  login1 = {
    f = function(user, data)
      print(user.__sock:getpeername()..": Initial text: "..data)
      -- Can't set user's name to a 0-length string
      if #data == 0 then
        return
      end
      -- If there are any non alphanumeric characters in the data
      if data:find("%W") then
        user.__sock:send("Invalid name, name must only contain alphanumeric characters (a-z, A-Z, 0-9)"..NEWL)
        return
      end
      
      if data == "new" then
        user:setState("newAccount1")
      else
        user.name = data
        user:setState("login2")
      end

    end,
    prompt = colour("%{green}Please enter your username (new to create a new account):")
  },
  newAccount1 = {
    f = function(user, data)
      if data:find("%W") then
        user.__sock:send("Invalid name, name must only contain alphanumeric characters (a-z, A-Z, 0-9)"..NEWL)
      elseif db.get_user(data) or data == "new" then
        user.__sock:send("Account with that name already exists!"..NEWL)
      else
        user.name = data
        user:setState("newAccount2")
      end
    end,
    prompt = "New account name: "
  },
  newAccount2 = {
    f = function(user, data)
      if #data < 8 then
        user.__sock:send("Please enter a password that is at least 8 characters long"..NEWL)
      else
        user.password = data
        user:setState("newAccount3")
      end
    end,
    before = function(user) user:send(IAC..WILL..ECHO, "") end,
    prompt = "Enter your password (DO NOT REUSE ANY OTHER PASSWORDS): ",
  },
  newAccount3 = {
    f = function(user, data)
      if data == user.password then
        user.password = nil
        db.add_user(user.name, data)
        user:setState("login1")
      else
        user.__sock:send("Password doesn't match!"..NEWL)
      end
    end,
    prompt = "Confirm your password: ",
    after = function(user) user:send(IAC..WONT..ECHO, "") end,
  },
  login2 = {
    before = function(user) user:send(IAC..WILL..ECHO, "") end,
    f = function(user, data)
    
      -- Get hash of user.name..data..salt
    
      --ADD SALT

      --FOR THE LOVE OF GOD DON'T USE MD5
      -- TODO use salt, and sha256

      userData = db.get_user(user.name)

      hash = md5.sumhexa(data)

      if not userData or userData.passhash:lower() ~= hash:lower() then
        user:send("Incorrect login!")
        user:setState("login1")
        return
      end
      
      for k,v in pairs(clients) do
        if v ~= user and ((v.state:find("login3") and v.name == user.name) or (v.user and v.user == user.name)) then
          user:send("Error: Already logged in!")
          user:setState("login1")

          return
        end
      end

      user:setState("login3")
    end,
    after = function(user) user:send(IAC..WONT..ECHO, "") end,
    prompt = colour("%{red}Please enter your password: ")
  },
  login3 = {
    before = function(user)
      local characters = db.get_user(user.name).characters 
      user.characters = {} 
      for i = 1, #characters do
        local char = db.get_or_load(characters[i])
        user.characters[char.name] = char
      end
      
      if #characters > 0 then
        user:send(NEWL.."Your characters:")
        for k,v in pairs(user.characters) do
          user:send(colour("%{yellow}"..k))  
        end  
      end
    end,
    f = function(user, data)
      if data == "quit" then
        verbs.quit.f(user)
      end

      if data == "new" then
        user._editing_obj = Object:new()
        user._editing_obj.user = user.name
        user:pushMenu(unpack(menus.char_gender))
        return
        -- TODO: Drop into the world here
        --player = db.load_object(194)
        --player.identifier = nil
      else
        player = user.characters[data]
      end
      if not player then
        user:send("Invalid character name")
        return
      end

      -- player.user = user
      player.__sock = user.__sock
      player.user = user.name
      clients[user.__sock] = player
      
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

      local STARTING_ROOM = db.load_object(tonumber(config.world_info.starting_room))
      -- Calling load_object creates an orphaned room since it's not 
      -- added to the objects_table
      STARTING_ROOM.identifier = 0
      -- Prevents the player from reloading into the base room
      player.room = player:getRoom() or STARTING_ROOM
      player.room:add(player)

      player:send(player.room:getDesc(player))

      -- Announce the player entering the server
      player.room:broadcast(player.name.." steps through the looking glass and appears here", player)

      -- To make sure the prompt is properly updated
      user:setState("chat")
      player.state = "login3"
      player:setState("chat")
    end,
    prompt = "Select a character, or type 'new' or 'quit': "
  },
  chat = {
    f = function(player, data)

      -- Don't do anything
      if #data == 0 then
        return
      end

      -- Get parts of data. e.g. "Why is the rum always gone?" will become {"Why", "is", "the", "rum", "always", "gone?"}
      local parts = split(data)
      
      -- replace parts like "@here" or "@me" with names of objects
      for i, part in ipairs(parts) do
        parts[i] = part:gsub("@([^ ]*)", {me=player.name, here=player.room.name})
      end
    
      -- First word sent
      local cmd = parts[1]
      if not cmd then return end

      -- Declare verb and name of verb
      local verb
      local key

      if player.room.cmdset and player.room.cmdset:find(cmd) then
        verb = player.room.cmdset:find(cmd)
      else
        verb = player.cmdset:find(cmd)
      end

      if verb then
        key = verb.name
        -- Run the verb, passing in the player, split parts, and original data string
        --
        -- If the player is puppeting, send with the puppeted NPC as the player argument
        local res = verb.f(player, parts, data)

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
    f = function(player, data)
      player.__menu(player, data)
    end,
    prompt = "menu> "
  },
  edit = {
    f = function(player, data)
      local parts = split(data)
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
      
      local t, key = resolve(player._editing_obj, key)
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
      parts = split(data)

      local arena = player.arena

      local verb = parts[1]
      if not parts[2] then
        return player:send("Please supply a target to attack!")
      end
      if verb == "attack" then -- hard coded D:
        local target = player.room:search(parts[2])
        if contains(arena.mobiles, target) then
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
