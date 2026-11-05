-- Inspect auras with keys, in combat too. One key per group (Config.lua):
-- your debuffs, your buffs, your target's debuffs, your target's buffs.
-- Each press shows the next aura of that group, wrapping around, in
-- Blizzard's own aura tooltip (GameTooltip:SetUnitAura, what hovering an
-- aura shows), with a line saying which one it is ("Target debuff 2/5").
--
-- It reads the auras from the unit, not from the aura icons, so it works
-- the same for you and your target (Forever's target aura icons are
-- private frames).
--
-- Escape closes the tooltip view. Override bindings can't be changed by
-- addon code in combat, but a secure snippet reacting to a key press can:
-- the aura key binds Escape (owned by a secure header) to a close button,
-- and the close button clears it again. Outside the tooltip view, Escape
-- works as usual.

local ns = PadKeys

BINDING_HEADER_PADKEYS_AURAS = "PadKeys: auras"
_G["BINDING_NAME_CLICK PadKeysAura:mydebuffs"] = "Inspect your next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:mybuffs"] = "Inspect your next buff"
_G["BINDING_NAME_CLICK PadKeysAura:targetdebuffs"] = "Inspect target's next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:targetbuffs"] = "Inspect target's next buff"

-- The click's button name is the group.
local GROUPS = {
  mydebuffs = { unit = "player", filter = "HARMFUL", name = "Your debuff", anchor = "DebuffFrame" },
  mybuffs = { unit = "player", filter = "HELPFUL", name = "Your buff", anchor = "BuffFrame" },
  targetdebuffs = { unit = "target", filter = "HARMFUL", name = "Target debuff", anchor = "TargetFrame" },
  targetbuffs = { unit = "target", filter = "HELPFUL", name = "Target buff", anchor = "TargetFrame" },
}

local MAX_AURAS = 40

-- What is showing: the group and the aura index in it.
local shown_group, shown_index

local function count_auras(unit, filter)
  local n = 0
  while n < MAX_AURAS and C_UnitAuras.GetAuraDataByIndex(unit, n + 1, filter) do
    n = n + 1
  end
  return n
end

local function close()
  if shown_group then
    GameTooltip:Hide()
  end
  shown_group, shown_index = nil, nil
end

local function show(group_name)
  local group = GROUPS[group_name]
  if not group then
    return
  end
  if group.unit == "target" and not UnitExists("target") then
    close()
    UIErrorsFrame:AddMessage("No target.", 1, 0.82, 0)
    return
  end
  local n = count_auras(group.unit, group.filter)
  if n == 0 then
    close()
    UIErrorsFrame:AddMessage("No " .. group.name:lower() .. "s.", 1, 0.82, 0)
    return
  end
  -- The same key steps on; another key starts its group at the first aura.
  local index = 1
  if shown_group == group_name and shown_index then
    index = shown_index % n + 1
  end
  shown_group, shown_index = group_name, index

  local anchor = _G[group.anchor] or UIParent
  GameTooltip:SetOwner(anchor, "ANCHOR_BOTTOMLEFT")
  GameTooltip:SetUnitAura(group.unit, index, group.filter)
  GameTooltip:AddLine(format("%s %d/%d", group.name, index, n), 0.6, 0.6, 0.6)
  GameTooltip:Show()
end

-- A new target makes a target aura view stale.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
  if shown_group and GROUPS[shown_group].unit == "target" then
    close()
  end
end)

local header = CreateFrame("Frame", "PadKeysAuraHeader", UIParent,
                           "SecureHandlerBaseTemplate")

local function key_button(name, snippet, func)
  local button = CreateFrame("Button", name, UIParent,
                             "SecureActionButtonTemplate")
  button:RegisterForClicks("AnyDown")
  SecureHandlerWrapScript(button, "OnClick", header, snippet)
  button:HookScript("OnClick", func)
  return button
end

-- Restricted snippets: owner is the header, which owns the Escape binding.
local CLAIM_ESCAPE = [[ owner:SetBindingClick(true, "ESCAPE", "PadKeysAuraClose") ]]
local RELEASE_ESCAPE = [[ owner:ClearBindings() ]]

key_button("PadKeysAura", CLAIM_ESCAPE, function(_, group) show(group) end)
key_button("PadKeysAuraClose", RELEASE_ESCAPE, close)
