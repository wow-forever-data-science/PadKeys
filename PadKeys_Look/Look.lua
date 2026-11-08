-- The PadKeys look beyond PadKeys' own frames (ns.config.look):
--
-- * Every font object in the game takes the theme font, keeping its size
--   and outline. Blizzard's text uses font objects, so this reaches
--   windows, chat and tooltips without touching a frame. Addons that load
--   later (professions, trainers) bring new font objects, so this runs
--   again on every ADDON_LOADED.
-- * Names and damage numbers above heads are drawn by the game from the
--   UNIT_NAME_FONT and DAMAGE_TEXT_FONT globals, read once at login.
-- * Chat windows get a black background, saved in the game's own chat
--   window settings (SetChatWindowColor / SetChatWindowAlpha), so
--   Blizzard's fade on mouseover keeps working. Blizzard's FCF_SetWindow*
--   functions aren't called: they store the alpha on the chat frame, which
--   taints Blizzard's chat fade. The colour shows at once; Blizzard reads
--   the saved alpha when the chat loads, so a changed chat_alpha shows
--   after the next /reload.
--
-- Nothing here is secure: fonts and colours only.

local ns = PadKeys
local c = ns.config.look
local font = ns.config.theme.font

local function restyle_fonts()
  for _, name in ipairs(GetFonts()) do
    local object = _G[name]
    if object and object.GetFont then
      local file, size, flags = object:GetFont()
      if file and file ~= font then
        object:SetFont(font, size, flags or "")
      end
    end
  end
end

-- The textures FCF_SetWindowColor colours, without its writes to the frame.
local function paint_black(name)
  for _, part in pairs(CHAT_FRAME_TEXTURES or {}) do
    local object = _G[name .. part]
    if object and object:GetObjectType() == "Button" then
      object:GetNormalTexture():SetVertexColor(0, 0, 0)
      object:GetHighlightTexture():SetVertexColor(0, 0, 0)
      object:GetPushedTexture():SetVertexColor(0, 0, 0)
    elseif object and object:GetObjectType() == "Texture" then
      object:SetVertexColor(0, 0, 0)
    end
  end
end

local function black_chat()
  for _, name in ipairs(CHAT_FRAMES or {}) do
    local frame = _G[name]
    if frame then
      SetChatWindowColor(frame:GetID(), 0, 0, 0)
      SetChatWindowAlpha(frame:GetID(), c.chat_alpha)
      paint_black(name)
    end
  end
end

if c.game_font then
  UNIT_NAME_FONT = font
  DAMAGE_TEXT_FONT = font
  restyle_fonts()
end

local owner = CreateFrame("Frame", "PadKeysLookOwner", UIParent)
owner:RegisterEvent("ADDON_LOADED")
owner:RegisterEvent("PLAYER_LOGIN")
owner:SetScript("OnEvent", function(_, event)
  if event == "ADDON_LOADED" then
    if c.game_font then
      restyle_fonts()
    end
  elseif c.chat_alpha then
    black_chat()
    -- New windows (whispers, a new tab) and a chat reset start in
    -- Blizzard's default colour.
    hooksecurefunc("FCF_OpenTemporaryWindow", black_chat)
    hooksecurefunc("FCF_OpenNewWindow", black_chat)
    hooksecurefunc("FCF_ResetChatWindows", black_chat)
  end
end)
