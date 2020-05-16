print("If you have not already done so, please set up your SQL server with the provided schema.sql")

defaults = require "default_config" 


fancy = {
	sql_driver = "Database driver [mysql, sqlite3]",
	sql_db = "Database name",

	sql_user = "Database admin username",
	sql_host = "Database server host",
	sql_port = "Database server port",
	sql_pass = "Database admin password",

}

function config(table, legend)
	for k,v in pairs(table) do
		local fancy = legend[k] or k
		io.write(fancy.."(default: "..v.."): ")
		val = io.read("*l")
		if val:len() > 0 then
			table[k] = val
		end
	end
end

config(defaults.sql_params, fancy)

-- attempt to connect to database
--
-- Ask for admin username/password

config(defaults.server_info, {port="Server port for clients to connect to", motd="Welcome message before users login"})

function ser(table)
	if type(table) == "table" then
		local s = "{"
		for k,v in pairs(table) do
			s = s..("[%q]=%s,"):format(k,ser(v))
		end
		return s.."}"
	else
		return "[["..tostring(table).."]]"
	end
end

-- write to config.lua
local f = io.open("config.lua", "w")
print(ser(defaults))
f:write("return "..ser(defaults))
f:close()
