-- PadKeys_Auras settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

-- Inspect auras, in combat too: hold a key for the tooltip of the next aura
-- in that group (wrapping around), like hovering it. C
-- replaces the character window (it's on the menu radial, Ctrl+G). ALT is
-- Option on a Mac; on Windows, where Cmd's layer is Alt, pick another key
-- for target debuffs.
local b = ns.config.bindings
b.C = "CLICK PadKeysAura:mydebuffs"
b["CTRL-C"] = "CLICK PadKeysAura:mybuffs"
b["ALT-C"] = "CLICK PadKeysAura:targetdebuffs"
b[ns.config.mod .. "C"] = "CLICK PadKeysAura:targetbuffs"
