return {
  data = {
    objects = {},
  },

  methods = {
    onLoad = {
      function(self, args, res, next)
        for i = #self.objects, 1, -1 do
          local obj = self.objects[i]
        end
      end,
    },
    add = {
      function(self, args, retval)
        local obj = args[1]

        for i = 1, #self.objects do
          if self.objects[i] == obj then
            return STOP
          end
        end

        self.objects[#self.objects + 1] = obj
        return true
      end,
    },
    remove = {
      function(self, args, retval)
        local obj = args[1]
        
        utils.tremove(self.objects, obj)
      end,
    },
    search = {
      function (self, args, res, next)
        local name = args[1]:lower()
        local res = res or {}
        if not name then return end
        if self.name:lower() == name then res[#res+1] = self end
        for i = 1, #self.objects do
          local obj = self.objects[i]
          if obj.name:lower() == name or utils.contains(obj.aliases, name) then
            res[#res+1] = obj
          end
        end
	if #res == 0 and args.printMissing ~= false then
          print("[search]"..'"'..self:getName()..'" ('..tostring(self.identifier)..") didn't contain \""..name..'"')
        end
        return res
      end
    }
  },
}
