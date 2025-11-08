-- File: ui/HARDCORE_ChallengesWindow.lua
-- Adds faded background, smaller divider, chalice icons, close button, class icon, and clean two-column layout.
local CM = HARDCORE and HARDCORE.ChallengeManager
local UI = {}
HARDCORE = HARDCORE or {}
HARDCORE.ChallengeUI = UI

-- === Assets ================================================================
local CLASS_ICONS = {
    [1] = "/esoui/art/icons/class/class_dragonknight.dds",
    [2] = "/esoui/art/icons/class/class_sorcerer.dds",
    [3] = "/esoui/art/icons/class/class_nightblade.dds",
    [4] = "/esoui/art/icons/class/class_templar.dds",
    [5] = "/esoui/art/icons/class/class_warden.dds",
    [6] = "/esoui/art/icons/class/class_necromancer.dds",
    [7] = "/esoui/art/icons/class/class_arcanist.dds"
}

local ICON_CHALICE = "/esoui/art/market/keyboard/esoplus_chalice_gold_64.dds"
local DIVIDER_TEX = "/esoui/art/miscellaneous/horizontaldivider.dds" -- cleaner small divider
local BACKGROUND_TEX = "/esoui/art/loadingscreens/loadscreen_brokenlight_temple_01.dds"

-- === Helpers ================================================================
local function classIcon()
    local id = GetUnitClassId("player")
    return CLASS_ICONS[id] or "/esoui/art/achievements/achievement_skills_tabicon_up.dds"
end

local function timeAliveText()
    if not HARDCORE or not HARDCORE.GetChallengeElapsedSeconds then
        return "0m"
    end
    local s = HARDCORE.GetChallengeElapsedSeconds()
    if s < 0 then
        s = 0
    end
    local d = math.floor(s / 86400);
    s = s % 86400
    local h = math.floor(s / 3600);
    s = s % 3600
    local m = math.floor(s / 60)

    if d > 0 then
        return string.format("%dd %dh %dm", d, h, m) -- like /played: days, hours, minutes
    elseif h > 0 then
        return string.format("%dh %dm", h, m)
    else
        return string.format("%dm", m)
    end
end

-- Row (challenge card) -------------------------------------------------------
local function createRow(parent, x, y, width)
    local row = WINDOW_MANAGER:CreateControl(nil, parent, CT_CONTROL)
    row:SetDimensions(width, 84)
    row:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)

    row.title = WINDOW_MANAGER:CreateControl(nil, row, CT_LABEL)
    row.title:SetFont("ZoFontGameBold")
    row.title:SetAnchor(TOPLEFT, row, TOPLEFT, 4, 4)

    -- Points (icon + number)
    row.pointsIcon = WINDOW_MANAGER:CreateControl(nil, row, CT_TEXTURE)
    row.pointsIcon:SetDimensions(22, 22)
    row.pointsIcon:SetTexture(ICON_CHALICE)
    row.pointsIcon:SetAnchor(TOPRIGHT, row, TOPRIGHT, -64, 4)

    row.points = WINDOW_MANAGER:CreateControl(nil, row, CT_LABEL)
    row.points:SetFont("ZoFontGameBold")
    row.points:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    row.points:SetAnchor(LEFT, row.pointsIcon, RIGHT, 6, 0)
    row.points:SetDimensions(54, 22)

    -- Progress bar
    row.barBg = WINDOW_MANAGER:CreateControl(nil, row, CT_BACKDROP)
    row.barBg:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 38)
    row.barBg:SetDimensions(width, 30)
    row.barBg:SetCenterColor(0, 0, 0, 0.45)
    row.barBg:SetEdgeColor(0, 0, 0, 0)

    row.bar = WINDOW_MANAGER:CreateControl(nil, row.barBg, CT_STATUSBAR)
    row.bar:SetAnchor(TOPLEFT, row.barBg, TOPLEFT, 2, 2)
    row.bar:SetDimensions(width - 4, 26)
    row.bar:SetGradientColors(0.25, 0.45, 1, 1, 0.10, 0.20, 0.55, 1)

    row.progressText = WINDOW_MANAGER:CreateControl(nil, row, CT_LABEL)
    row.progressText:SetFont("ZoFontGame")
    row.progressText:SetAnchor(RIGHT, row.barBg, RIGHT, -10, -1)

    return row
end

