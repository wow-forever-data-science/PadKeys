-- Key layout: preview, apply and restore the bindings and console variables
-- in Config.lua, plus the keys of the loaded PadKeys_* addons. The first apply saves what each key and setting was, so
-- restore can put it back. Binding changes are blocked in combat.

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

function ns.apply_layout()
  if blocked() then
    return
  end
  ns.db.keys = ns.db.keys or {}
  ns.db.cvars = ns.db.cvars or {}

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

  for name, value in pairs(ns.config.cvars) do
    if ns.db.cvars[name] == nil then
      ns.db.cvars[name] = C_CVar.GetCVar(name) or ""
    end
    C_CVar.SetCVar(name, tostring(value))
  end
  ns.say("layout applied. /padkeys restore undoes it.")
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

  for name, old in pairs(ns.db.cvars or {}) do
    if old ~= "" then
      C_CVar.SetCVar(name, old)
    end
  end
  ns.db.keys, ns.db.cvars = nil, nil
  ns.say("previous keys and settings restored.")
end
