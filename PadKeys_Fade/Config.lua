-- PadKeys_Fade settings. Edit, then /reload.

local ns = PadKeys

ns.config.fade = {
  -- Frames that fade together: hovering one shows its whole group. Names
  -- are Blizzard's globals; a name that doesn't exist is skipped. Bars
  -- must be set to "Always" (not "Hidden") in Edit Mode to show on hover.
  groups = {
    bars = {
      "MainActionBar",        -- Action Bar 1 (MainMenuBar on older clients)
      "MultiBarBottomLeft",   -- Action Bar 2
      "MultiBarBottomRight",  -- Action Bar 3
      "MultiBarRight",        -- Action Bar 4
      "MultiBarLeft",         -- Action Bar 5
      "MultiBar5",            -- Action Bar 6
      "MultiBar6",            -- Action Bar 7
      "MultiBar7",            -- Action Bar 8
      "PetActionBar",
      "StanceBar",
      "MainStatusTrackingBarContainer",      -- experience / reputation
      "SecondaryStatusTrackingBarContainer",
    },
    menu = {
      "MicroMenuContainer",
      "BagsBar",
    },
  },
  -- Groups that show while you drag a spell, item, macro or pet action.
  show_while_dragging = { bars = true },
  -- Alpha when faded: 0 is invisible.
  faded_alpha = 0,
  -- Seconds to fade in and out, and to stay after the mouse leaves.
  fade_in = 0.15,
  fade_out = 0.3,
  linger = 0.6,
  -- Extra pixels around each frame that still count as hovering it.
  padding = 10,
  -- A label left of each action bar: its name and the PadKeys key that
  -- fires it ("Bar 2 · Cmd", "Bar 6 · G wheel").
  labels = true,
  label_size = 12,
}
