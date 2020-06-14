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

config(defaults.server_info, {port="Server port for clients to connect to", motd="Welcome message before users login"})

config(defaults.db_info, {})
config(defaults.world_info, {})

require "utils"
NEWL = "\r\n"
ser = require("world_save").ser

-- write to config.lua
local f = io.open("config.lua", "w")
print(ser(defaults))
f:write("return "..ser(defaults))
f:close()
