return {
  data = {
    ephemeral = true
  },

  dependencies = {
    "object",
    "playerState",
    "container",
  },

  methods = {
    onEnter = {
      function(self, args)
        return self.room:getDesc(self)
      end,
      function(self, args, ret)
        self:send(ret)
      end
    },
    onLoad = {
      function(self, args)
        if not self.cmdset then
					self.cmdset = cmdsets.Default
				end

				self.cmdset = CommandSet:new(self.cmdset)
				self.cmdset = self.cmdset:union(cmdsets.Default)
      end
    },
  }
}
