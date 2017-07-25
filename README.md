# Lua-MUD
A MUD framework written in lua

## What is this?
This is a framework written in lua, designed to be the server-side of a MUD (Multi User Dungeon). MUD's were most popular in the 90's, when compter graphics were, for the most part, limited to text on a console. Most muds are a combination of a text adventure and a TCP chat server, and allow for player-player interactions in a text only environment.

##What dependencies does this have?
Currently runs on Lua 5.1
Requires a MySQL server for storage.

## How do I use this?
1. Download or clone the source
2. Make sure that lua is installed and in your path
3. Setup the MySQL server with the example schema
4. Run 'lua main.lua' inside the source directory, and take note of the port it is bound to. Players can connect to the server via telnet, or via any one of a number of pre-existing MUD clients.
