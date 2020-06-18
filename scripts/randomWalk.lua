return {
  dependencies = {
    "randomEvents"
  },
  data = {
    ["randomEvents.onRandomWalk"]=0.001,
  },
  methods = {
    onRandomWalk = {
      function(self)
        local exits = keys(self.room:getExits())

        local dir = exits[math.random(#exits)]
        self:call("walk", {dir})
      end,
    },
  },
}
