return {
  data = {
    randomEvents = {}
  },

  methods = {
    onTick = {
      function(self)
        for eventName, probability in pairs(self.randomEvents) do
          if math.random() < probability then
            self:call(eventName)
          end
        end
      end
    },
  },
}
