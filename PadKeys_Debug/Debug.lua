-- Saves every Lua error and blocked action (and notes from the PadKeys
-- addons, PadKeysDebug_Note) to PadKeysDebugDB, so they can
-- be read outside the game in
-- WTF/Account/<account>/SavedVariables/PadKeys_Debug.lua. The game writes
-- that file on /reload and logout. Blizzard's own error display keeps
-- working: the previous error handler still runs.
--
-- It has no dependencies, and the other PadKeys addons list it as an
-- optional dependency, so it loads first and also catches their load
-- errors.

local MAX_ENTRIES = 100
local MAX_TEXT = 4000

-- This session's entries. The saved table replaces the global before
-- ADDON_LOADED; then it gets this table, so earlier errors are kept.
local entries = {}
local by_key = {}

local function clip(text)
  text = text or ""
  if #text > MAX_TEXT then
    return text:sub(1, MAX_TEXT) .. "\n[clipped]"
  end
  return text
end

-- Repeats of one error only count up, so a per-frame error is one entry.
local function record(kind, message, stack, locals)
  local key = kind .. "\0" .. message .. "\0" .. (stack or "")
  local now = date("%Y-%m-%d %H:%M:%S")
  local entry = by_key[key]
  if entry then
    entry.count = entry.count + 1
    entry.last = now
    return
  end
  if #entries >= MAX_ENTRIES then
    return
  end
  entry = {
    kind = kind,
    message = message,
    stack = clip(stack),
    locals = clip(locals),
    count = 1,
    first = now,
    last = now,
    in_combat = InCombatLockdown(),
  }
  by_key[key] = entry
  entries[#entries + 1] = entry
end

local previous = geterrorhandler()
seterrorhandler(function(message, ...)
  pcall(record, "error", tostring(message), debugstack(3), debuglocals(3))
  return previous(message, ...)
end)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:RegisterEvent("MACRO_ACTION_BLOCKED")
events:RegisterEvent("MACRO_ACTION_FORBIDDEN")
events:SetScript("OnEvent", function(_, event, who, action)
  if event == "ADDON_LOADED" then
    if who == "PadKeys_Debug" then
      -- One session per login: the last session is replaced, so the file
      -- only holds what happened since the last /reload or login.
      local _, build = GetBuildInfo()
      PadKeysDebugDB = {
        session = { started = date("%Y-%m-%d %H:%M:%S"), build = build },
        entries = entries,
      }
    end
    return
  end
  record(event, format("%s tried %s", tostring(who), tostring(action)),
         debugstack(2), nil)
end)

-- For the PadKeys addons: note a diagnostic line (kind "note"), e.g.
-- frame sizes, to read from the file like an error.
function PadKeysDebug_Note(message)
  record("note", tostring(message), nil, nil)
end

SLASH_PADKEYSDEBUG1 = "/pkdebug"
SlashCmdList.PADKEYSDEBUG = function(msg)
  if msg == "clear" then
    wipe(entries)
    wipe(by_key)
    print("PadKeys debug: cleared.")
    return
  end
  print(format("PadKeys debug: %d entries this session. /reload to write them to disk; /pkdebug clear to empty.", #entries))
end
