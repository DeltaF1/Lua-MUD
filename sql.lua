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
		local row = {}
		cursor:fetch(row)
		if #row == 0 then
			return nil
		end
		-- A workaround to deal with the MySQL driver returning everything as strings. This would be way faster in the driver,
		-- but you work with what you're given. This can probably be optimized, some profiling will be necessary
		
		-- TODO: Profile this part of the code
		
		local types = cursor:getcoltypes()
		
		--print("SQL given types")
		for i = 1,#types do
			--print("coltype:",types[i],"value:", row[i])
			-- if it's a number
			if types[i]:sub(1,1) == "n" then
				row[i] = tonumber(row[i])
			end
		end
		
		--print("Lua types")
		--for i = 1,#row do
			--print("luatype:",type(row[i]),"value:",row[i])
		--end
		
		return unpack(row)
	end
end

function sql.escape(statement)
	if DB_CON.escape then
		sql.escape = function(stmt)
			return DB_CON:escape(stmt)
		end
	else
		sql.escape = function(statement)
			if type(statement) ~= "string" then
				return statement
			end
			-- print("NOT IMPLEMENTED")
			-- FIXME: vulnerable to injection still...
			--return statement:gsub("(\x00)", "\\%1"):gsub("(\n)", "\\%1"):gsub(
			--"(\r)", "\\%1"):gsub("(')", "\\%1"):gsub("(\")", "\\%1"):gsub("(\x1a)", "\\%1"):gsub("([^\\])(\\)([^\\])", "%1\\%2%3"):gsub(
			--"([^\\])(\\)$", "%1\\%2")
			return statement:gsub("([^\\])(')", "%1\\%2"):gsub("([^\\])(\")", "%1\\%2")
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
	local arg = {...}
	for i = 1, #arg do
		arg[i] = sql.escape(arg[i])
	end
	return string.format(sql_statement, unpack(arg))
end

function sql.get_identifier(table, column)
	
	res, err = sql.execute("INSERT INTO %s (identifier, %s) VALUES (NULL, '__new')",table, column or "name")
	
	if not res then error(err) end
	
	cur = DB_CON:execute("SELECT LAST_INSERT_ID()")
	
	-- print("[sql.get_identifier]")
	-- print(debug.traceback())
	
	identifier = cur:fetch()
	
	cur:close()
	
	return tonumber(identifier)
end

return sql
