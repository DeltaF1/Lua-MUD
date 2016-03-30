-- misc.lua

mech_1 = {
  players = {
  },
  identifier = "mech_1",
  desc = "A large metallic frame, holding {name} within",
  objects = {
  },
  room = "starting",
  filename = "misc.lua",
  do_look = "return function(self, player) return \"Through the cockpit you see...\".. NEWL .. self.room:do_look(player) end",
  exits = {
    out = "starting",
  },
  name = "Mech",
}

arcane_alcove = {
  players = {
  },
  identifier = "arcane_alcove",
  name = "Arcane Alcove",
  exits = {
    east = "starting",
  },
  objects = {
    [1] = "arcane_candle",
  },
  filename = "misc.lua",
  desc = "Set aside from the other rooms, this space is dimly lit, save for a small flickering candle. The stonework seems to dance in the candelight, and strange runes fade in and out of view. To the east is the starting zone.",
}

--[[END OF FILE]]--