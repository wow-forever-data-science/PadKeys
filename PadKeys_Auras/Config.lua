-- PadKeys_Auras settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

-- Inspect auras, in combat too: a press shows the tooltip of the next aura
-- in that group (wrapping around) at the aura, and it fades. C
-- replaces the character window (it's on the menu radial, Ctrl+G). ALT is
-- Option on a Mac; on Windows, where Cmd's layer is Alt, pick another key
-- for target debuffs.
local b = ns.config.bindings
b.C = "CLICK PadKeysAura:mydebuffs"
b["CTRL-C"] = "CLICK PadKeysAura:mybuffs"
b["ALT-C"] = "CLICK PadKeysAura:targetdebuffs"
b[ns.config.mod .. "C"] = "CLICK PadKeysAura:targetbuffs"

ns.config.auras = {
  -- Shortest time left first, auras without a duration last. false keeps
  -- Blizzard's order (roughly the order they were applied).
  shortest_first = true,
  -- Seconds without a press before the next press starts at the first
  -- aura again.
  reset_after = 3,
  -- Seconds a tooltip stays before it fades.
  show_for = 3,
}
