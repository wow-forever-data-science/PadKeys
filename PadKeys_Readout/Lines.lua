-- A thin white line from the cast ring to each group of icons around the
-- pointer while it shows (Config.lua, readout.lines), so the eye finds
-- its way out from the ring: big cooldowns, tracked buffs, totems,
-- debuffs, your pet and boss rows.
--
-- Each line runs from the ring's edge towards the group's nearest point
-- and stops there. Only frame geometry and shown state are read (plain
-- values, never secret); Blizzard's docked frames are only looked at, as
-- in Dock.lua. Lines are textures of the readout, so they follow the
-- pointer and are covered with it.

local ns = PadKeys
local c = ns.config.readout
local l = c.lines
local readout = PadKeysReadout
if not (l and l.enabled and readout and readout.CreateLine) then
  return
end

local UPDATE_INTERVAL = 0.05
local radius = (c.ring and c.ring.size or 56) / 2 + (l.gap or 2)

-- Whether a frame has a shown descendant within `depth` levels: an empty
-- Blizzard viewer stays shown with its icons hidden.
local function any_shown(frame, depth)
  for _, child in ipairs({ frame:GetChildren() }) do
    if child:IsShown() and (depth <= 1 or child:GetNumChildren() == 0 or
                            any_shown(child, depth - 1)) then
      return true
    end
  end
  return false
end

-- A frame's rect around the readout's centre, in the readout's scale.
local function rect(frame)
  local left, bottom, width, height = frame:GetRect()
  if not left then
    return nil
  end
  local s = frame:GetEffectiveScale() / readout:GetEffectiveScale()
  local cx, cy = readout:GetCenter()
  left, bottom = left * s - cx, bottom * s - cy
  return left, bottom, left + width * s, bottom + height * s
end

-- Each group: how to find its rect while it shows.
-- "children": the shown icons of a 1-pixel container (Big, Totems);
-- "self": the frame while it shows (pet, a boss row);
-- "docked": a Blizzard frame with a shown icon in it.
local GROUPS = {
  { "PadKeysReadoutBig", "children" },
  { "PadKeysReadoutTotems", "children" },
  { "PadKeysReadoutPet", "self" },
  { "BuffIconCooldownViewer", "docked", c.buffs },
  { "DebuffFrame", "docked", c.debuffs },
}
local boss_frames = {}
for i = 1, c.boss_rows or 3 do
  boss_frames[i] = "PadKeysReadoutBoss" .. i
end
table.insert(GROUPS, { boss_frames, "self", c.boss })

-- The union of the shown parts of a group, or nil.
local function group_rect(names, kind)
  local l0, b0, r0, t0
  local function add(frame)
    local left, bottom, right, top = rect(frame)
    if left then
      l0 = math.min(l0 or left, left)
      b0 = math.min(b0 or bottom, bottom)
      r0 = math.max(r0 or right, right)
      t0 = math.max(t0 or top, top)
    end
  end
  for _, name in ipairs(type(names) == "table" and names or { names }) do
    local frame = _G[name]
    if frame and frame:IsVisible() then
      if kind == "children" then
        for _, child in ipairs({ frame:GetChildren() }) do
          if child:IsShown() then
            add(child)
          end
        end
      elseif kind == "self" or any_shown(frame, 2) then
        add(frame)
      end
    end
  end
  return l0, b0, r0, t0
end

local function clamp(v, low, high)
  return math.max(low, math.min(v, high))
end

for _, group in ipairs(GROUPS) do
  local line = readout:CreateLine(nil, "BACKGROUND")
  line:SetColorTexture(1, 1, 1, l.alpha or 0.6)
  line:SetThickness(l.thickness or 1)
  line:Hide()
  group.line = line
end

local function update()
  for _, group in ipairs(GROUPS) do
    local line = group.line
    local ok, left, bottom, right, top = false, nil, nil, nil, nil
    if group[3] ~= false then
      ok, left, bottom, right, top = pcall(group_rect, group[1], group[2])
    end
    local x, y, dist
    if ok and left then
      -- The group's nearest point to the pointer.
      x, y = clamp(0, left, right), clamp(0, bottom, top)
      dist = math.sqrt(x * x + y * y)
    end
    local stop = dist and dist - (l.gap or 2)
    if stop and stop > radius then
      local dx, dy = x / dist, y / dist
      line:SetStartPoint("CENTER", readout, dx * radius, dy * radius)
      line:SetEndPoint("CENTER", readout, dx * stop, dy * stop)
      line:Show()
    else
      line:Hide()
    end
  end
end

local timer = CreateFrame("Frame")
local since = 0
timer:SetScript("OnUpdate", function(_, elapsed)
  since = since + elapsed
  if since >= UPDATE_INTERVAL then
    since = 0
    update()
  end
end)
