local stripTags = require "xmlparser".stripTags
return {
  data = {},
  methods = {
    send = {
      function(self, args, res, next)
        if not args[1] then args[1] = "" end
        if not args[2] then args[2] = NEWL end
      end,

      function(self, args, res, next)
        local msg = args[1]
        return msg
      end,

      function(self, args, res)
        success, stripped  = pcall(stripTags, res)
        if not success then
          if res:match("<") then
            print("Error parsing XML:")
            print(stripped)
          end
          stripped = res
        end
        if type(stripped) ~= "string" then
          print(stripped)
          print(res)
        end

        return stripped
      end,

      function(self, args, res)
        local concat = args[2]
        if concat then
          return res..concat
        else 
          return res
        end
      end,

      function(self, args, res, next)
        local msg = res
        msg = msg:gsub("([^\r])(\n)", "%1\r\n")
        if self.__sock then
          self.__sock:send(msg)
        end
        return msg
      end,
    },
  },
}
