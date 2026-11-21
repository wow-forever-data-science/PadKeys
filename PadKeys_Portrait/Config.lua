-- PadKeys_Portrait settings. Edit, then /reload.

local ns = PadKeys

ns.config.portrait = {
  -- What shows in place of your portrait when you are in no stance, form,
  -- aspect or aura: "class" for your class icon, "face" for Blizzard's
  -- portrait.
  fallback = "class",
  -- Hunter aspects and paladin auras are buffs, read only out of combat
  -- (in combat they are secret); in combat your own casts switch the icon,
  -- and one cancelled in combat shows as combat ends.
  -- false shows stances and forms only.
  buffs = true,
  -- What you are tracking (Find Herbs, Track Beasts, ...) as a badge on
  -- the portrait's lower right; hover it for the name. false for none.
  -- In combat only your own tracking casts change it.
  tracking = true,
  tracking_size = 22,
}
