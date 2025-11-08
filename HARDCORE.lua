--[[
File: HARDCORE/HARDCORE.lua
Author: You + ChatGPT
Description: Polished UI for the "HARDCORE" addon. Two-column grid, consistent icons,
             tooltips, framed backdrop, subtle animation. First-load popup & /hc.
]] local ADDON_NAME = "HARDCORE"
HARDCORE = HARDCORE or {} -- make GLOBAL so RuleManager and rules share the same table
HARDCORE.name = ADDON_NAME
HARDCORE.version = "0.6.0"

-- SavedVars (per account)
HARDCORE.defaults = {
    hasSeenIntro = false, -- optional: first-time hint; not used for auto-open once accepted
    acceptedAt = nil, -- timestamp when player first accepted the challenge (ever)
    isActive = false, -- whether Hardcore Mode is currently active
    challengeStartedAt = nil, -- timestamp while running
    challengeElapsed = 0 -- total seconds accumulated (stops when not active)

}

local COLOR = {
    white = ZO_ColorDef:New(1, 1, 1, 1),
    gold = ZO_ColorDef:New(1, 0.84, 0, 1),
    gray = ZO_ColorDef:New(0.78, 0.78, 0.78, 1),
    dim = ZO_ColorDef:New(0.85, 0.85, 0.85, 0.65)
}

local RULE_ICONS = {
    mail = "/esoui/art/addons/gamepad/gp_mod_listing_category_mail.dds",
    crafting = "/esoui/art/inventory/inventory_craft_tabicon_active.dds",
    gear = "/esoui/art/tradinghouse/gamepad/gp_tradinghouse_materials_trait_armortrait.dds",
    sets = "/esoui/art/icons/icon_1handed.dds",
    cp = "/esoui/art/armory/buildicons/buildicon_5.dds",
    trade = "/esoui/art/icons/emotes/emotecategoryicon_social.dds",
    hud = "/esoui/art/icons/heraldrycrests_misc_eye_01.dds",
    enemy = "/esoui/art/hud/hud_countdown_badge_dueling.dds",
    compass = "/esoui/art/addons/gamepad/gp_mod_listing_category_mapandcompass.dds",
    aoe = "/esoui/art/treeicons/u46_helpcategory_update46_down.dds",
    tp = "/esoui/art/zonestories/completiontypeicon_wayshrine.dds",
    healing = "/esoui/art/lfg/lfg_healer_down_no_glow_64.dds",
    safezone = "/esoui/art/icons/mapkey/mapkey_avatown.dds",
    grouping = "/esoui/art/treeicons/gamepad/gp_tutorial_idexicon_groups.dds",
    repairkit = "/esoui/art/vendor/vendor_tabicon_repair_down.dds",
    vendor = "/esoui/art/vendor/vendor_tabicon_repair_down.dds",
    permadeath = "/esoui/art/trials/vitalitydepletion.dds",
    soulgem = "/esoui/art/inventory/inventory_tabicon_soulgem_down.dds",
    bank = "/esoui/art/icons/servicemappins/servicepin_bank.dds",
    guildstore = "/esoui/art/tutorial/gamepad/gp_playermenu_icon_guilds.dds"
}

