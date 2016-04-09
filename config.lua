return {
	-- CONFIG
	--
	-- Miscellaneous options for the MUD server
	
	-- If this is changed, users file will be useless
	salt = "",
	
	-- The port that the server binds to. If this port is taken, the server may bind to another available port, check the console output for the bound port
	port = 5555,
	motd = "%{green}Welcome to the text-chat-test-server-o-matic-9000"
}