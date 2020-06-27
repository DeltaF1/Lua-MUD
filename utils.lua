local utils = {}
-- I know, I know, this file may as well  be named "RandomCodeThatHasNoHome.lua"

DIR_SEP = package.config:sub(1,1)

function utils.keys(t)
  local rt = {}
  for k,_ in pairs(t) do table.insert(rt, k) end
  return rt
end

function string.compare(s1, s2)
  assert(s1 and s2, "string.compare takes two arguments!")
  
  local len = math.min(#s1, #s2)
  
  for i = 1, len do
    local num1 = s1:lower():sub(i,i):byte()
    local num2 = s2:lower():sub(i,i):byte()
    if num1 ~= num2 then
      return num1 < num2 and 1 or -1
    end
  end
  return 0
end

function string.capitalize(s)
  return s:sub(1,1):upper()..s:sub(2)
end

function utils.split(s, sep)
  local t = {}
  local sep = sep or " "..NEWL
  
  -- For every substring made up of non separator characters, add to t
  for i in string.gmatch(s, "[^"..sep.."]+") do table.insert(t, i) end
  return t
end

function utils.stripControlChars(str)
    local s = ""
    for i = 1, str:len() do
  if str:byte(i) >= 32 and str:byte(i) <= 126 then
        s = s .. str:sub(i,i)
  end
    end
    return s
end

function utils.files(dir)
  local s
  if DIR_SEP == "\\" then
    s = io.popen("dir "..dir.." /b /a-d"):read("*all")
  else
    s = io.popen("ls -p "..dir.." | grep -v /"):read("*all")
  end
    
  return utils.split(s)
end

function makeFile(dir)
  os.execute()
end

function string.multimatch(s, patterns)
  for _,v in ipairs(patterns) do
    local capture = s:match(v)
    if capture then return capture end
  end
  return nil
end

-- lua-users.org
function utils.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function utils.deepcopy(value, seen)
  if type(value) == "table" then
    seen = seen or {}
    local t = {}
    for k,v in pairs(value) do
      if seen[v] then
        t[k] = seen[v]
      else
        t[k] = utils.deepcopy(v, seen)
        seen[k] = t[k] 
      end
    end
    return t
  else
    return value
  end
end

-- Bart Kiers @ stackoverflow.com
function utils.case_insensitive_pattern(pattern)

  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)

  return p
end

-- kikito @ stackoverflow.com
function utils.isArray(t)
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end

--resolve identifier chain i.e. object.inventory.items.#1
function utils.resolve(obj, key)
  local k
  local keyparts = utils.split(key, "%.")
  -- for part in key:gmatch("([^%.]+)") do table.insert(keyparts, part) end
  
  for i, part in ipairs(keyparts) do
    local num = part:match("#(%d+)")
    if num then part = tonumber(num) end
    k = part
    if i == #keyparts then break end
    if type(obj[part]) == "table" then
      obj = obj[part]
    elseif i ~= #keyparts then
      return nil
    end
  end
  
  return obj, k
end

function utils.contains(t, i)
  for j,v in ipairs(t) do
    if v == i then return true end
  end
  return false
end

function utils.tremove(t, i)
  for j = #t, 1, -1 do
    if t[j] == i then table.remove(t, j) end
  end
  return t
end

--create proxy table with get/set list

-- TODO: Make it recursive, so any subtables are also proxied. Allow for ACL with resolve syntax
-- e.g. "user.send" = true allows for only the send function to be read from self.user
function makeProxy(t, get, set)
  return setmetatable({}, {
    __index = function(self, k)  
      if get then assert(get[k], "Read-access error in script!") end
      local v = t[k]
      if type(v) == "function" then
        return function(proxy, ...)
          return v(t, ...)
        end
      end
      return v
    end,
    __newindex = function(self, k, v)
      assert(set and type(v):match("^"..set[k]), "Write-access error in script!")
      t[k] = v
    end,
    
  })
end

-- Houshalter @ stackoverflow.com
local oct2bin = {
    ['0'] = '000',
    ['1'] = '001',
    ['2'] = '010',
    ['3'] = '011',
    ['4'] = '100',
    ['5'] = '101',
    ['6'] = '110',
    ['7'] = '111'
}
function getOct2bin(a) return oct2bin[a] end
function num2bin(n)
    local s = string.format('%o', n)
    s = s:gsub('.', oct2bin)
    return s
end


return utils
