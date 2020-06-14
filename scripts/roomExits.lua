return {
  data = {
    exits = {},
  },

  methods = {
    attach = {
      function(self, args, _, next)
        local room, dir, oppdir = unpack(args)
        local oppdir = oppdir or oppdirs[dir]
        
        self.exits[dir] = room
        
        if oppdir then
          room.exits[oppdir] = self
        end
      end,
    },
    detach = {
      function(self, args, _, next)
        local dir, oppdir = unpack(args)
        local oppdir = oppdir or oppdirs[dir]
        if oppdir and self.exits[dir] then
          self.exits[dir].exits[oppdir] = nil
          self.exits[dir] = nil
        end
      end,
    },
    -- TODO: Rename player to object?
    doMove = {
      function(self, args)
        local player, dir = unpack(args)
        local destination = self:getExit(dir, player)

        if destination then
          self:call("onExit", {player=player, dir=dir})

          player:call("onExit", {dir})
          
          tremove(self.objects, player)
          destination:add(player)

          player.room = destination
          player:call("onEnter", {dir})

          destination:call("onEnter")
          return destination
        else
          player:call("send", {"Can't go that way!"})
          return STOP
        end
      end
    },
    getExit = {
      function(self, args)
        local dir, object = unpack(args)

        return self.exits[dir]
      end
    },
  },
} 
