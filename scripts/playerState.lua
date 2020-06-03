return {
  data = {
    state = "chat",
  },
  methods = {
    setState = {
      function(self, args, res, next)
        local state = unpack(args)
        self.prompt = nil
        local after = handlers[self.state].after
        if after then after(self) end

        local before = handlers[state].before
        if before then before(self) end

        self.state = state
      end,
    },
    setMenu = {
      function(self, args, res, next)
        local prompt, f, input = unpack(args) 
        input = input or {"y","n"}
        self.state = "menu"
        self.prompt = prompt
        self.__menu = function(player, data)

          for i = 1, #input do
            patt = "^"..input[i]

            if data:match(patt) then

              f(player, data, i)
              return
            end
          end
          player:send("Invalid option!")
        end
      end,
    },
  },
}
