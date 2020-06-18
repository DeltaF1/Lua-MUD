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

-- create missing dirs
-- TODO: add windows-compatible version of this
os.execute("mkdir " .. defaults.db_info.dataDir)
os.execute("mkdir " .. defaults.db_info.backupDataDir)

-- load in some helper files
require "utils"
NEWL = "\r\n"
ser = require("world_save").ser

-- Setup Admin
db = require("filesystem_store")(defaults.db_info.dataDir)

io.write("Admin Username: ")
adminname = io.read("*l")
io.write("Admin password: ")
adminpass = io.read("*l")

db.add_user(adminname, adminpass)

defaults.admin_name = adminname

-- write to config.lua
local f = io.open("config.lua", "w")
print(ser(defaults))
f:write("return "..ser(defaults))
f:close()

