# Lua-MUD
A MUD framework written in lua

## What is this?
This is a framework written in lua, designed to be the server-side of a MUD (Multi User Dungeon). MUD's were most popular in the 90's, when compter graphics were, for the most part, limited to text on a console. Most muds are a combination of a text adventure and a TCP chat server, and allow for player-player interactions in a text only environment.

## Why make this?
I really enjoy these kinds of games, and the systems behind them are often very interesting, requiring a wide breadth of programming knowledge to design. This project has a lot of different components interacting together, such as a tcp/ip server, object (de)serialization methods, player state management, and security measures to prevent cheating or server destruction.

## How do I use this?
1. Download or clone the source
  1. After downloading, create a directory called "rooms" in the source directory, and build some [room files](https://github.com/DeltaF1/Lua-MUD/wiki/Room-Files). This directory will be added into the full source shortly, once I have building tools available to create some demo room files.
2. Make sure that lua is installed and in your path
3. Run 'lua main.lua' inside the source directory, and take note of the port it is bound to. Players can connect to the server via telnet, or via any one of a number of pre-existing MUD clients.
