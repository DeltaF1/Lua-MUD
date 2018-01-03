local sql = {}

--[[
function sql.rows(connection, sql_statement)
	if type(connection) == "string" then
		sql_statement = connection
		connection = nil
	end
	local cursor = assert (sql.execute(connection, sql_statement))
	return function()
		return cursor:fetch()
	end
end
]]--

function sql.rows(sql_statement, ...)
	local cursor = assert (sql.execute(sql_statement, ...))
	return function()
		return cursor:fetch()
	end
end

function sql.escape(statement)
	if DB_CON.escape then
		sql.escape = function(statement)
			return DB_CON:escape(stmt)
		end
	else
		sql.escape = function(statement)
			print("NOT IMPLEMENTED")
			return statement
		end
	end
	return sql.escape(statement)
end

--[[
function sql.execute(connection, sql_statement, ...)
	return connection:execute(sql.format(sql_statement, ...));
end
]]--

function sql.execute(sql_statement, ...)
	return DB_CON:execute(sql.format(sql_statement, ...));
end


function sql.format(sql_statement, ...)
	for i = 1,arg.n do
		arg[i] = sql.escape(tostring(arg[i]))
	end
	return string.format(sql_statement, unpack(arg))
end

function sql.get_identifier(table, column)
	
	res, err = sql.execute("INSERT INTO "..table.."(identifier, "..(column or "name")..") VALUES (NULL, '__new')")
	
	if not res then error(err) end
	
	cur = DB_CON:execute("SELECT LAST_INSERT_ID()")
	
	-- print("[sql.get_identifier]")
	-- print(debug.traceback())
	
	identifier = cur:fetch()
	
	cur:close()
	
	return identifier
end

return sql