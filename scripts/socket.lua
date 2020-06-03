return {
  data = {},
  methods = {
    send = {
      function(self, args, res, next)
        if not args[1] then args[1] = "" end
        if not args[2] then args[2] = NEWL end
      end,

      function(self, args, res, next)
        local msg, concat = unpack(args)
        if concat then
          msg = msg..concat
        end
        return msg
      end,

      function(self, args, res, next)
        local msg = res
        msg = msg:gsub("([^\r])(\n)", "%1\r\n")
        self.__sock:send(msg)
        return msg
      end,
    },
  },
}
