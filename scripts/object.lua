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
  },
  getMessage = {
    function(self, args, ret)
      local messageName, args = unpack(args)
      local messages = self:getMessages()
      if not messages then return nil end
      local message = messages[messageName]
      if not message then return nil end

      return message:gsub("{([^}]+)}", function(key)
	    	local t,k = utils.resolve({self=self,args=args}, key)
	    	if not t then
	        print("missing key "..key)
          return ""	
	    	end
	    	return t[k]
	    end)
      
    end
  },
}

return {data = data, methods = methods}
