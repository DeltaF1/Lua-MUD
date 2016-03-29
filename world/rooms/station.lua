-- station.lua

closet = {
  players = {
  },
  identifier = "closet",
  name = "Broom Closet",
  exits = {
    south = "starting",
  },
  objects = {
  },
  filename = "station.lua",
  desc = "A single lightbulb swings on a naked wire, casting sharp shadows on a shelf of cleaning fluids.",
}

starting = {
  players = {
  },
  identifier = "starting",
  desc = "As your eyes adust to the dim lighting, you can see rough stone walls all around, with a low vaulted ceiling. On the north wall is a wooden door. A ladder hangs down from above. To the west you can see a small stone alcove",
  objects = {
    [1] = {
      aliases = {
      },
      name = "sign",
      desc = "The sign reads: Welcome to the server! an exits command will be added, but for now you can go north, west, or up",
    },
  },
  filename = "station.lua",
  exits = {
    up = "tavern_ground_floor",
    north = "closet",
    west = "arcane_alcove",
  },
  do_enter = "return function(self, player, dir) Room.do_enter(self, player, dir); local t = {\"A cold breeze brushes past your cheeks\", \"The torches on the walls flicker for a moment, but the air is still\", \"You feel a drop of water fall from above, and trickle down your back\"}; local msg = t[math.random(#t)]; if msg then player:send(NEWL); player:send(msg); end; end",
  name = "Starting",
}

--[[END OF FILE]]--