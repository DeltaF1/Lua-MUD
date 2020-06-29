return {
  methods = {
    close = {
      function(self, args, ret)
        if self.puppeting then
          self:unpuppet()
        end
        print(("%s [%s] has disconnected"):format(self.name, self.sock:getpeername()))
        self.sock:close()
      end
    },
    puppet = {
      function(self, args, ret)
        local character = args[1]
        if character.__puppeteer then
          return STOP
        end
        
        character.__puppeteer = self
        character:call("onPuppet", {self})
        self.puppeting = character 
        return true
      end
    },
    unpuppet = {
      function(self, args, ret)
        local character = self.puppeting
        character.__puppeteer = nil
        character:call("onUnpuppet", {self})
        self.puppeting = nil
      end
    },
  },
}
