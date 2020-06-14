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
          if not source or source ~= player then 
            player:call("send", {message})
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
          return res..NEWL..NEWL..containerList
        end
        return res
      end,
    },
  },
}

