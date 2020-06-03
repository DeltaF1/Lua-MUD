# Lua-MUD
A MUD framework written in lua

## What is this?
This is a framework written in lua, designed to be the server-side of a [MUD (Multi User Dungeon)](https://en.wikipedia.org/wiki/MUD). MUD's were most popular in the 90's, when compter graphics were, for the most part, limited to text on a console. Most muds are a combination of a text adventure and a TCP chat server.

## What dependencies does this have?
NOTE: SQL support is currently deprecated in favour of flat file storage. The db api may be rewritten to use SQL libraries again in the future
- ~~[LuaSQL](https://keplerproject.github.io/luasql/) with an appropriate driver installed~~
- ~~e.g. for SQLite3 run `luarocks install luasql-sqlite3`~~

## How do I use this?
1. Download or clone the source
2. Make sure that lua is installed and in your path
3. Setup your world files
  - Rename data/1.lua.example to data/1.lua for a 1-room world example OR
  - Load in the data/ directory from an existing world
4. Run 'lua main.lua' inside the source directory, and take note of the port it is bound to. Players can connect to the server via telnet, or via any one of a number of pre-existing MUD clients.
