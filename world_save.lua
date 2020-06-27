local tostring = tostring
local pairs = pairs
local table = table

local t = {}

local EDITOR_KEYWORDS = {"and", "break", "do", "else", "elseif",
     "end", "false", "for", "function", "if",
     "in", "local", "nil", "not", "or",
     "repeat", "return", "then", "true", "until", "while"}


-- Serialize a table
function t.ser(obj, newl, indent, tables)
  if getmetatable(obj) and getmetatable(obj) == CommandSet then
    --Serialize the keys
    obj = utils.keys(obj)
  end
  local newl = newl or "\n"
  -- Previously serialized tables, to prevent stack overflows
  local tables = tables or {}
  local indent = indent or 1
  local indentStr = string.rep("  ", indent)
  local s = --[[string.rep("  ", indent-1)..]]'{'..newl
  for k,v in pairs(obj) do
    -- Discard function keys. If they're built in they'll be part of a superclass, if they're custom they'll be encoded in xxx_str
    if type(v) ~= "function" and type(v) ~= "userdata" and not (type(k) == "string" and  k:match("^__")) then        
      s = s .. indentStr
      if type(k) == "string" then
         -- If the key is only alphanumeric, and doesn't start with a number, leave it as is. Otheriwse add ["key"] syntax
        if utils.contains(EDITOR_KEYWORDS, k) or not k:match("^[%a_][%w_]*$") then
          k = '["'..k..'"]'
        end
        
      -- If the key is a number index add brackets. e.g. {[1]="foo", [2]="bar"}
      else
        if type(k) == "table" then
          if k.__id then
            k = 'ID('..k.__id..')'
          elseif rawget(k, "identifier") then
            k = 'ID('..k.identifier..')'
          -- If it's a table not yet seen, encode it
          elseif not utils.contains(tables, k) then
            table.insert(tables, k)
            k = ser(k, newl, indent+1, tables)
          end
        end
        
        k = "["..k.."]"
      end
      
      s = s ..k..' = '
      
      if type(v) == "string" then
        v = v:gsub(NEWL, "\\"..NEWL)
        v = v:gsub('\\','\\\\')
        v = v:gsub('"', '\\"')
        v = '"'..v..'"'
      elseif type(v) == "table" then
        -- If it has an identifier, then encode that instead of the table
        if v.__id then
          v = 'ID('..v.__id..')'
        elseif rawget(v, "identifier") then
          v = 'ID('..v.identifier..')'
        -- If it's a table not yet seen, encode it
        elseif not utils.contains(tables, v) then
          table.insert(tables, v)
          v = ser(v, newl, indent+1, tables)
        end
      end
      
      s = s .. tostring(v) .. ","
      s = s..newl
    end
  end
  s = s..string.rep("  ",indent-1).."}"
  return s
end

function t.save()
  for dir, tbl in pairs{["rooms"]=rooms, ["objects"]=objects, ["players"]=players} do
    saveTable(tbl, dir)
  end
  
  
  
end

local function saveTable(tbl, dir)
  local files = {}
  for k,v in pairs(tbl) do
    files[v.filename] = files[v.filename] or {}
    table.insert(files[v.filename], v)
  end
  
  for k,v in pairs(files) do
    print("Saving to file "..k)
    local s = "-- "..k.."\n\n"
    -- s = s.."-- Generated "..os.time()
    for _, object in ipairs(v) do
      if object.sock then
        local oldsock = object.sock
        object.sock = nil
      end
      s = s..object.identifier.." = "..ser(object).."\n\n"
      if oldsock then object.sock = oldsock end
    end
    s = s.."--[[END OF FILE]]--"
    
    -- Need to find way to create empty file
    local f = io.open("world"..DIR_SEP..dir..DIR_SEP..k, "w")
    f:write(s)
    f:close()
  end
  --print(ser(keys))
end

return t
