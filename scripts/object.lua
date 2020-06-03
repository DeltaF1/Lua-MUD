local data = {
  name = "",
  aliases = {},
  desc = "",
}

local methods = {
  getDesc = {
    function(self, args, retval, next)
      return self.desc
    end
  }
}

return {data = data, methods = methods}
