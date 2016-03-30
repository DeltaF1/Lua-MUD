-- I know, I know, this file may as well  be named "RandomCodeThatHasNoHome.lua"

DIR_SEP = package.config:sub(1,1)

print(DIR_SEP)

EDITOR_KEYWORDS = {"and", "break", "do", "else", "elseif",
     "end", "false", "for", "function", "if",
     "in", "local", "nil", "not", "or",
     "repeat", "return", "then", "true", "until", "while"}

function keys(t)
	local rt = {}
	for k,_ in pairs(t) do table.insert(rt, k) end
	return rt
end

function string.compare(s1, s2)
	assert(s1 and s2, "string.compare takes two arguments!")
	
	local len = math.min(#s1, #s2)
	
	for i = 1, len do
		local num1 = s1:sub(i,i):byte()
		local num2 = s2:sub(i,i):byte()
		if num1 ~= num2 then
			return num1 < num2 and 1 or -1
		end
	end
	return 0
end

function split(s, sep)
	local t = {}
	local sep = sep or " "..NEWL
	
	-- For every substring made up of non separator characters, add to t
	for i in string.gmatch(s, "[^"..sep.."]+") do table.insert(t, i) end
	return t
end

function files(dir)
	local s
	if DIR_SEP == "\\" then
		s = io.popen("dir "..dir.." /b /a-d"):read("*all")
	else
		s = io.popen("ls -p "..dir.." | grep -v /"):read("*all")
	end
		
	return split(s)
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
function shallowcopy(orig)
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

-- Bart Kiers @ stackoverflow.com
function case_insensitive_pattern(pattern)

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
function isArray(t)
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end

function resolve(obj, key)
	local k
	local keyparts = {}
	for part in key:gmatch("([^%.]+)") do table.insert(keyparts, part) end
	
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

contains = function (t, i)
	for j,v in ipairs(t) do
		if v == i then return true end
	end
	return false
end

tremove = function(t, i)
	for j = #t, 1, -1 do
		if t[j] == i then table.remove(t, j) end
	end
	return t
end


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