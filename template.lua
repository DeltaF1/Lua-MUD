return function(name, ...)
  local f = require("templates."..name)

  local t = f(...)

  return Object:new(t)
end
