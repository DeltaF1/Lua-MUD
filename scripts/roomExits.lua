return {
  data = {
    exits = {},
  },

  methods = {
    attach = {
      function(self, args, _, next)
        local room, dir = args.room, args.dir
        local oppdir = oppdirs[dir]
        
        self.exits[dir] = room
        
        if oppdir then
          room.exits[oppdir] = self
        end
      end,
    },
    detach = {
      function(self, args, _, next)
        local dir = args.dir
        local oppdir = oppdirs[dir]
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
        local destination = self.exits[dir]

        if destination then
          self:call("onExit", {player=player, dir=dir})

          player:call("onExit")
          
          tremove(self.objects, player)
          destination:add(player)

          player.room = destination
          player:call("onEnter")

          --destination:call("onEnter")
        else
          player:send("Can't go that way!")
          return STOP
        end
      end
    },
  },
} 
