-- Inspect your debuffs (X) and buffs (Alt+X) with keys, in combat too. Each
-- press shows the tooltip of the next aura icon in Blizzard's DebuffFrame or
-- BuffFrame, in display order and wrapping around, by calling the icon's own
-- OnEnter (AuraButtonMixin), so it looks exactly like hovering it.
--
-- Escape closes the tooltip view. Override bindings can't be changed by
-- addon code in combat, but a secure snippet reacting to a key press can:
-- the X/Alt+X buttons bind Escape (owned by a secure header) to a close
-- button, and the close button clears it again. Outside the tooltip view,
-- Escape works as usual.

local _, ns = ...

local current = {}

local function shown_auras(frame)
  local out = {}
  for _, aura in ipairs(frame and frame.auraFrames or {}) do
    if aura.hasValidInfo and aura:IsShown() then
      out[#out + 1] = aura
    end
  end
  return out
end

local function leave(frame)
  local old = current[frame]
  if old and old.OnLeave then
    old:OnLeave()
  end
  current[frame] = nil
  return old
end

local function step(frame, other)
  leave(other)
  local old = leave(frame)
  local auras = shown_auras(frame)
  local n = #auras
  if n == 0 then
    UIErrorsFrame:AddMessage(frame == DebuffFrame and "No debuffs." or
                               "No buffs.", 1, 0.82, 0)
    return
  end
  local pos = 0
  for i, aura in ipairs(auras) do
    if aura == old then
      pos = i
    end
  end
  pos = pos % n + 1
  current[frame] = auras[pos]
  auras[pos]:OnEnter()
end

local function close()
  leave(DebuffFrame)
  leave(BuffFrame)
end

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

key_button("PadKeysAuraDebuff", CLAIM_ESCAPE,
           function() step(DebuffFrame, BuffFrame) end)
key_button("PadKeysAuraBuff", CLAIM_ESCAPE,
           function() step(BuffFrame, DebuffFrame) end)
key_button("PadKeysAuraClose", RELEASE_ESCAPE, close)
