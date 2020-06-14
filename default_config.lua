return {
	server_info = {
		port = 5555,
		motd = ([[
%{red}
THIS IS THE MESSAGE THAT WILL BE SENT AS THE FIRST TEXT BEFORE LOGGING IN.
%{reset}%{blue}
THE COLOUR CAN BE MANIPULATED THROUGH COLOUR CODES.
]]):gsub("\n", "NEWL"),

	},
  db_info = {
    dataDir = "data",
    backupDataDir = "data.bak",
  },
  world_info = {
    starting_room = 1,
  },
}
