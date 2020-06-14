local Middleware = require "middleware"
local Object = {}

Object.__index = Object

Object.__index = function(self, key)
  local v = Object[key]
  if v then return v
  elseif rawget(self, "__middleware") and rawget(self.__middleware, key) then
        -- TODO: Should calls to nonexistent
        -- methods error or just do nothing?
        -- Polymorphism vs. ease of debugging
    return function(self, ...)
      return self.__middleware:call(self, key, {...})
    end
  elseif key:match("^get") then
    return function(self)
      return rawget(self, key:sub(4,4):lower()..key:sub(5,-1))
    end
  end
end

Object.new = function(self,o)
	-- Either create a new object, or turn existing table into an instance
	local o = o or {}
  setmetatable(o, self)	
	if not o.identifier then
    o.identifier = db.reserve_id() 
	end
  if not o.scripts then
    o.scripts = {"object"}
  end
  o:updateScripts()

  return o  
end

function Object:updateScripts()
  self.__middleware = Middleware()
  local loaded = {}
  for i = 1, #self.scripts do
    local k = self.scripts[i]
    self:loadScript(k, loaded)
  end
end

function Object:loadScript(scriptName, loaded)
  loaded = loaded or {}
  if loaded[scriptName] then return end
  loaded[scriptName] = require("scripts."..scriptName)
  local script = loaded[scriptName]
  if script.dependencies then
    for j = 1, #script.dependencies do
      self:loadScript(script.dependencies[j], loaded)
    end
  end
  
  for k,v in pairs(script.data or {}) do
    if self[k] == nil then
      local t, key = resolve(self, k)
      if t then
        t[key] = deepcopy(v)
      end
    end
  end

  for methodName,middleware in pairs(script.insert or {}) do
    for j = 1, #middleware do
      local func, pos = unpack(middleware[j])
      if pos < 0 then
        pos = #(self.__middleware[methodName] or {}) + pos + 1
      end
      self.__middleware:insert_middleware(methodName, func, pos)
    end
  end

  for methodName,middleware in pairs(script.methods or {}) do
    for j = 1, #middleware do
      local func = middleware[j]
      self.__middleware:append_middleware(methodName, func)
    end
  end
end

function Object:call(name, args)
  return self.__middleware:call(self, name, args)
end

return Object