-- Rules with short tooltip blurbs for professional polish
local RULES = {{
    text = "No Mail (until 50)",
    icon = RULE_ICONS.mail,
    tip = "Mail system is locked until level 50"
}, {
    text = "No Crafting",
    icon = RULE_ICONS.crafting,
    tip = "Crafting, refining, researching and deconstruction are disabled."
}, {
    text = "Limited Gear Quality (50+)",
    icon = RULE_ICONS.gear,
    tip = "From level 50 onward, only white or green gear may be worn."
}, {
    text = "Max 2 Pieces per Set",
    icon = RULE_ICONS.sets,
    tip = "You may equip at most 2 pieces from any item set. Higher set bonuses (3–5 pieces) are forbidden."
}, {
    text = "No Champion Points",
    icon = RULE_ICONS.cp,
    tip = "Do not spend or benefit from Champion Points."
}, {
    text = "Hardcore HUD",
    icon = RULE_ICONS.hud,
    tip = "Hidden health attribute bar and action bar (brief peek only)."
}, {
    text = "Blind Combat",
    icon = RULE_ICONS.enemy,
    tip = "All nameplates, health bars, and the target frame are hidden."
}, {
    text = "No Compass",
    icon = RULE_ICONS.compass,
    tip = "Compass and quest markers on it are disabled."
}, {
    text = "No AOE Cues",
    icon = RULE_ICONS.aoe,
    tip = "Ground telegraphs for enemy AOE attacks are hidden."
}, {
    text = "No Bank (until 50)",
    icon = RULE_ICONS.bank,
    tip = "Bank access is locked until level 50."
}, {
    text = "No Guild Stores",
    icon = RULE_ICONS.guildstore,
    tip = "Guild traders and stores cannot be used."
}, {
    text = "No Trading",
    icon = RULE_ICONS.trade,
    tip = "You cannot trade directly with other players."
}, {
    text = "No Repairs",
    icon = RULE_ICONS.repairkit,
    tip = "Repairing gear via vendors or repair kits is disabled. Damaged gear must be replaced."
}, {
    text = "No Soul Gems",
    icon = RULE_ICONS.soulgem,
    tip = "Soul gems cannot be used to recharge weapons."
}, {
    text = "Safe Zone Skill Change",
    icon = RULE_ICONS.safezone,
    tip = "Skill management is only allowed inside towns and cities."
}, {
    text = "Limited Teleport",
    icon = RULE_ICONS.tp,
    tip = "Fast travel is restricted to wayshrine-to-wayshrine only."
}, {
    text = "One Life Run",
    icon = RULE_ICONS.permadeath,
    tip = "One death ends the challenge. No further points or progress, time survived is recorded"
}}

-- Utility: tooltip helpers --------------------------------------------------
local function ShowTip(ctrl, text)
    if not text or text == "" then
        return
    end
    InitializeTooltip(InformationTooltip, ctrl, RIGHT, -8, 0)
    SetTooltipText(InformationTooltip, text)
end
local function HideTip()
    ClearTooltip(InformationTooltip)
end

local function AnnounceTrialBegins()
    local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.QUEST_ACCEPTED)
    params:SetText("The Trial Begins")
    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
end
-- === Time tracking (per character) =========================================
function HARDCORE.GetChallengeElapsedSeconds()
    local sv = HARDCORE.saved
    local live = (sv.isActive and sv.challengeStartedAt) and (GetTimeStamp() - sv.challengeStartedAt) or 0
    return (sv.challengeElapsed or 0) + live
end

local function _startTimerNow()
    HARDCORE.saved.challengeStartedAt = GetTimeStamp()
end

local function _stopTimerAccumulate()
    local sv = HARDCORE.saved
    if sv.challengeStartedAt then
        sv.challengeElapsed = (sv.challengeElapsed or 0) + (GetTimeStamp() - sv.challengeStartedAt)
        sv.challengeStartedAt = nil
    end
end

function HARDCORE.BeginChallengeRun()
    local sv = HARDCORE.saved
    if sv.isActive then
        return
    end
    sv.isActive = true
    sv.challengeElapsed = 0
    if not sv.acceptedAt then
        sv.acceptedAt = GetTimeStamp()
    end
    _startTimerNow()

    if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
        HARDCORE.RuleManager:SetActive(true)
    end
    if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.SetActive then
        HARDCORE.ChallengeManager:SetActive(true)
    end
    if HARDCORE.ChallengeUI and HARDCORE.ChallengeUI.Show then
        HARDCORE.ChallengeUI:Show()
    end

    -- ✅ Close the intro/acceptance window
    if HARDCORE.ToggleIntro then
        HARDCORE.ToggleIntro(false)
    end
end

function HARDCORE.SurrenderChallenge()
    _stopTimerAccumulate()
    HARDCORE.saved.isActive = false

    if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
        HARDCORE.RuleManager:SetActive(false)
    end
    if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.SetActive then
        HARDCORE.ChallengeManager:SetActive(false)
    end
    if HARDCORE.ChallengeUI and HARDCORE.ChallengeUI.Hide then
        HARDCORE.ChallengeUI:Hide()
    end
end

-- helpers -----------------------------------------------------
local function GetMainMenuBar()
    return MAIN_MENU_KEYBOARD and MAIN_MENU_KEYBOARD.categoryBar
