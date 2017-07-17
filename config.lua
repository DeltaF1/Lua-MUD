return {
	-- CONFIG
	--
	-- Miscellaneous options for the MUD server
	
	-- The port that the server binds to. If this port is taken, the server may bind to another available port, check the console output for the bound port
	port = 5555,
	motd = [[%{red}
 __ __ __    ________  __       ______   ______          
/_//_//_/\  /_______/\/_/\     /_____/\ /_____/\         
\:\\:\\:\ \ \__.::._\/\:\ \    \:::_ \ \\::::_\/_        
 \:\\:\\:\ \   \::\ \  \:\ \    \:\ \ \ \\:\/___/\       
  \:\\:\\:\ \  _\::\ \__\:\ \____\:\ \ \ \\::___\/_      
   \:\\:\\:\ \/__\::\__/\\:\/___/\\:\/.:| |\:\____/\     
    \_______\/\________\/ \_____\/ \____/_/ \_____\/     
 ___   ___   ________   __   __   ______   ___   __      
/__/\ /__/\ /_______/\ /_/\ /_/\ /_____/\ /__/\ /__/\    
\::\ \\  \ \\::: _  \ \\:\ \\ \ \\::::_\/_\::\_\\  \ \   
 \::\/_\ .\ \\::(_)  \ \\:\ \\ \ \\:\/___/\\:. `-\  \ \  
  \:: ___::\ \\:: __  \ \\:\_/.:\ \\::___\/_\:. _    \ \ 
   \: \ \\::\ \\:.\ \  \ \\ ..::/ / \:\____/\\. \`-\  \ \
    \__\/ \::\/ \__\/\__\/ \___/_(   \_____\/ \__\/ \__\/
    
%{blue}
Welcome to the world of Wildehaven, a fantastical land, full of great beauty as
well as great peril. If you are brave enough to journey into the wilds, your
quest begins here.
]],
	-- SQL connection options
	sql_user = "lua_mud",
	sql_host = "localhost",
	sql_port = 3306,
}
