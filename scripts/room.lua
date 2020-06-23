return {
  dependencies = {
    "object",
    "container",
    "roomExits",
  },
  methods = {
    broadcast = {
      function(self, args, res)
        local message, source = unpack(args)
        for i = 1, #self.objects do
          local player = self.objects[i]
          -- calling "send" could potentially trigger an object to go away, which makes an object dissapear...
          -- therefore have to check player's existence
          if player and (not source or source ~= player) then 
            deferred(player, "send", {message})
          end
        end
      end,
    },
    
    getDesc = {
      function(self, args, res)
        return self.name..NEWL..NEWL..res
      end,

      function(self, args, res)
        local source = args[1]
        local containerList = "" 
        for i = 1, #self.objects do
          local object = self.objects[i]
          if object ~= source and not object:getScenery() then
            local roomDesc = object:getRoomDesc(self) 
            local message = (roomDesc or "You see "..object.name..".").." "
            containerList = containerList .. message
          end
        end
        if #containerList > 0 then
          res = res..NEWL..NEWL..containerList
        end
        exits = colour("%{yellow}exits: ["..self:getExitsDesc().."]")
        res = res..NEWL..exits
        return res
      end,
    },

    getExitsDesc = {
      function(self, args, ret)
        return self:getExits()
      end,
      function(self, args, ret)
        return table.concat(keys(ret), ", ")
      end
    },
    onTick = {
      function(self, args, ret)
        if self.__checkedConsistency then return end
        self.__checkedConsistency = true 
        for k,v in pairs(self:getExits()) do
          if not v.exits or not v:getExits() then
            print(("WARNING: room %q is attempting to link to room %q (which has no exits)"):format(self.identifier, v.identifier or "NIL"))
            print(ser(v))
          end
        end
      end,
    },
  },
}