end

local function DeactivateMenuButton()
    local bar = GetMainMenuBar()
    if bar then
        ZO_MenuBar_ClearSelection(bar)
    end
end

function HARDCORE.OpenChallengeWindow()
    if not HARDCORE or not HARDCORE.ChallengeUI or not HARDCORE.ChallengeUI.Show then
        return
    end

    if not (HARDCORE.saved and HARDCORE.saved.isActive) then
        d("[HARDCORE] Hardcore is not active. Accept the challenge to open the Challenges window.")
        return
    end

    if HARDCORE.ChallengeUI:IsShown() then
        HARDCORE.ChallengeUI:Hide()
    else
        HARDCORE.ChallengeUI:Show()
    end
end

local function ActivateMenuButton()
    local bar = GetMainMenuBar()
    if bar then
        ZO_MenuBar_SelectDescriptor(bar, "HARDCORE_MAINMENU", true) -- optional
    end
end
local function AddHardcoreMainMenuButton()
    local bar = MAIN_MENU_KEYBOARD and MAIN_MENU_KEYBOARD.categoryBar
    if not bar or HARDCORE._mainMenuBtnAdded then
        return
    end

    local data = {
        descriptor = "HARDCORE_MAINMENU",
        normal = "/esoui/art/journal/journal_tabicon_achievements_up.dds",
        pressed = "/esoui/art/journal/journal_tabicon_achievements_down.dds",
        highlight = "/esoui/art/journal/journal_tabicon_achievements_over.dds",
        categoryName = "HARDCORE", -- <- shows text under the icon
        callback = function()
            if not HARDCORE then
                return
            end
            local bar = MAIN_MENU_KEYBOARD and MAIN_MENU_KEYBOARD.categoryBar

            if HARDCORE.saved and HARDCORE.saved.isActive then
                -- Hardcore run is active: toggle the Challenges window
                if HARDCORE.OpenChallengeWindow then
                    HARDCORE.OpenChallengeWindow()
                end
                -- reflect selection by whether the Challenges window is visible
                if bar and HARDCORE.ChallengeUI then
                    if HARDCORE.ChallengeUI:IsShown() then
                        ZO_MenuBar_SelectDescriptor(bar, "HARDCORE_MAINMENU", true)
                    else
                        ZO_MenuBar_ClearSelection(bar)
                    end
                end
            else
                -- Not active yet: open your intro window as before
                if HARDCORE.ToggleIntro then
                    HARDCORE.ToggleIntro()
                end
                if bar and HARDCORE.window then
                    if HARDCORE.window:IsHidden() then
                        ZO_MenuBar_ClearSelection(bar)
                    else
                        ZO_MenuBar_SelectDescriptor(bar, "HARDCORE_MAINMENU", true)
                    end
                end
            end
        end

    }

    -- Add and force our own tooltip so it always appears
    local btn = ZO_MenuBar_AddButton(bar, data)
    if btn then
        btn:SetHandler("OnMouseEnter", function(self)
            InitializeTooltip(InformationTooltip, self, TOP, 0, 10)
            SetTooltipText(InformationTooltip, "HARDCORE")
        end)
        btn:SetHandler("OnMouseExit", function()
            ClearTooltip(InformationTooltip)
        end)
    end

    HARDCORE._mainMenuBtnAdded = true
end

-- Register once per session when player finishes loading in
EVENT_MANAGER:RegisterForEvent("HARDCORE_MainMenuBtn", EVENT_PLAYER_ACTIVATED, function()
    AddHardcoreMainMenuButton()
end)

-- === Champion Points check & dialog ===
local function HARDCORE_HasAnyChampionSlotted()
    local startSlot, endSlot = GetAssignableChampionBarStartAndEndSlots()
    if not startSlot or not endSlot then
        return false
    end
    for i = startSlot, endSlot do
        if IsSlotUsed(i, HOTBAR_CATEGORY_CHAMPION) then
            return true
        end
    end
    return false
end

