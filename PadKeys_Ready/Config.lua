-- PadKeys_Ready settings. Edit, then /reload.

local ns = PadKeys

ns.config.ready = {
  -- Where it flashes. "cursor": above the mouse pointer, just outside
  -- the swing ring (PadKeys_Readout; its icon's centre x, y from the
  -- pointer, positive y is up; the name above it). "center": x, y from
  -- the middle of the screen, e.g. y = 70. PadKeys_NotReady flashes
  -- under it, at y = 44 from the pointer. The same size as that flash,
  -- a little bigger than the icons around the pointer.
  anchor = "cursor",
  size = 42,
  x = 0,
  y = 90,
  -- Seconds the icon stays at full strength, then seconds to fade out.
  hold = 0.5,
  fade_out = 0.8,
  -- The spell's name under the icon, and its size.
  label = true,
  label_size = 14,
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,

  -- Reactive abilities: they flash as they become usable (after a dodge,
  -- a block, a parry, or a target under 20% health). Names as the
  -- spellbook shows them, in your client's language. Fire Nova is usable
  -- only with a fire totem down, and its cooldown is under cooldown_min:
  -- it flashes as you drop a fire totem with it ready, or as it comes
  -- back with one down.
  reactive = {
    "Overpower", "Revenge", "Execute", "Riposte", "Counterattack",
    "Mongoose Bite", "Victory Rush", "Hammer of Wrath", "Kill Shot",
    "Fire Nova", "Fire Nova Totem",
  },

  -- Cooldowns: any spell or item on your action bars flashes as it comes
  -- back, if its cooldown lasted at least this many seconds. 0 turns it off.
  cooldown_min = 30,
  -- Names that never flash as their cooldown ends (e.g. "Hearthstone").
  ignore = { "Hearthstone" },
  -- Only in combat, or with an enemy targeted. false flashes them always.
  only_when_fighting = true,
}
