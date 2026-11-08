-- Key layout: preview, apply and restore the bindings in Config.lua, plus
-- the keys of the loaded PadKeys_* addons. The first apply saves what each
-- key was, so restore can put it back. Binding changes are blocked in
-- combat. Console variables (soft targeting and so on) are not set here:
-- they are defaults in the wow-settings repository.
--
-- Config.lua is the source of truth for these keys: once applied, each
-- login applies the layout again if anything changed one of them (a
-- wow-settings apply of older bindings, a changed Config.lua). After
-- /padkeys restore nothing is applied until the next /padkeys apply.

local _, ns = ...

-- One row per key: the action it gets (false unbinds) and what it has now.
-- Keys an earlier apply took for an addon that is no longer loaded get
-- their saved binding back (released = true), so a disabled PadKeys_*
-- addon leaves no dead keys.
local function planned_changes()
  local rows = {}
  for key, action in pairs(ns.config.bindings) do
    rows[#rows + 1] = { key = key, action = action, old = GetBindingAction(key) }
  end
  for key, saved in pairs(ns.db.keys or {}) do
    if ns.config.bindings[key] == nil then
      rows[#rows + 1] = { key = key, action = saved ~= "" and saved or false,
                          old = GetBindingAction(key), released = true }
    end
  end
  table.sort(rows, function(a, b) return a.key < b.key end)
  return rows
end

local function blocked()
  if InCombatLockdown() then
    ns.say("can't change key bindings in combat.")
    return true
  end
  return false
end

function ns.preview_layout()
  for _, row in ipairs(planned_changes()) do
    local new = row.action or ""
    if row.old ~= new then
      ns.say(format("%s: %s -> %s", row.key,
                    row.old ~= "" and row.old or "(unbound)",
                    new ~= "" and new or "(unbound)"))
    end
  end
end

local function out_of_date()
  for _, row in ipairs(planned_changes()) do
    if row.old ~= (row.action or "") then
      return true
    end
  end
  return false
end

function ns.apply_layout(quiet)
  if blocked() then
    return
  end
  ns.db.keys = ns.db.keys or {}

  for _, row in ipairs(planned_changes()) do
    if row.released then
      ns.db.keys[row.key] = nil
    elseif ns.db.keys[row.key] == nil then
      ns.db.keys[row.key] = row.old
    end
    if row.action then
      SetBinding(row.key, row.action)
    else
      SetBinding(row.key)
    end
  end
  SaveBindings(GetCurrentBindingSet())
  ns.say(quiet and "keys were out of date; layout applied again." or
         "layout applied. /padkeys restore undoes it.")
end

function ns.restore_layout()
  if blocked() then
    return
  end
  if not ns.db.keys then
    ns.say("nothing to restore.")
    return
  end

  for key, old in pairs(ns.db.keys) do
    if old == "" then
      SetBinding(key)
    else
      SetBinding(key, old)
    end
  end
  SaveBindings(GetCurrentBindingSet())
  ns.db.keys = nil
  ns.say("previous keys restored.")
end

-- The client loads the saved bindings around login, so this waits a moment.
local sync = CreateFrame("Frame")
sync:RegisterEvent("PLAYER_LOGIN")
sync:SetScript("OnEvent", function()
  C_Timer.After(1, function()
    if ns.db.keys and not InCombatLockdown() and out_of_date() then
      ns.apply_layout(true)
    end
  end)
end)
