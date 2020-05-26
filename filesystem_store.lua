local t = {}

-- TODO: pull from args table
local PREFIX = "data/"

local function generate_filename(id)
	return PREFIX..tostring(id)..".lua"
end

-- This table serves as an Out-Of-Band way to denote references to otheir entities
local foreign_metatable = {}
-- This env will be used to load the data file
--
-- Any malicious code will have no access to functions like 
local env = {
	-- In the future if multiple tables come back, then the
	-- table could be passed as a second parameter to ID
	ID = function(value)
		return setmetatable({value}, foreign_metatable)
	end,
}

local lazy = require "lazy"

function t.get_lazy(id)
	if not objects[id] then
	  objects[id] = lazy(id)
  end
  return objects[id]
end

local function resolve_refs(object, seen)
	local seen = seen or {}
	for k,v in pairs(object) do
		if getmetatable(v) == foreign_metatable then
			v = v[1]
      object[k] = t.get_lazy(v)
		elseif type(v) == "table" and not seen[v] then
			seen[v] = true
			resolve_refs(v)
		end
	end
end

local function load_file(filename) --> object
	-- loadfile takes in a "mode" paramter. If precompiled bytecode is preferable then change to "bt"
  local f = loadfile(filename, "t", env)
  if f then return f()
  else return f end
end

local load_scripts = require "scripts"

function t.load_object(identifier)
	-- Assert that the identifier is a number
	--
	-- If identifier were a string then loadfile might
	-- execute a path traversal attack
	assert(type(identifier) == "number")
	local data = load_file(generate_filename(identifier))
  if not data then return nil end

  data.identifier = identifier

	resolve_refs(data)

  data = Object:new(data)
  data:call("onLoad")
  -- FIXME data:on_load()?
  if data.players then data.players = {} end

	return data
end

-- TODO:
--
-- Define explicit ephemeral storage (that might persist a soft reload such as this)
function t.reload(object, id)
  id = id or object.identifier

  -- clear
  for k,v in pairs(object) do
    object[k] = nil
  end
  t.update_object(object, id)
end

function t.update_object(object, id)
	id = id or object.identifier
  local loaded = t.load_object(id)
	if not loaded then return nil end
  for k,v in pairs(loaded) do
		object[k] = v
	end
  object = Object:new(object)
  return object
end

function t.get_or_load(id)
	if not objects[id] then
		objects[id] = {}
		t.update_object(objects[id], id)
	end
	return objects[id]
end

local function id_exists(id)
	local f = io.open(generate_filename(id))
	if f then
		f:close()
		return true
	end
end

local function write(obj, filename)
	local f = io.open(filename, "w")
	f:write("return "..ser(obj))
	f:close()
end

function t.store_object(object)
	if not object.identifier then
		print("object doesn't have id!")
    print(ser(object))
    object.identifier = t.reserve_id()

	end
	write(object, generate_filename(object.identifier))
	return object.identifier
end

local function get_max()
	local f = io.open(PREFIX.."max_id.txt", "r")
	local max = f:read("*number")
	f:close()
	return max
end

function t.reserve_id()
	local max = get_max()	
	max = max + 1

	f = io.open(PREFIX.."max_id.txt", "w")
	f:write(tostring(max))
	f:close()
	return max
end

function t.get_user(name)
	local users = loadfile(PREFIX.."users.lua", "t", {})()

	return users[name]
end

function t.add_character(name, object)
  local id = object.identifier
	local users = loadfile(PREFIX.."users.lua", "t", {})()

	table.insert(users[name].characters, id)

	write(users, PREFIX.."users.lua")
end

return t
