return {
  data = {},
  insert = {
    send = {
      {
      function(self, args, res, next)
        local msg = res
        if self.room then
          return string.gsub(msg, "(%S+)", function(v)
            -- For every word, search the room for an object with that name
            local a, name, b = v:match("([^%a']*)([%a']+)([^%a]*)")
            if not name then return nil end
            local obj = self.room:search(name)[1]

            -- If that name means an object, highlight it
            if obj and obj.colour then
              return a.."%{"..(obj.colour).."}"..name.."%{reset}"..b
            end
          end)
        end
        return msg
      end,
      -1
      },
      {
        function (self, args,res)
          return colour(res)
        end,
        -1
      }
    },
  },
}

