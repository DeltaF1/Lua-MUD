local load = function(tbl, id)
  setmetatable(tbl, nil)
  tbl.__id = nil
  db.update_object(tbl, id)
end

lazy_mt = {

	__index = function(tbl, index)
		load(tbl, tbl.__id)
    return tbl[index]
	end,
	__newindex = function(tbl, index, val)
		load(tbl, tbl.__id)
    tbl[index] = val
	end,
	__ipairs = function(tbl)
		load(tbl, tbl.__id)
		return ipairs(tbl)
	end,
	__pairs = function(tbl)
		load(tbl, tbl.__id)
		return pairs(tbl)
	end,
}

return function(id)
  return setmetatable({__id=id}, lazy_mt)
end
