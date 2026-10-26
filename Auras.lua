-- Inspect your debuffs (and buffs) with keys, in combat too. Each press
-- shows the tooltip of the next aura icon in Blizzard's DebuffFrame or
-- BuffFrame, in display order, by calling the icon's own OnEnter
-- (AuraButtonMixin), so it looks exactly like hovering it. Pressing past
-- the last one hides the tooltip. Tooltips aren't protected, so this works
-- in combat; cancelling buffs is still out of combat only (UI cursor).

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

local function step(frame, delta)
  local auras = shown_auras(frame)
  local old = current[frame]
  if old and old.OnLeave then
    old:OnLeave()
  end
  current[frame] = nil

  local n = #auras
  if n == 0 then
    UIErrorsFrame:AddMessage(frame == DebuffFrame and "No debuffs." or
                               "No buffs.", 1, 0.82, 0)
    return
  end
  -- Positions 1..n are auras; 0 means "tooltip hidden".
  local pos = 0
  for i, aura in ipairs(auras) do
    if aura == old then
      pos = i
    end
  end
  pos = (pos + delta) % (n + 1)
  if pos > 0 then
    current[frame] = auras[pos]
    auras[pos]:OnEnter()
  end
end

-- Called by the key bindings in Bindings.xml.
function ns.next_debuff() step(DebuffFrame, 1) end
function ns.previous_debuff() step(DebuffFrame, -1) end
function ns.next_buff() step(BuffFrame, 1) end
