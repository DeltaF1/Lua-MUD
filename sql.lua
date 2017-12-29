-- (Hint, sql credentials are found in config.lua)

local sql = {}

function sql.rows(connection, sql_statement)
	local cursor = assert (connection: execute (sql_statement))
	return function()
		return cursor:fetch()
	end
end

function sql.run_query(query_string)
	-- escape the string
	-- execute on DB_CON
end

function sql.get_identifier(table, column)
	
	-- NOTE: Possible SQL Injection here, no reason to ever call get_identifier without a hardcoded input
	res, err = DB_CON:execute("INSERT INTO "..table.."(identifier, "..(column or "name")..") VALUES (NULL, '__new')")
	
	if not res then error(err) end
	
	cur = DB_CON:execute("SELECT LAST_INSERT_ID()")
	
	-- print("[sql.get_identifier]")
	-- print(debug.traceback())
	
	identifier = cur:fetch()
	
	cur:close()
	
	return identifier
end

return sql