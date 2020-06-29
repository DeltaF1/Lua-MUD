return {
  data = {
    ephemeral = true
  },

  dependencies = {
    "object",
    "container",
    "character",
    "vanishAfterDisconnect",
  },

  methods = {
    onEnter = {
      function(self, args)
        return self.room:getDesc(self)
      end,
      function(self, args, ret)
        self:send(ret)
      end,
      -- TODO: move this to character class
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
    send = {
      function(self, args, ret)
        if self.__puppeteer then
          return self.__puppeteer:call("send", args)
        end
      end
    },
    setState = {
      function(self, args, ret)
        if self.__puppeteer then
          return self.__puppeteer:call("setState", args)
        end
      end
    },
    setMenu = {
      function(self, args, ret)
        if self.__puppeteer then
          return self.__puppeteer:call("setMenu", args)
        end
      end
    },
    pushMenu = {
      function(self, args, ret)
        if self.__puppeteer then
          return self.__puppeteer:call("pushMenu", args)
        end
      end
    },
    popMenu = {
      function(self, args, ret)
        if self.__puppeteer then
          return self.__puppeteer:call("popMenu", args)
        end
      end
    },
  }
}
