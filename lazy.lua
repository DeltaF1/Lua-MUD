local load = function(tbl, id)
	db.update_object(id, tbl)
end

local lazy = {

	__index = function(tbl, index)
		load(tbl, tbl.__id)
    print("tbl loaded")
    print(tbl.name)
    error()
    return "GARBAGE"
	end,
	__newindex = function(tbl, index, val)
		load(tbl, tbl.__id)
    print("tbl loaded")
    print(tbl.name)
		error()
	end,
	__ipairs = function(tbl)
		load(tbl, tbl.__id)
    print("tbl loaded")
    print(tbl.name)
		error()
		return ipairs(tbl)
	end,
	__pairs = function(tbl)
		load(tbl, tbl.__id)
    print("tbl loaded")
    print(tbl.name)
		error()
		return pairs(tbl)
	end,
}

return function(id)
	return db.get_or_load(id)
  --return setmetatable({__id=id}, lazy)
end