-- === UI =====================================================================
function UI:Create()
    if self.win then
        return
    end

    local wm = WINDOW_MANAGER
    local win = wm:CreateTopLevelWindow("HARDCORE_ChallengeWindow")
    self.win = win
    win:SetHidden(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetClampedToScreen(true)

    -- Bigger window for spacing
    local WIN_W, WIN_H = 1180, 720
    win:SetDimensions(WIN_W, WIN_H)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, -20)

    -- === BACKGROUND IMAGE (like in HARDCORE.lua) ===
    local inner = win -- same parent
    local bg = wm:CreateControl("HARDCORE_ChallengeBG", inner, CT_TEXTURE)
    bg:SetAnchorFill(inner)
    bg:SetTexture("/esoui/art/loadingscreens/loadscreen_brokenlight_temple_01.dds")
    bg:SetTextureCoords(0, 1, 0, 1)
    bg:SetDrawTier(DT_LOW)
    bg:SetDrawLayer(DL_BACKGROUND)
    bg:SetAlpha(1)
    bg:SetBlendMode(TEX_BLEND_COLOR_ALPHA)
    self.bgTex = bg

    -- Add subtle dark overlay for readability
    local overlay = wm:CreateControl(nil, inner, CT_BACKDROP)
    overlay:SetAnchorFill()
    overlay:SetCenterColor(0, 0, 0, 0.55)
    overlay:SetEdgeColor(1, 1, 1, 0.08)

    -- === Corner ornaments (same style as HARDCORE.lua) ===
    local function Corner(name, tex, anchorPoint, xOff, yOff, w, h)
        local t = wm:CreateControl(name, inner, CT_TEXTURE)
        t:SetTexture(tex)
        t:SetDimensions(w or 16, h or 16)
        t:SetBlendMode(TEX_BLEND_ALPHA)
        t:SetAlpha(0.9)
        t:SetDrawLayer(DL_OVERLAY)
        t:SetDrawLevel(5)
        t:SetAnchor(anchorPoint, inner, anchorPoint, xOff or 0, yOff or 0)
        return t
    end

    Corner("HARDCORE_ChallengeCornerTL", "/esoui/art/reticle/border_topleft.dds", TOPLEFT, -1, -1, 16, 16)
    Corner("HARDCORE_ChallengeCornerTR", "/esoui/art/reticle/border_topright.dds", TOPRIGHT, 1, -1, 16, 16)
    Corner("HARDCORE_ChallengeCornerBL", "/esoui/art/reticle/border_bottomleft.dds", BOTTOMLEFT, -1, 1, 16, 16)
    Corner("HARDCORE_ChallengeCornerBR", "/esoui/art/reticle/border_bottomright.dds", BOTTOMRIGHT, 1, 1, 16, 16)

    -- Close button
    self.close = wm:CreateControlFromVirtual(nil, win, "ZO_CloseButton")
    self.close:SetAnchor(TOPRIGHT, win, TOPRIGHT, -10, 10)
    self.close:SetHandler("OnClicked", function()
        UI:Hide()
    end)

    -- Class icon (top-left)
    self.classIcon = wm:CreateControl(nil, win, CT_TEXTURE)
    self.classIcon:SetDimensions(36, 36)
    self.classIcon:SetAnchor(TOPLEFT, win, TOPLEFT, 16, 14)
    self.classIcon:SetTexture(classIcon())

    -- Header info
    self.header = wm:CreateControl(nil, win, CT_LABEL)
    self.header:SetFont("ZoFontHeader3")
    self.header:SetAnchor(LEFT, self.classIcon, RIGHT, 12, 0)

    self.timeAlive = wm:CreateControl(nil, win, CT_LABEL)
    self.timeAlive:SetFont("ZoFontHeader3")
    self.timeAlive:SetAnchor(TOP, win, TOP, 0, 14)

    -- Player points (icon + number)
    self.pointsGroup = wm:CreateControl(nil, win, CT_CONTROL)
    self.pointsGroup:SetDimensions(160, 32)
    self.pointsGroup:SetAnchor(TOPRIGHT, win, TOPRIGHT, -56, 14)

    self.pointsIcon = wm:CreateControl(nil, self.pointsGroup, CT_TEXTURE)
    self.pointsIcon:SetDimensions(26, 26)
    self.pointsIcon:SetAnchor(LEFT, self.pointsGroup, LEFT, 0, 0)
    self.pointsIcon:SetTexture(ICON_CHALICE)

    self.points = wm:CreateControl(nil, self.pointsGroup, CT_LABEL)
    self.points:SetFont("ZoFontHeader3")
    self.points:SetAnchor(LEFT, self.pointsIcon, RIGHT, 8, 0)

    -- Divider (thin and subtle)
    self.divider = wm:CreateControl(nil, win, CT_TEXTURE)
    self.divider:SetTexture(DIVIDER_TEX)
    self.divider:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 58)
    self.divider:SetDimensions(WIN_W - 40, 8)
    self.divider:SetColor(1, 1, 1, 0.35)

    -- Scroll container
    local CONTENT_W = WIN_W - 24
    self.scroll = wm:CreateControlFromVirtual("$(parent)Scroll", win, "ZO_ScrollContainer")
    self.scroll:SetAnchor(TOPLEFT, win, TOPLEFT, 12, 84)
    self.scroll:SetDimensions(CONTENT_W, WIN_H - 160)
    local list = self.scroll:GetNamedChild("ScrollChild")
    self.list = list

    -- Wider surrender button
    self.surrender = wm:CreateControlFromVirtual(nil, win, "ZO_DefaultButton")
    self.surrender:SetText("Surrender Challenge")
    self.surrender:SetDimensions(520, 40)
    self.surrender:SetAnchor(BOTTOM, win, BOTTOM, 0, -12)
    self.surrender:SetHandler("OnClicked", function()
        if HARDCORE and HARDCORE.SurrenderChallenge then
            HARDCORE.SurrenderChallenge()
        end
    end)

    if CM and CM.On then
        CM:On(function()
            UI:Refresh()
        end)
    end
