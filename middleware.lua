STOP = {}

local middleware = {}

middleware.__index = middleware

local function new()
  return setmetatable({}, middleware)
end

function middleware:append(name, func)
  if not self[name] then self[name] = {} end
  local funcs = self[name]
  funcs[#funcs + 1] = func
end

function middleware:prepend(name, func)
  if not self[name] then self[name] = {} end
  local funcs = self[name]
  table.insert(funcs, 1, func)  
end

function middleware:remove(name, func)
  local funcs = self[name]
  if not funcs then return end
  for i = #funcs, 1, -1 do
    if funcs[i] == func then
      table.remove(funcs, i)
      break
    end
  end
  if #self[name] == 0 then self[name] = nil end
end

function middleware:call(obj, name, args)
  local funcs = self[name]
  if not funcs then return nil end
  local i = 0
  local res = {}
  local function next()
    i = i + 1
    local f = funcs[i]
    if f then
      return f(obj, args, res, next)
    end
  end

  retCode = next()
  if retCode ~= nil then
    return retCode
  end
  return res
end

middleware.__call = middleware.call

return new
