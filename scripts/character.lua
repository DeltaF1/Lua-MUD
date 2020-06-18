return {
  methods = {
    onEnter = {
      function(self, args, ret)
        args[1] = oppdirs[args[1]] or args[1]
      end,
      function(self, args ,ret)
        local message = self:getMessage("enters", {dir=args[1]}) or (self.name.." enters from the "..args[1])
        self.room:broadcast(message, self)
      end
    },
    onExit = {
      function(self, args, ret)
        local dir = xml.wrapText(args[1], "dir")
        self.name = xml.wrapText(self.name, "char", {id=self.identifier})
        local message = self:getMessage("leaves", {dir=dir}) or (self.name.." leaves to the "..dir)
        self.name = xml.stripTags(self.name)
        self.room:broadcast(xml.wrapText(message, "leave"), self)
      end
    },
    walk = {
      function(self, args, ret)
        self.room:doMove(self, args[1])
      end
    },
  },
}
