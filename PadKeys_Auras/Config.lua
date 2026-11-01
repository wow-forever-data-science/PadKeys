-- PadKeys_Auras settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

-- Inspect your auras, in combat too: each press shows the next tooltip
-- (wrapping around); Escape closes the tooltip view. C replaces the
-- character window (it's on the radial's centre page). ALT is Option on a
-- Mac.
ns.config.bindings.C = "CLICK PadKeysAuraDebuff:LeftButton"
ns.config.bindings["ALT-C"] = "CLICK PadKeysAuraBuff:LeftButton"