local function HARDCORE_ShowCPBlockedDialog()
    -- register once
    if not HARDCORE._cpDialogRegistered then
        ZO_Dialogs_RegisterCustomDialog("HARDCORE_CP_BLOCKED", {
            title = {
                text = "Champion Points Detected"
            },
            mainText = {
                text = "You have Champion slottables equipped.\n\nPlease unslot ALL Champion skills before starting the challenge."
            },
            buttons = {
                [1] = {
                    text = "Open Champion UI",
                    callback = function()
                        if SCENE_MANAGER and SCENE_MANAGER.Show then
                            -- Common scene name for the CP screen in ESO UI
                            SCENE_MANAGER:Show("championPerks")
                        end
                    end
                },
                [2] = {
                    text = SI_OK
                }
            },
            noChoiceCallback = function()
            end
        })
        HARDCORE._cpDialogRegistered = true
    end

    ZO_Dialogs_ShowDialog("HARDCORE_CP_BLOCKED")
end

-- UI creation ---------------------------------------------------------------
local function CreateIntroWindow()
    if HARDCORE.window then
        return
    end

    local wm = WINDOW_MANAGER

    -- Top-level window
    local win = wm:CreateTopLevelWindow("HARDCORE_IntroWindow")
    HARDCORE.window = win
    win:SetMovable(false)
    win:SetMouseEnabled(true)
    win:SetClampedToScreen(true)
    win:SetResizeHandleSize(0)
    win:SetHidden(true)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, -40)
    win:SetDimensions(900, 480)

    -- Framed backdrop
    local frame = wm:CreateControl(nil, win, CT_BACKDROP)
    frame:SetAnchorFill()
    frame:SetCenterColor(0, 0, 0, 0.88)
    frame:SetEdgeTexture("/esoui/art/chatwindow/chat_bg_edge.dds", 32, 4, 4)
    frame:SetEdgeColor(0.9, 0.85, 0.65, 1)

    -- Inner container
    local inner = wm:CreateControl("HARDCORE_Inner", win, CT_CONTROL)
    inner:SetAnchor(TOPLEFT, win, TOPLEFT, 8, 8)
    inner:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, -8, -8)

    -- Background image
    local bg = wm:CreateControl("HARDCORE_InnerBG", inner, CT_TEXTURE)
    bg:SetAnchorFill(inner)
    bg:SetTexture("/esoui/art/loadingscreens/loadscreen_shadastear_01.dds")
    bg:SetTextureCoords(0, 1, 0, 1)
    bg:SetDrawTier(DT_LOW)
    bg:SetDrawLayer(DL_BACKGROUND)
    bg:SetAlpha(0.60)
    bg:SetBlendMode(TEX_BLEND_COLOR_ALPHA)

    -- Soft dark wash for readability
    local wash = wm:CreateControl("HARDCORE_InnerWash", inner, CT_BACKDROP)
    wash:SetAnchorFill(inner)
    wash:SetCenterColor(0, 0, 0, 0.40)
    wash:SetEdgeColor(0, 0, 0, 0)
    wash:SetEdgeTexture(nil, 1, 1, 0, 0)
    wash:SetDrawTier(DT_LOW)
    wash:SetDrawLayer(DL_BACKGROUND)
    wash:SetDrawLevel(1)

    -- Subtle inner edge
    local subtleEdge = wm:CreateControl("HARDCORE_InnerEdge", inner, CT_BACKDROP)
    subtleEdge:SetAnchorFill(inner)
    subtleEdge:SetCenterColor(0, 0, 0, 0)
    subtleEdge:SetEdgeTexture("/esoui/art/miscellaneous/centerscreen_announceEdge.dds", 32, 4, 4)
    subtleEdge:SetEdgeColor(0, 0, 0, 0.25)
    subtleEdge:SetDrawLayer(DL_OVERLAY)
    subtleEdge:SetDrawLevel(1)

    -- Corner ornaments (smaller)
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

    Corner("HARDCORE_CornerTL", "/esoui/art/reticle/border_topleft.dds", TOPLEFT, -1, -1, 16, 16)
    Corner("HARDCORE_CornerTR", "/esoui/art/reticle/border_topright.dds", TOPRIGHT, 1, -1, 16, 16)
    Corner("HARDCORE_CornerBL", "/esoui/art/reticle/border_bottomleft.dds", BOTTOMLEFT, -1, 1, 16, 16)
    Corner("HARDCORE_CornerBR", "/esoui/art/reticle/border_bottomright.dds", BOTTOMRIGHT, 1, 1, 16, 16)

    -- Title
    local title = wm:CreateControl(nil, inner, CT_LABEL)
    title:SetAnchor(TOP, inner, TOP, 0, 20)
    title:SetFont("$(BOLD_FONT)|38|soft-shadow-thick")
    title:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    title:SetText("HARDCORE")
    title:SetColor(COLOR.gold:UnpackRGBA())

    -- Decorative icons left & right of title
    local iconLeft = wm:CreateControl(nil, inner, CT_TEXTURE)
    iconLeft:SetDimensions(40, 40)
    iconLeft:SetAnchor(RIGHT, title, LEFT, -12, 0)
    iconLeft:SetTexture("/esoui/art/icons/poi/poi_solotrial_incomplete.dds")

    local iconRight = wm:CreateControl(nil, inner, CT_TEXTURE)
    iconRight:SetDimensions(40, 40)
    iconRight:SetAnchor(LEFT, title, RIGHT, 12, 0)
    iconRight:SetTexture("/esoui/art/icons/poi/poi_solotrial_incomplete.dds")

    -- Divider
    local divider = wm:CreateControl(nil, inner, CT_TEXTURE)
    divider:SetAnchor(TOP, title, BOTTOM, 0, 8)
    divider:SetDimensions(520, 8)
    divider:SetTexture("/esoui/art/miscellaneous/horizontaldivider.dds")
    divider:SetAlpha(0.55)

    -- Subtitle
    local sub = wm:CreateControl(nil, inner, CT_LABEL)
    sub:SetAnchor(TOP, divider, BOTTOM, 0, 6)
    sub:SetFont("$(MEDIUM_FONT)|18|soft-shadow-thin")
    sub:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    sub:SetColor(COLOR.gray:UnpackRGBA())
    sub:SetText("Accept the challenge to enable the ruleset on this character.")
    HARDCORE.subtitle = sub

    -- Scroll container
    local scroll = wm:CreateControlFromVirtual("HARDCORE_RulesScroll", inner, "ZO_ScrollContainer")
    scroll:SetAnchor(TOPLEFT, inner, TOPLEFT, 24, 120)
    scroll:SetDimensions(852, 280)
    local scrollChild = scroll:GetNamedChild("ScrollChild")

    -- Grid layout
    local COLS, COL_W, ROW_H, ICON = 3, 280, 44, 28

    local function CreateRuleRow(parent, idx, rule)
        local col = ((idx - 1) % COLS) + 1
        local row = math.floor((idx - 1) / COLS)
        local x = (col - 1) * COL_W
        local y = row * ROW_H

        local rowCtrl = wm:CreateControl("HARDCORE_RuleRow" .. idx, parent, CT_CONTROL)
        rowCtrl:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
        rowCtrl:SetDimensions(COL_W - 10, ROW_H)
        rowCtrl:SetMouseEnabled(true)

        local icon = wm:CreateControl(nil, rowCtrl, CT_TEXTURE)
        icon:SetDimensions(ICON, ICON)
        icon:SetAnchor(LEFT, rowCtrl, LEFT, 4, 0)
        icon:SetTexture(rule.icon)
        icon:SetAlpha(0.95)

        local label = wm:CreateControl(nil, rowCtrl, CT_LABEL)
        label:SetAnchor(LEFT, icon, RIGHT, 10, 0)
        label:SetFont("$(MEDIUM_FONT)|20|soft-shadow-thin")
        label:SetText(rule.text)
        label:SetColor(COLOR.white:UnpackRGBA())
        label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)

        rowCtrl:SetHandler("OnMouseEnter", function()
            label:SetColor(COLOR.gold:UnpackRGBA())
            ShowTip(rowCtrl, rule.tip)
        end)
        rowCtrl:SetHandler("OnMouseExit", function()
            label:SetColor(COLOR.white:UnpackRGBA())
            HideTip()
        end)

        return rowCtrl
    end

    for i, rule in ipairs(RULES) do
        CreateRuleRow(scrollChild, i, rule)
    end

    -- Per-character SavedVars for HUD backup
    local function GetHUDSV()
        HARDCORE = HARDCORE or {}
        if not HARDCORE.hudBackup then
            HARDCORE.hudBackup = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_HUD_BACKUP", 1, nil, {
                saved = {
                    allNameplates = nil,
                    allHealthbars = nil,
                    combatCues = nil
                }
            })
        end
        return HARDCORE.hudBackup
    end

    local function _boolToSetting(v)
        return v and "1" or "0"
    end

    function HARDCORE.SaveHUDSettings()
        local sv = GetHUDSV()
        sv.saved.allNameplates = GetSetting_Bool(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_NAMEPLATES)
        sv.saved.allHealthbars = GetSetting_Bool(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_HEALTHBARS)
        sv.saved.combatCues = GetSetting_Bool(SETTING_TYPE_COMBAT, COMBAT_SETTING_MONSTER_TELLS_ENABLED)
    end

    function HARDCORE.RestoreHUDSettings()
        local sv = GetHUDSV()
        if sv.saved.allNameplates ~= nil then
            SetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_NAMEPLATES, _boolToSetting(sv.saved.allNameplates))
        end
        if sv.saved.allHealthbars ~= nil then
            SetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_HEALTHBARS, _boolToSetting(sv.saved.allHealthbars))
        end
        if sv.saved.combatCues ~= nil then
            SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_MONSTER_TELLS_ENABLED, _boolToSetting(sv.saved.combatCues))
        end
    end

    -- Accept / Re-enter / Surrender button (single control, dynamic behavior)
    local btn = wm:CreateControlFromVirtual("HARDCORE_ActionButton", win, "ZO_DefaultButton")
    HARDCORE.actionButton = btn
    btn:SetAnchor(BOTTOM, win, BOTTOM, 0, -18)
    btn:SetDimensions(260, 44)

    local function UpdateActionButton()
        if HARDCORE.saved.isActive then
            btn:SetHidden(true)
        else
            btn:SetHidden(false)
            btn:SetText(HARDCORE.saved.acceptedAt and "Re-enter Challenge" or "Accept Challenge")
            btn:SetHandler("OnMouseEnter", function()
                ShowTip(btn, "Enable Hardcore Mode on this character.")
            end)
            btn:SetHandler("OnMouseExit", HideTip)
            btn:SetHandler("OnClicked", function()
                -- Block start if any CP are slotted
                if HARDCORE_HasAnyChampionSlotted() then
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    HARDCORE_ShowCPBlockedDialog()
                    return
                end
                HARDCORE.ToggleIntro() -- closes
                DeactivateMenuButton()
                PlaySound(SOUNDS.INSTANCE_SHUTDOWN)
                PlaySound(SOUNDS.QUEST_ACCEPTED)
                PlaySound(SOUNDS.ENDLESS_DUNGEON_SCORE_FINAL_FLIP)
                AnnounceTrialBegins()
                if not HARDCORE.saved.acceptedAt then
                    HARDCORE.saved.acceptedAt = GetTimeStamp()
                end
                HARDCORE.BeginChallengeRun()
                HARDCORE.saved.isActive = true
                if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
                    HARDCORE.RuleManager:SetActive(true)
                    function HARDCORE.BeginChallengeRun()
                        HARDCORE.saved = HARDCORE.saved or {}
                        HARDCORE.saved.isActive = true -- make sure this is set
                        HARDCORE.saved.acceptedAt = GetTimeStamp()

                        if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
                            HARDCORE.RuleManager:SetActive(true)
                        end
                        if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.SetActive then
                            HARDCORE.ChallengeManager:SetActive(true)
                        end
                        if HARDCORE.ChallengeUI and HARDCORE.ChallengeUI.Show then
                            HARDCORE.ChallengeUI:Show()
                        end
                    end
                end
                if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.SetActive then
                    HARDCORE.ChallengeManager:SetActive(true)
                end
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_SKILL_PURCHASED,
                    "HARDCORE: Challenge active. Good luck!")
                if HARDCORE.subtitle then
                    HARDCORE.subtitle:SetText("HARDCORE rules are active on this character.")
                end
                HARDCORE.ToggleIntro() -- close window
            end)
        end
    end

    HARDCORE.UpdateActionButton = UpdateActionButton
    UpdateActionButton()

    -- Close (X)
    local close = wm:CreateControlFromVirtual("HARDCORE_Close", win, "ZO_CloseButton")
    close:SetAnchor(TOPRIGHT, win, TOPRIGHT, -18, 14)
    close:SetHandler("OnClicked", function()
        win:SetHidden(true)
        DeactivateMenuButton()
    end)

    -- Fade-in animation
    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local fade = timeline:InsertAnimation(ANIMATION_ALPHA, win)
    fade:SetAlphaValues(0, 1)
    fade:SetDuration(200)
    HARDCORE.fadeIn = function()
        win:SetAlpha(0)
        timeline:PlayFromStart()
    end