end
-- Tick header once per second (safe global updater)
EVENT_MANAGER:UnregisterForUpdate("HARDCORE_ChallengeUI_Ticker")
EVENT_MANAGER:RegisterForUpdate("HARDCORE_ChallengeUI_Ticker", 1000, function()
    local ui = HARDCORE and HARDCORE.ChallengeUI
    if not ui or not ui.win or ui.win:IsHidden() then
        return
    end

    -- Lvl
    local lvl = GetUnitLevel("player") or 1
    if ui.header then
        ui.header:SetText(("Lvl %d"):format(lvl))
    end

    -- Time Alive
    if ui.timeAlive then
        ui.timeAlive:SetText(("Time Alive %s"):format(timeAliveText()))
    end

    -- Points
    if ui.points and HARDCORE and HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.GetPoints then
        ui.points:SetText(tostring(HARDCORE.ChallengeManager:GetPoints() or 0))
    end
end)

function UI:Show()
    self:Create()
    self.classIcon:SetTexture(classIcon())
    self.win:SetHidden(false)
    self:Refresh()
end

function UI:Hide()
    if self.win then
        self.win:SetHidden(true)
    end
end

function UI:IsShown()
    return self.win and not self.win:IsHidden()
end

-- Layout config
local COLUMN_GAP = 40
local ROW_HEIGHT = 96

local function contentWidth(self)
    return self.scroll:GetWidth()
end

local function colWidth(self)
    return (contentWidth(self) - COLUMN_GAP) / 2
end

function UI:Refresh()
    if not self.win then
        return
    end

    local lvl = GetUnitLevel("player") or 1
    self.header:SetText(("Lvl %d"):format(lvl))
    self.timeAlive:SetText(("Time Alive %s"):format(timeAliveText()))
    self.points:SetText(tostring(CM and CM:GetPoints() or 0))

    -- rebuild rows
    for _, r in ipairs(self._rows or {}) do
        r:SetHidden(true)
    end
    self._rows = {}

    if not CM then
        return
    end

    local index = 0
    local CW = colWidth(self)
    CM:ForEach(function(id, chal)
        local col = index % 2
        local row = math.floor(index / 2)
        local x = col == 0 and 0 or (CW + COLUMN_GAP)
        local y = row * ROW_HEIGHT

        local card = createRow(self.list, x, y, CW)
        card.title:SetText(chal.title)
        card.points:SetText(tostring(chal.points))

        local cur, max = CM:GetProgress(id)
        local pct = max > 0 and (cur / max) or 0
        card.bar:SetValue(pct * 100)
        card.progressText:SetText(("%d / %d"):format(cur, max))

        local state = CM:GetStatus(id)
        if state == "COMPLETED" then
            card.bar:SetGradientColors(0.1, 0.8, 0.2, 1, 0.05, 0.5, 0.12, 1)
            card.progressText:SetText("Completed")
        elseif state == "FAILED" then
            card.bar:SetGradientColors(0.8, 0.1, 0.1, 1, 0.5, 0.05, 0.05, 1)
            card.progressText:SetText("Failed")
        end

        table.insert(self._rows, card)
        index = index + 1
    end)

    local rows = math.ceil((#self._rows) / 2)
    self.list:SetHeight(rows * ROW_HEIGHT + 10)
end

EVENT_MANAGER:RegisterForEvent("HARDCORE_ChallengeUI_Login", EVENT_PLAYER_ACTIVATED, function()
    if HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive then
        UI:Show()
    end
end)
