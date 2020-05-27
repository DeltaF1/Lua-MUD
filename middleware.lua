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

function middleware:insert(name, func, pos)
  if not self[name] then self[name] = {} end
  local funcs = self[name]
  table.insert(funcs, pos, func)  
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
  local ret, b
  for i = 1, #funcs do
    local f = funcs[i]
    if f then
      ret, b  = f(obj, args, ret)
      if ret == STOP then
        return b
      end
    end
  end
  
  return ret
end

return new