end

function HARDCORE.ToggleIntro()
    if not HARDCORE.window then
        CreateIntroWindow()
    end

    local hidden = HARDCORE.window:IsHidden()
    if hidden then
        HARDCORE.window:SetHidden(false)
        if HARDCORE.fadeIn then
            HARDCORE.fadeIn()
        end
        if HARDCORE.UpdateActionButton then
            HARDCORE.UpdateActionButton()
        end
        -- Subtitle reflects current state
        if HARDCORE.subtitle then
            if HARDCORE.saved.isActive then
                HARDCORE.subtitle:SetText("HARDCORE rules are active on this character.")
            else
                HARDCORE.subtitle:SetText(HARDCORE.saved.acceptedAt and
                                              "Hardcore Mode is inactive. You can re-enter anytime." or
                                              "Accept the challenge to enable the ruleset on this character.")
            end
        end
        PlaySound(SOUNDS.SKILL_XP_DARK_FISSURE_CLOSED)
        ActivateMenuButton()
    else
        HARDCORE.window:SetHidden(true)
        DeactivateMenuButton()
    end
end

local function RegisterSlash()
    SLASH_COMMANDS["/hc"] = function()
        HARDCORE.OpenChallengeWindow()
    end
end

local function OnAddOnLoaded(event, addonName)
    if addonName ~= ADDON_NAME then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    HARDCORE.saved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_SV", 1, nil, HARDCORE.defaults, GetWorldName())
    -- If Hardcore is active on load, only ensure a start anchor if it's missing.
    if HARDCORE.saved.isActive then
        if not HARDCORE.saved.challengeStartedAt then
            HARDCORE.saved.challengeStartedAt = GetTimeStamp()
        end

        -- Re-apply managers (no fresh-run logic here)
        if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
            HARDCORE.RuleManager:SetActive(true)
        end
        if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.SetActive then
            HARDCORE.ChallengeManager:SetActive(true)
        end
    end

    if HARDCORE.RuleManager and HARDCORE.RuleManager.Init then
        HARDCORE.RuleManager:Init()
    end
    if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.Init then
        HARDCORE.ChallengeManager:Init()
    end
    -- LAM panel
    local lam = LibAddonMenu2
    if lam then
        local panelData = {
            type = "panel",
            name = "HARDCORE",
            author = "You",
            version = HARDCORE.version,
            displayName = "|cFFD700HARDCORE|r",
            registerForRefresh = true,
            registerForDefaults = true
        }
        lam:RegisterAddonPanel("HARDCORE_LAM", panelData)
        lam:RegisterOptionControls("HARDCORE_LAM", {{
            type = "description",
            text = "Open the rules window with /hc. Accept to enable the challenge."
        }, {
            type = "button",
            name = "Show Intro",
            width = "full",
            func = function()
                HARDCORE.ToggleIntro()
            end
        }})
    end

    CreateIntroWindow()
    RegisterSlash()

    -- Auto-open ONLY until the challenge has ever been accepted
    if not HARDCORE.saved.acceptedAt then
        zo_callLater(function()
            HARDCORE.ToggleIntro()
        end, 600)
    end

end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

--[[
File: HARDCORE/HARDCORE.txt (manifest)

## Title: HARDCORE
## Author: You
## Version: 0.6.0
## APIVersion: 101042
## Description: Polished rules window with two-column grid, tooltips, fade-in. /hc to toggle.
## DependsOn: LibAddonMenu-2.0
## SavedVariables: HARDCORE_SV

HARDCORE.lua
]]
