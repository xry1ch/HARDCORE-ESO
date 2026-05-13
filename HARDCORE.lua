local ADDON_NAME = "HARDCORE"
HARDCORE = HARDCORE or {}
local HARDCORE = HARDCORE
HARDCORE.name = ADDON_NAME
HARDCORE.version = "1.0.0"

-- SavedVars
HARDCORE.defaults = {
    hasSeenIntro = false,
    isActive = false,
    minHealthPct = 100,
    persistedMinHealthPct = 100,
    difficultyTier = 2,
    disableVisionDim = false,
    disableLowHealthVolume = false,
    hasSeenCongrats = false,
    hasDied = false
}

local COLOR = {
    white = ZO_ColorDef:New(1, 1, 1, 1),
    gold = ZO_ColorDef:New(1, 0.84, 0, 1),
    gray = ZO_ColorDef:New(0.78, 0.78, 0.78, 1),
    dim = ZO_ColorDef:New(0.85, 0.85, 0.85, 0.65),
    red = ZO_ColorDef:New(0.85, 0.15, 0.15, 1)
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

local RULES = {{
    text = "Sealed Mail",
    icon = RULE_ICONS.mail,
    tip = "Couriers refuse your letters and parcels.",
    ruleId = "NoMail"
}, {
    text = "Restricted Crafting",
    icon = RULE_ICONS.crafting,
    tip = "Only cooking and alchemy are permitted. All other crafting arts are forbidden on this journey.",
    ruleId = "NoCrafting"
}, {
    text = "Humble Gear Only",
    icon = RULE_ICONS.gear,
    tip = "You may arm yourself only with simple gear of white or green quality.",
    ruleId = "LimitedGear"
}, {
    text = "Two-Set Limit",
    icon = RULE_ICONS.sets,
    tip = "You may wear no more than two items from the same set; the greater set bonuses are off-limits.",
    ruleId = "LimitedSets"
}, {
    text = "Sealed Champion Power",
    icon = RULE_ICONS.cp,
    tip = "Champion power remains sealed; none may be gained or used.",
    ruleId = "NoCP"
}, {
    text = "Adventurer's HUD",
    icon = RULE_ICONS.hud,
    tip = "Your health bar is hidden. As your strength wanes, your vision dims and narrows, and your action bars remain concealed, revealed only in brief moments.",
    ruleId = "HardcoreHUD"
}, {
    text = "Blind Combat",
    icon = RULE_ICONS.enemy,
    tip = "Foes show no names, no health bars, and no target frame. Read the battle, not the UI.",
    ruleId = "NoHealthBar"
}, {
    text = "No Guiding Compass",
    icon = RULE_ICONS.compass,
    tip = "Your compass is silent, offering no markers or guidance.",
    ruleId = "NoCompass"
}, {
    text = "Hidden AOE Threats",
    icon = RULE_ICONS.aoe,
    tip = "Enemy area attacks leave no ground telegraphs. Danger must be sensed, not seen.",
    ruleId = "HiddenAOEThreats"
}, {
    text = "Locked Banks",
    icon = RULE_ICONS.bank,
    tip = "All banks remain inaccessible.",
    ruleId = "NoBank"
}, {
    text = "Closed Guild Markets",
    icon = RULE_ICONS.guildstore,
    tip = "Guild traders and their markets are closed to you.",
    ruleId = "NoGuildStore"
}, {
    text = "Self-Reliant Journey",
    icon = RULE_ICONS.trade,
    tip = "No direct trade may pass between you and other adventurers.",
    ruleId = "NoTrade"
}, {
    text = "Irreparable Gear",
    icon = RULE_ICONS.repairkit,
    tip = "Gear cannot be repaired; once worn down, it must be replaced.",
    ruleId = "NoRepair"
}, {
    text = "Dormant Soul Gems",
    icon = RULE_ICONS.soulgem,
    tip = "Soul gems cannot restore weapon charges on this challenge.",
    ruleId = "NoSoulGems"
}, {
    text = "Sanctuary Skill Changes",
    icon = RULE_ICONS.safezone,
    tip = "Skills may be adjusted only within towns and safe settlements.",
    ruleId = "EquipmentCitySkills"
}, {
    text = "Bound Wayshrines",
    icon = RULE_ICONS.tp,
    tip = "Fast travel is restricted to wayshrine-to-wayshrine only.",
    ruleId = "LimitedTP"
}, {
    text = "One Life Run",
    icon = RULE_ICONS.permadeath,
    tip = "DEATH = DELETE",
    alwaysOn = true
}}

-- Difficulty tiers (slider presets)
local DIFFICULTY_TIERS = {
    [1] = "|t24:24:/esoui/art/armory/buildicons/buildicon_58.dds|t  Novice",
    [2] = "|t24:24:/esoui/art/armory/buildicons/buildicon_39.dds|t  Adept",
    [3] = "|t24:24:/esoui/art/armory/buildicons/buildicon_34.dds|t  Master",
    [4] = "|t24:24:/esoui/art/armory/buildicons/buildicon_18.dds|t  Legendary",
    [5] = "|t24:24:/esoui/art/campaign/campaign_tabicon_summary_up.dds|t  Custom"
}

local TIER_RULE_IDS = {
    [1] = {"HardcoreHUD", "HiddenAOEThreats", "NoCompass", "LimitedTP"},
    [2] = {"HardcoreHUD", "HiddenAOEThreats", "NoCompass", "LimitedTP", "NoTrade", "NoBank", "NoGuildStore",
           "NoCrafting", "NoSoulGems", "NoMail"},
    [3] = {"HardcoreHUD", "HiddenAOEThreats", "NoCompass", "LimitedTP", "NoTrade", "NoBank", "NoGuildStore",
           "NoCrafting", "NoSoulGems", "NoHealthBar", "NoCP", "NoMail"},
    [4] = {"HardcoreHUD", "HiddenAOEThreats", "NoCompass", "LimitedTP", "NoTrade", "NoBank", "NoGuildStore",
           "NoCrafting", "NoSoulGems", "NoHealthBar", "NoCP", "LimitedGear", "LimitedSets", "NoRepair",
           "EquipmentCitySkills", "NoMail"}
}

local function BuildSet(arr)
    local s = {}
    for _, id in ipairs(arr or {}) do
        s[id] = true
    end
    return s
end

function HARDCORE.InitRulesSaved()
    HARDCORE = HARDCORE or {}
    if not HARDCORE.rulesSaved then
        HARDCORE.rulesSaved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_Rules_SV", 1, nil, {
            enabled = {}
        }, GetWorldName())
    end
    HARDCORE.rulesSaved.enabled = HARDCORE.rulesSaved.enabled or {}
    return HARDCORE.rulesSaved
end

local function GetRulesSV()
    return HARDCORE.InitRulesSaved()
end
function HARDCORE.SetDifficultySliderEnabled(enabled)
    HARDCORE._difficultyControlsEnabled = enabled and true or false

    if not HARDCORE.difficultySlider then
        return
    end

    HARDCORE.difficultySlider:SetEnabled(enabled)

    HARDCORE.difficultySlider:SetAlpha(enabled and 1 or 0.35)

    HARDCORE.difficultySlider:SetMouseEnabled(enabled)
end

local function IsCustomDifficultyTier(tier)
    return tonumber(tier) == 5
end

local function GetRuleEnabledSetForUI(tier)
    if IsCustomDifficultyTier(tier) then
        local sv = GetRulesSV()
        return sv.enabled or {}
    end
    return BuildSet(TIER_RULE_IDS[tier])
end

function HARDCORE.ApplyDifficultyPreset(tier)
    tier = zo_clamp(tonumber(tier) or 1, 1, 5)
    HARDCORE.saved.difficultyTier = tier

    local sv = GetRulesSV()
    local enabledSet = BuildSet(TIER_RULE_IDS[tier])

    if HARDCORE.RuleManager and HARDCORE.RuleManager.ForEachRule then
        HARDCORE.RuleManager:ForEachRule(function(id, _rule)
            sv.enabled[id] = enabledSet[id] == true
        end)
    else
        for id in pairs(sv.enabled) do
            sv.enabled[id] = enabledSet[id] == true
        end
        for id in pairs(enabledSet) do
            sv.enabled[id] = true
        end
    end

    HARDCORE.RefreshDifficultyUI()
end

function HARDCORE.RefreshDifficultyUI()
    if not HARDCORE._ruleRows then
        return
    end
    local tier = (HARDCORE.saved and HARDCORE.saved.difficultyTier) or 1
    local enabledSet = GetRuleEnabledSetForUI(tier)

    if HARDCORE.difficultyLabel then
        HARDCORE.difficultyLabel:SetText(DIFFICULTY_TIERS[tier] or ("Tier " .. tostring(tier)))
    end
    if HARDCORE.difficultySlider then
        HARDCORE.difficultySlider:SetValue(tier)
    end

    for _, row in ipairs(HARDCORE._ruleRows) do
        local r = row._ruleData
        local isAlways = r and r.alwaysOn
        local active = isAlways or ((r and r.ruleId and enabledSet[r.ruleId]) == true)

        if row._icon then
            row._icon:SetAlpha(active and 0.95 or 0.25)
        end
        if row._label then
            if active then
                row._label:SetColor(COLOR.white:UnpackRGBA())
            else
                row._label:SetColor(COLOR.dim:UnpackRGBA())
            end
        end
        if row._bg then
            row._bg:SetAlpha(active and 0.18 or 0.05)
        end

        row:SetMouseEnabled(true)
        if row._hitArea then
            row._hitArea:SetMouseEnabled(true)
        end
    end
end

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

local function HARDCORE_GetPlayerClassIngameIcon()
    local classId = GetUnitClassId("player")
    local classIndex = GetClassIndexById(classId)
    if not classIndex then
        return nil
    end

    local _, _, _, _, _, _, ingameIconKeyboard = GetClassInfo(classIndex)
    return ingameIconKeyboard
end

function HARDCORE.UpdateActiveStatsUI()
    if not HARDCORE.activeStats then
        return
    end

    if not (HARDCORE.saved and HARDCORE.saved.isActive) then
        HARDCORE.activeStats:SetHidden(true)
        return
    end

    HARDCORE.activeStats:SetHidden(false)

    local icon = HARDCORE_GetPlayerClassIngameIcon()
    if icon and HARDCORE.activeStats.classIcon then
        HARDCORE.activeStats.classIcon:SetTexture(icon)
    end

    local lvl = GetUnitLevel("player")
    if HARDCORE.activeStats.levelLabel then
        HARDCORE.activeStats.levelLabel:SetText(string.format("Lv %d", lvl))
    end

    -- persisted minimum health reached
    local minPct = (HARDCORE.saved and HARDCORE.saved.persistedMinHealthPct) or 100
    if HARDCORE.activeStats.minHpLabel then
        HARDCORE.activeStats.minHpLabel:SetText(string.format("%d%%", minPct))
    end
end

local MINHP_EVENT_NAME = ADDON_NAME .. "_MinHP"

local function HARDCORE_OnPowerUpdate(_, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
    local cur, maxVal = GetUnitPower("player", COMBAT_MECHANIC_FLAGS_HEALTH)
    if not maxVal or maxVal <= 0 then
        return
    end

    local pct = zo_floor((cur / maxVal) * 100 + 0.5)

    local prev = HARDCORE.saved.minHealthPct
    if prev == nil then
        HARDCORE.saved.minHealthPct = 100
        prev = 100
    end

    if pct < prev then
        HARDCORE.saved.minHealthPct = pct
        if not HARDCORE.saved.persistedMinHealthPct or pct < HARDCORE.saved.persistedMinHealthPct then
            HARDCORE.saved.persistedMinHealthPct = pct
        end
        HARDCORE.UpdateActiveStatsUI()
    end
end

local function HARDCORE_EnableMinHpTracking()
    EVENT_MANAGER:UnregisterForEvent(MINHP_EVENT_NAME, EVENT_POWER_UPDATE)
    if HARDCORE.saved and HARDCORE.saved.isActive then
        EVENT_MANAGER:RegisterForEvent(MINHP_EVENT_NAME, EVENT_POWER_UPDATE, HARDCORE_OnPowerUpdate)
        EVENT_MANAGER:AddFilterForEvent(MINHP_EVENT_NAME, EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG, "player", REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_HEALTH)
    end
end

local function HARDCORE_DisableMinHpTracking()
    EVENT_MANAGER:UnregisterForEvent(MINHP_EVENT_NAME, EVENT_POWER_UPDATE)
end

function HARDCORE.BeginChallengeRun()
    local sv = HARDCORE.saved
    if sv.isActive then
        return
    end
    sv.isActive = true
    sv.minHealthPct = 100
    if not sv.persistedMinHealthPct then
        sv.persistedMinHealthPct = 100
    end
    HARDCORE_EnableMinHpTracking()

    if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
        HARDCORE.RuleManager:SetActive(true)
    end

    if HARDCORE.ToggleIntro then
        HARDCORE.ToggleIntro(false)
    end
end

function HARDCORE.SurrenderChallenge()
    HARDCORE.saved.isActive = false
    HARDCORE_DisableMinHpTracking()

    if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
        HARDCORE.RuleManager:SetActive(false)
    end
end

local function GetMainMenuBar()
    return MAIN_MENU_KEYBOARD and MAIN_MENU_KEYBOARD.categoryBar
end

local function DeactivateMenuButton()
    local bar = GetMainMenuBar()
    if bar then
        ZO_MenuBar_ClearSelection(bar)
    end
end

local function ActivateMenuButton()
    local bar = GetMainMenuBar()
    if bar then
        ZO_MenuBar_SelectDescriptor(bar, "HARDCORE_MAINMENU", true)
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
        categoryName = "HARDCORE",
        callback = function()
            if not HARDCORE then
                return
            end
            local bar = MAIN_MENU_KEYBOARD and MAIN_MENU_KEYBOARD.categoryBar

            if HARDCORE.saved and HARDCORE.saved.isActive then
                if GetUnitLevel("player") >= 50 then
                    HARDCORE.ShowCongratulationsWindow()
                    if bar then ZO_MenuBar_ClearSelection(bar) end
                else
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_SKILL_PURCHASED,
                        "HARDCORE: Challenge is active.")
                end
            else
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

local function HARDCORE_OnPlayerActivatedMainMenu()
    AddHardcoreMainMenuButton()
end

local function HARDCORE_OnUnitDeathStateChanged(_, unitTag, isDead)
    if isDead and HARDCORE.saved and HARDCORE.saved.isActive then
        HARDCORE.saved.hasDied = true
        HARDCORE.SurrenderChallenge()
        HARDCORE.RestoreHUDSettings()
        HARDCORE.ShowDeathWindow()
    end
end

local function HARDCORE_OnLevelUpdate(_, unitTag, newLevel)
    if newLevel >= 50 and HARDCORE.saved and HARDCORE.saved.isActive and not HARDCORE.saved.hasSeenCongrats then
        HARDCORE.ShowCongratulationsWindow()
    end
end

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

local function CreateIntroWindow()
    if HARDCORE.window then
        return
    end

    local wm = WINDOW_MANAGER

    local win = wm:CreateTopLevelWindow("HARDCORE_IntroWindow")
    HARDCORE.window = win
    win:SetMovable(false)
    win:SetMouseEnabled(true)
    win:SetClampedToScreen(true)
    win:SetResizeHandleSize(0)
    win:SetHidden(true)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, -40)
    win:SetDimensions(900, 555)

    local frame = wm:CreateControl(nil, win, CT_BACKDROP)
    frame:SetAnchorFill()
    frame:SetCenterColor(0, 0, 0, 0.88)
    frame:SetEdgeTexture("/esoui/art/chatwindow/chat_bg_edge.dds", 32, 4, 4)
    frame:SetEdgeColor(0.9, 0.85, 0.65, 1)

    local inner = wm:CreateControl("HARDCORE_Inner", win, CT_CONTROL)
    inner:SetAnchor(TOPLEFT, win, TOPLEFT, 8, 8)
    inner:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, -8, -8)

    local bg = wm:CreateControl("HARDCORE_InnerBG", inner, CT_TEXTURE)
    bg:SetAnchorFill(inner)
    bg:SetTexture("/esoui/art/loadingscreens/loadscreen_shadastear_01.dds")
    bg:SetTextureCoords(0, 1, 0, 1)
    bg:SetDrawTier(DT_LOW)
    bg:SetDrawLayer(DL_BACKGROUND)
    bg:SetAlpha(0.60)
    bg:SetBlendMode(TEX_BLEND_COLOR_ALPHA)

    local wash = wm:CreateControl("HARDCORE_InnerWash", inner, CT_BACKDROP)
    wash:SetAnchorFill(inner)
    wash:SetCenterColor(0, 0, 0, 0.40)
    wash:SetEdgeColor(0, 0, 0, 0)
    wash:SetEdgeTexture(nil, 1, 1, 0, 0)
    wash:SetDrawTier(DT_LOW)
    wash:SetDrawLayer(DL_BACKGROUND)
    wash:SetDrawLevel(1)

    local subtleEdge = wm:CreateControl("HARDCORE_InnerEdge", inner, CT_BACKDROP)
    subtleEdge:SetAnchorFill(inner)
    subtleEdge:SetCenterColor(0, 0, 0, 0)
    subtleEdge:SetEdgeTexture("/esoui/art/miscellaneous/centerscreen_announceEdge.dds", 32, 4, 4)
    subtleEdge:SetEdgeColor(0, 0, 0, 0.25)
    subtleEdge:SetDrawLayer(DL_OVERLAY)
    subtleEdge:SetDrawLevel(1)

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

    local title = wm:CreateControl(nil, inner, CT_LABEL)
    title:SetAnchor(TOP, inner, TOP, 0, 20)
    title:SetFont("$(BOLD_FONT)|38|soft-shadow-thick")
    title:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    title:SetText("HARDCORE")
    title:SetColor(COLOR.gold:UnpackRGBA())

    local iconLeft = wm:CreateControl(nil, inner, CT_TEXTURE)
    iconLeft:SetDimensions(40, 40)
    iconLeft:SetAnchor(RIGHT, title, LEFT, -12, 0)
    iconLeft:SetTexture("/esoui/art/icons/poi/poi_solotrial_incomplete.dds")

    local iconRight = wm:CreateControl(nil, inner, CT_TEXTURE)
    iconRight:SetDimensions(40, 40)
    iconRight:SetAnchor(LEFT, title, RIGHT, 12, 0)
    iconRight:SetTexture("/esoui/art/icons/poi/poi_solotrial_incomplete.dds")

    local divider = wm:CreateControl(nil, inner, CT_TEXTURE)
    divider:SetAnchor(TOP, title, BOTTOM, 0, 8)
    divider:SetDimensions(520, 8)
    divider:SetTexture("/esoui/art/miscellaneous/horizontaldivider.dds")
    divider:SetAlpha(0.55)

    local sub = wm:CreateControl(nil, inner, CT_LABEL)
    sub:SetAnchor(TOP, divider, BOTTOM, 0, 6)
    sub:SetFont("$(MEDIUM_FONT)|18|soft-shadow-thin")
    sub:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    sub:SetColor(COLOR.gray:UnpackRGBA())
    sub:SetText("Accept the challenge to enable the ruleset on this character.")
    HARDCORE.subtitle = sub

    -- Difficulty preset slider
    HARDCORE._ruleRows = {}
    local tier = (HARDCORE.saved and HARDCORE.saved.difficultyTier) or 1

    local diffLabel = wm:CreateControl(nil, inner, CT_LABEL)
    diffLabel:SetAnchor(TOP, sub, BOTTOM, 0, 10)
    diffLabel:SetFont("$(MEDIUM_FONT)|18|soft-shadow-thin")
    diffLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    diffLabel:SetColor(COLOR.gold:UnpackRGBA())
    HARDCORE.difficultyLabel = diffLabel

    local slider = wm:CreateControlFromVirtual("HARDCORE_DifficultySlider", inner, "ZO_Slider")
    slider:SetDimensions(520, 18)
    slider:SetAnchor(TOP, diffLabel, BOTTOM, 0, 10)
    slider:SetMinMax(1, 5)
    slider:SetValueStep(1)
    slider:SetAllowDraggingFromThumb(true)
    slider:SetValue(tier)
    HARDCORE.difficultySlider = slider

    slider:SetHandler("OnValueChanged", function(_, value, eventReason)
        if eventReason == EVENT_REASON_HARDWARE then
            local v = zo_round(value)
            slider:SetValue(v) -- snap
            HARDCORE.ApplyDifficultyPreset(v)
        end
    end)

    local scroll = wm:CreateControlFromVirtual("HARDCORE_RulesScroll", inner, "ZO_ScrollContainer")
    scroll:SetAnchor(TOPLEFT, inner, TOPLEFT, 24, 200)
    scroll:SetDimensions(852, 280)
    local scrollChild = scroll:GetNamedChild("ScrollChild")

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

        local bg = wm:CreateControl(nil, rowCtrl, CT_BACKDROP)
        bg:SetAnchorFill()
        bg:SetCenterColor(0, 0, 0, 0.18)
        bg:SetEdgeColor(1, 1, 1, 0.04)

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

        rowCtrl._bg = bg
        rowCtrl._icon = icon
        rowCtrl._label = label
        rowCtrl._ruleData = rule
        table.insert(HARDCORE._ruleRows, rowCtrl)

        local hitArea = wm:CreateControl(nil, rowCtrl, CT_CONTROL)
        hitArea:SetAnchorFill()
        hitArea:SetMouseEnabled(true)
        rowCtrl._hitArea = hitArea

        local function ToggleCustomRule()
            if rule.alwaysOn or not rule.ruleId then
                return
            end
            if not IsCustomDifficultyTier(HARDCORE.saved and HARDCORE.saved.difficultyTier) then
                return
            end
            if HARDCORE.saved and HARDCORE.saved.isActive then
                return
            end
            if HARDCORE._difficultyControlsEnabled == false then
                return
            end

            local sv = GetRulesSV()
            local enabled = sv.enabled[rule.ruleId] == true
            if HARDCORE.RuleManager and HARDCORE.RuleManager.SetRuleEnabled then
                HARDCORE.RuleManager:SetRuleEnabled(rule.ruleId, not enabled)
            else
                sv.enabled[rule.ruleId] = not enabled
            end
            HARDCORE.RefreshDifficultyUI()
        end

        local function OnEnter()
            label:SetColor(COLOR.gold:UnpackRGBA())
            ShowTip(rowCtrl, rule.tip)
        end

        local function OnExit()
            HideTip()
            if HARDCORE.RefreshDifficultyUI then
                HARDCORE.RefreshDifficultyUI()
            else
                label:SetColor(COLOR.white:UnpackRGBA())
            end
        end

        hitArea:SetHandler("OnMouseEnter", OnEnter)
        hitArea:SetHandler("OnMouseExit", OnExit)
        hitArea:SetHandler("OnMouseUp", ToggleCustomRule)

        return rowCtrl
    end

    for i, rule in ipairs(RULES) do
        CreateRuleRow(scrollChild, i, rule)
    end

    local savedTier = (HARDCORE.saved and HARDCORE.saved.difficultyTier) or 1
    if IsCustomDifficultyTier(savedTier) then
        HARDCORE.saved.difficultyTier = savedTier
    else
        HARDCORE.ApplyDifficultyPreset(savedTier)
    end
    HARDCORE.RefreshDifficultyUI()

    local function GetHUDSV()
        HARDCORE = HARDCORE or {}
        if not HARDCORE.hudBackup then
            HARDCORE.hudBackup = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_HUD_BACKUP", 1, nil, {
                saved = {
                    allNameplates = nil,
                    allHealthbars = nil,
                    combatCues = nil
                }
            }, GetWorldName())
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

    -- Accept / Re-enter / Surrender 
    local btn = wm:CreateControlFromVirtual("HARDCORE_ActionButton", win, "ZO_DefaultButton")
    HARDCORE.actionButton = btn
    btn:SetAnchor(BOTTOM, win, BOTTOM, 0, -18)
    btn:SetDimensions(260, 44)

    local stats = wm:CreateControl("HARDCORE_ActiveStats", win, CT_CONTROL)
    HARDCORE.activeStats = stats
    stats:SetAnchor(LEFT, btn, RIGHT, 60, 0)
    stats:SetDimensions(260, 44)
    stats:SetHidden(true)

    local classIcon = wm:CreateControl(nil, stats, CT_TEXTURE)
    stats.classIcon = classIcon
    classIcon:SetDimensions(28, 28)
    classIcon:SetAnchor(TOPLEFT, stats, TOPLEFT, 0, 8)
    classIcon:SetAlpha(0.95)

    local levelLabel = wm:CreateControl(nil, stats, CT_LABEL)
    stats.levelLabel = levelLabel
    levelLabel:SetAnchor(LEFT, classIcon, RIGHT, 6, 0)
    levelLabel:SetFont("$(BOLD_FONT)|18|soft-shadow-thin")
    levelLabel:SetColor(COLOR.white:UnpackRGBA())
    levelLabel:SetText("Lv ?")

    local minHpIcon = wm:CreateControl(nil, stats, CT_TEXTURE)
    stats.minHpIcon = minHpIcon
    minHpIcon:SetDimensions(24, 24)
    minHpIcon:SetAnchor(LEFT, levelLabel, RIGHT, 12, 0)
    minHpIcon:SetTexture("/esoui/art/icons/alchemy/crafting_alchemy_trait_restorehealth_conflict.dds")
    minHpIcon:SetAlpha(0.95)

    local arrowIcon = wm:CreateControl(nil, stats, CT_TEXTURE)
    stats.arrowIcon = arrowIcon
    arrowIcon:SetDimensions(16, 16)
    arrowIcon:SetAnchor(LEFT, minHpIcon, RIGHT, 4, 0)
    arrowIcon:SetTexture("/esoui/art/miscellaneous/gamepad/gp_scrollarrow.dds")
    arrowIcon:SetAlpha(0.95)

    local minHpLabel = wm:CreateControl(nil, stats, CT_LABEL)
    stats.minHpLabel = minHpLabel
    minHpLabel:SetAnchor(LEFT, arrowIcon, RIGHT, 4, 0)
    minHpLabel:SetFont("$(BOLD_FONT)|18|soft-shadow-thin")
    minHpLabel:SetColor(COLOR.gray:UnpackRGBA())
    minHpLabel:SetText("100%")

    local function UpdateActionButton()
        btn:SetHidden(false)

        local isActive = HARDCORE.saved and HARDCORE.saved.isActive
        if HARDCORE.SetDifficultySliderEnabled then
            HARDCORE.SetDifficultySliderEnabled(not isActive)
        end

        if isActive then
            btn:SetEnabled(true)
            btn:SetState(BSTATE_NORMAL, false)
            btn:SetText("Surrender Challenge")
            btn:SetHandler("OnMouseEnter", function()
                ShowTip(btn, "End the hardcore challenge and deactivate the rules.")
            end)
            btn:SetHandler("OnMouseExit", HideTip)
            btn:SetHandler("OnClicked", function()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
                HARDCORE.SetDifficultySliderEnabled(true)
                HARDCORE.SurrenderChallenge()
                HARDCORE.RestoreHUDSettings()
                if HARDCORE.subtitle then
                    HARDCORE.subtitle:SetText("Hardcore Mode is inactive. You can re-enter anytime.")
                end
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_SKILL_PURCHASED,
                    "HARDCORE: Challenge surrendered. Settings restored.")
                HARDCORE.UpdateActionButton()
                -- Reload UI to apply restored settings
                zo_callLater(function()
                    ReloadUI()
                end, 500)
            end)
            HARDCORE_EnableMinHpTracking()
            HARDCORE.UpdateActiveStatsUI()
        elseif HARDCORE.saved.hasDied then
            btn:SetEnabled(false)
            btn:SetState(BSTATE_DISABLED, true)
            btn:SetText("Challenge Failed")
            btn:SetHandler("OnMouseEnter", function()
                ShowTip(btn, "Your character has fallen. The challenge cannot be reactivated.")
            end)
            btn:SetHandler("OnMouseExit", HideTip)
            btn:SetHandler("OnClicked", nil)
            HARDCORE_DisableMinHpTracking()
            if HARDCORE.activeStats then
                HARDCORE.activeStats:SetHidden(true)
            end
        else
            btn:SetEnabled(true)
            btn:SetState(BSTATE_NORMAL, false)
            btn:SetText(HARDCORE.saved.hasSeenIntro and "Re-enter Challenge" or "Accept Challenge")
            btn:SetHandler("OnMouseEnter", function()
                ShowTip(btn, "Enable Hardcore Mode on this character.")
            end)
            btn:SetHandler("OnMouseExit", HideTip)
            btn:SetHandler("OnClicked", function()
                local tier = (HARDCORE.saved and tonumber(HARDCORE.saved.difficultyTier)) or 1
                local rulesSV = GetRulesSV()

                if ((tier >= 3 and not IsCustomDifficultyTier(tier)) or
                    (IsCustomDifficultyTier(tier) and rulesSV.enabled.NoCP == true)) and HARDCORE_HasAnyChampionSlotted() then
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    HARDCORE_ShowCPBlockedDialog()
                    return
                end
                HARDCORE.ToggleIntro()
                DeactivateMenuButton()
                PlaySound(SOUNDS.INSTANCE_SHUTDOWN)
                PlaySound(SOUNDS.QUEST_ACCEPTED)
                PlaySound(SOUNDS.ENDLESS_DUNGEON_SCORE_FINAL_FLIP)
                HARDCORE.SetDifficultySliderEnabled(false)
                AnnounceTrialBegins()
                HARDCORE.saved.hasSeenIntro = true
                HARDCORE.SaveHUDSettings()
                HARDCORE.BeginChallengeRun()
                if HARDCORE.RuleManager and HARDCORE.RuleManager.SetActive then
                    HARDCORE.RuleManager:SetActive(true)
                end
                if HARDCORE.ChallengeManager and HARDCORE.ChallengeManager.SetActive then
                    HARDCORE.ChallengeManager:SetActive(true)
                end
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_SKILL_PURCHASED,
                    "HARDCORE: Challenge active. Good luck!")
                if HARDCORE.subtitle then
                    HARDCORE.subtitle:SetText("HARDCORE rules are active on this character.")
                end
                HARDCORE.ToggleIntro()
            end)
            HARDCORE_DisableMinHpTracking()
            if HARDCORE.activeStats then
                HARDCORE.activeStats:SetHidden(true)
            end
        end
    end

    HARDCORE.UpdateActionButton = UpdateActionButton
    UpdateActionButton()

    local close = wm:CreateControlFromVirtual("HARDCORE_Close", win, "ZO_CloseButton")
    close:SetAnchor(TOPRIGHT, win, TOPRIGHT, -18, 14)
    close:SetHandler("OnClicked", function()
        win:SetHidden(true)
        DeactivateMenuButton()
    end)

    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local fade = timeline:InsertAnimation(ANIMATION_ALPHA, win)
    fade:SetAlphaValues(0, 1)
    fade:SetDuration(200)
    HARDCORE.fadeIn = function()
        win:SetAlpha(0)
        timeline:PlayFromStart()
    end
end

function HARDCORE.ToggleIntro(playSound)
    if not HARDCORE.window then
        CreateIntroWindow()
    end

    local hidden = HARDCORE.window:IsHidden()
    if hidden then
        HARDCORE.window:SetHidden(false)
        if HARDCORE.RefreshDifficultyUI then
            HARDCORE.RefreshDifficultyUI()
        end
        if HARDCORE.fadeIn then
            HARDCORE.fadeIn()
        end
        if HARDCORE.UpdateActionButton then
            HARDCORE.UpdateActionButton()
        end
        if HARDCORE.subtitle then
            if HARDCORE.saved.isActive then
                HARDCORE.subtitle:SetText("HARDCORE rules are active on this character.")
            elseif HARDCORE.saved.hasDied then
                HARDCORE.subtitle:SetText("This character has died. The challenge has ended permanently.")
            else
                HARDCORE.subtitle:SetText(HARDCORE.saved.hasSeenIntro and
                                              "Hardcore Mode is inactive. You can re-enter anytime." or
                                              "Accept the challenge to enable the ruleset on this character.")
            end
        end
        ActivateMenuButton()
        SetGameCameraUIMode(true)
        if playSound ~= false then
            PlaySound(SOUNDS.SKILL_XP_DARK_FISSURE_CLOSED)
        end
    else
        HARDCORE.window:SetHidden(true)
        DeactivateMenuButton()
        SetGameCameraUIMode(false)
    end
end

local function RegisterSlash()
    SLASH_COMMANDS["/hc"] = function()
        if HARDCORE.saved and HARDCORE.saved.isActive and GetUnitLevel("player") >= 50 then
            HARDCORE.ShowCongratulationsWindow()
            return
        end

        if HARDCORE.saved and HARDCORE.saved.hasDied then
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Challenge failed. You cannot reactivate it.")
        end

        if not HARDCORE.window then
            CreateIntroWindow()
        end
        HARDCORE.window:SetHidden(false)
        if HARDCORE.fadeIn then
            HARDCORE.fadeIn()
        end
        if HARDCORE.UpdateActionButton then
            HARDCORE.UpdateActionButton()
        end
        SetGameCameraUIMode(true)
        PlaySound(SOUNDS.SKILL_XP_DARK_FISSURE_CLOSED)
    end
end

local function OnAddOnLoaded(event, addonName)
    if addonName ~= ADDON_NAME then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    HARDCORE.saved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_SV", 1, nil, HARDCORE.defaults, GetWorldName())
    if HARDCORE.saved.isActive then
        if HARDCORE.saved.minHealthPct == nil then
            HARDCORE.saved.minHealthPct = 100
        end
        if HARDCORE.saved.persistedMinHealthPct == nil then
            HARDCORE.saved.persistedMinHealthPct = 100
        end
        HARDCORE_EnableMinHpTracking()
        zo_callLater(function()
            if HARDCORE.SetDifficultySliderEnabled then
                HARDCORE.SetDifficultySliderEnabled(false)
            end
        end, 100)
    end

    if HARDCORE.RuleManager and HARDCORE.RuleManager.Init then
        HARDCORE.RuleManager:Init()
    end
    local lam = LibAddonMenu2
    if lam then
        local function RefreshNoHealthBarOptions()
            local rm = HARDCORE.RuleManager
            if not (rm and rm.GetRule) then
                return
            end
            local rule = rm:GetRule("NoHealthBar")
            if rule and rule.RefreshOptions then
                rule:RefreshOptions()
            end
        end

        local panelData = {
            type = "panel",
            name = "HARDCORE",
            version = HARDCORE.version,
            displayName = "|cFFD700HARDCORE|r",
            registerForRefresh = true,
            registerForDefaults = true
        }
        lam:RegisterAddonPanel("HARDCORE_LAM", panelData)
        lam:RegisterOptionControls("HARDCORE_LAM", {{
            type = "checkbox",
            name = "Disable vision dim",
            tooltip = "Hide the health bar but skip the screen darkening/vignette effect.",
            width = "full",
            getFunc = function()
                return HARDCORE.saved and HARDCORE.saved.disableVisionDim
            end,
            setFunc = function(val)
                if HARDCORE.saved then
                    HARDCORE.saved.disableVisionDim = val and true or false
                end
                RefreshNoHealthBarOptions()
            end
        }, {
            type = "checkbox",
            name = "Disable low-health volume drop",
            tooltip = "Prevent audio volume from being reduced when your health is low.",
            width = "full",
            getFunc = function()
                return HARDCORE.saved and HARDCORE.saved.disableLowHealthVolume
            end,
            setFunc = function(val)
                if HARDCORE.saved then
                    HARDCORE.saved.disableLowHealthVolume = val and true or false
                end
                RefreshNoHealthBarOptions()
            end
        }})
    end

    CreateIntroWindow()
    RegisterSlash()

    EVENT_MANAGER:RegisterForEvent("HARDCORE_MainMenuBtn", EVENT_PLAYER_ACTIVATED, HARDCORE_OnPlayerActivatedMainMenu)

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_Death", EVENT_UNIT_DEATH_STATE_CHANGED, HARDCORE_OnUnitDeathStateChanged)
    EVENT_MANAGER:AddFilterForEvent(ADDON_NAME .. "_Death", EVENT_UNIT_DEATH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_Level", EVENT_LEVEL_UPDATE, HARDCORE_OnLevelUpdate)
    EVENT_MANAGER:AddFilterForEvent(ADDON_NAME .. "_Level", EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

    if HARDCORE.saved.isActive and GetUnitLevel("player") >= 50 and not HARDCORE.saved.hasSeenCongrats then
        zo_callLater(function()
            HARDCORE.ShowCongratulationsWindow()
        end, 2000)
    end

    if not (HARDCORE.saved.hasSeenIntro or HARDCORE.saved.isActive) then
        zo_callLater(function()
            HARDCORE.ToggleIntro(false)
        end, 600)
    end

end

function HARDCORE.ShowCongratulationsWindow()
    if HARDCORE.congratsWindow then
        HARDCORE.congratsWindow:SetHidden(false)
        return
    end

    local wm = WINDOW_MANAGER
    local win = wm:CreateTopLevelWindow("HARDCORE_CongratsWindow")
    HARDCORE.congratsWindow = win
    win:SetMovable(false)
    win:SetMouseEnabled(true)
    win:SetClampedToScreen(true)
    win:SetResizeHandleSize(0)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, -40)
    win:SetDimensions(750, 480)

    local frame = wm:CreateControl(nil, win, CT_BACKDROP)
    frame:SetAnchorFill()
    frame:SetCenterColor(0, 0, 0, 0.88)
    frame:SetEdgeTexture("/esoui/art/chatwindow/chat_bg_edge.dds", 32, 4, 4)
    frame:SetEdgeColor(0.9, 0.85, 0.65, 1)

    local inner = wm:CreateControl("HARDCORE_CongratsInner", win, CT_CONTROL)
    inner:SetAnchor(TOPLEFT, win, TOPLEFT, 8, 8)
    inner:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, -8, -8)

    local bg = wm:CreateControl("HARDCORE_CongratsInnerBG", inner, CT_TEXTURE)
    bg:SetAnchorFill(inner)
    bg:SetTexture("/esoui/art/loadingscreens/loadscreen_pantherfangchapel_01.dds")
    bg:SetTextureCoords(0, 1, 0, 1)
    bg:SetDrawTier(DT_LOW)
    bg:SetAlpha(0.60)
    bg:SetBlendMode(TEX_BLEND_COLOR_ALPHA)

    local wash = wm:CreateControl("HARDCORE_CongratsInnerWash", inner, CT_BACKDROP)
    wash:SetAnchorFill(inner)
    wash:SetCenterColor(0, 0, 0, 0.40)
    wash:SetEdgeColor(0, 0, 0, 0)
    wash:SetDrawTier(DT_LOW)
    wash:SetDrawLayer(DL_BACKGROUND)
    wash:SetDrawLevel(1)

    local subtleEdge = wm:CreateControl("HARDCORE_CongratsInnerEdge", inner, CT_BACKDROP)
    subtleEdge:SetAnchorFill(inner)
    subtleEdge:SetCenterColor(0, 0, 0, 0)
    subtleEdge:SetEdgeTexture("/esoui/art/miscellaneous/centerscreen_announceEdge.dds", 32, 4, 4)
    subtleEdge:SetEdgeColor(0, 0, 0, 0.25)
    subtleEdge:SetDrawLayer(DL_OVERLAY)
    subtleEdge:SetDrawLevel(1)

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

    Corner("HARDCORE_CongratsCornerTL", "/esoui/art/reticle/border_topleft.dds", TOPLEFT, -1, -1, 16, 16)
    Corner("HARDCORE_CongratsCornerTR", "/esoui/art/reticle/border_topright.dds", TOPRIGHT, 1, -1, 16, 16)
    Corner("HARDCORE_CongratsCornerBL", "/esoui/art/reticle/border_bottomleft.dds", BOTTOMLEFT, -1, 1, 16, 16)
    Corner("HARDCORE_CongratsCornerBR", "/esoui/art/reticle/border_bottomright.dds", BOTTOMRIGHT, 1, 1, 16, 16)

    local title = wm:CreateControl(nil, inner, CT_LABEL)
    title:SetAnchor(TOP, inner, TOP, 0, 40)
    title:SetFont("$(BOLD_FONT)|42|soft-shadow-thick")
    title:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    title:SetText("CONGRATULATIONS!")
    title:SetColor(COLOR.gold:UnpackRGBA())

    local divider = wm:CreateControl(nil, inner, CT_TEXTURE)
    divider:SetAnchor(TOP, title, BOTTOM, 0, 12)
    divider:SetDimensions(520, 8)
    divider:SetTexture("/esoui/art/miscellaneous/horizontaldivider.dds")
    divider:SetAlpha(0.55)

    local subTitle = wm:CreateControl(nil, inner, CT_LABEL)
    subTitle:SetAnchor(TOP, divider, BOTTOM, 0, 20)
    subTitle:SetFont("$(MEDIUM_FONT)|24|soft-shadow-thin")
    subTitle:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    subTitle:SetColor(COLOR.white:UnpackRGBA())
    subTitle:SetText("You have reached Level 50\nand completed the Hardcore Challenge!")

    local desc = wm:CreateControl(nil, inner, CT_LABEL)
    desc:SetAnchor(TOP, subTitle, BOTTOM, 0, 45)
    desc:SetFont("$(MEDIUM_FONT)|20")
    desc:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    desc:SetColor(COLOR.gray:UnpackRGBA())
    desc:SetText("Your trial is over. You may now choose to continue\nyour journey as a normal adventurer.")

    local btn = wm:CreateControlFromVirtual("HARDCORE_CongratsActionButton", win, "ZO_DefaultButton")
    btn:SetAnchor(BOTTOM, win, BOTTOM, 0, -35)
    btn:SetDimensions(280, 44)
    btn:SetText("End Challenge & Continue")
    btn:SetHandler("OnClicked", function()
        HARDCORE.saved.hasSeenCongrats = true
        HARDCORE.SurrenderChallenge()
        HARDCORE.RestoreHUDSettings()
        win:SetHidden(true)
        SetGameCameraUIMode(false)
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.UI_GIFT_INVENTORY_VIEW_OPEN, "Hardcore Challenge Completed!")
        zo_callLater(function() ReloadUI() end, 500)
    end)

    local close = wm:CreateControlFromVirtual("HARDCORE_CongratsClose", win, "ZO_CloseButton")
    close:SetAnchor(TOPRIGHT, win, TOPRIGHT, -18, 14)
    close:SetHandler("OnClicked", function()
        HARDCORE.saved.hasSeenCongrats = true
        win:SetHidden(true)
        SetGameCameraUIMode(false)
    end)

    SetGameCameraUIMode(true)
    PlaySound(SOUNDS.UI_GIFT_INVENTORY_VIEW_OPEN)
end

function HARDCORE.ShowDeathWindow()
    if HARDCORE.deathWindow then
        HARDCORE.deathWindow:SetHidden(false)
        return
    end

    local wm = WINDOW_MANAGER
    local win = wm:CreateTopLevelWindow("HARDCORE_DeathWindow")
    HARDCORE.deathWindow = win
    win:SetMovable(false)
    win:SetMouseEnabled(true)
    win:SetClampedToScreen(true)
    win:SetResizeHandleSize(0)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, -40)
    win:SetDimensions(750, 480)

    local frame = wm:CreateControl(nil, win, CT_BACKDROP)
    frame:SetAnchorFill()
    frame:SetCenterColor(0.05, 0, 0, 0.88)
    frame:SetEdgeTexture("/esoui/art/chatwindow/chat_bg_edge.dds", 32, 4, 4)
    frame:SetEdgeColor(0.8, 0.15, 0.15, 1)

    local inner = wm:CreateControl("HARDCORE_DeathInner", win, CT_CONTROL)
    inner:SetAnchor(TOPLEFT, win, TOPLEFT, 8, 8)
    inner:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, -8, -8)

    local bg = wm:CreateControl("HARDCORE_DeathInnerBG", inner, CT_TEXTURE)
    bg:SetAnchorFill(inner)
    bg:SetTexture("/esoui/art/loadingscreens/loadscreen_circus_of_the_cheerful_slaughter_01.dds")
    bg:SetTextureCoords(0, 1, 0, 1)
    bg:SetDrawTier(DT_LOW)
    bg:SetAlpha(0.60)
    bg:SetColor(0.8, 0.2, 0.2, 1)
    bg:SetBlendMode(TEX_BLEND_COLOR_ALPHA)

    local wash = wm:CreateControl("HARDCORE_DeathInnerWash", inner, CT_BACKDROP)
    wash:SetAnchorFill(inner)
    wash:SetCenterColor(0.2, 0, 0, 0.50)
    wash:SetEdgeColor(0, 0, 0, 0)
    wash:SetDrawTier(DT_LOW)
    wash:SetDrawLayer(DL_BACKGROUND)
    wash:SetDrawLevel(1)

    local subtleEdge = wm:CreateControl("HARDCORE_DeathInnerEdge", inner, CT_BACKDROP)
    subtleEdge:SetAnchorFill(inner)
    subtleEdge:SetCenterColor(0, 0, 0, 0)
    subtleEdge:SetEdgeTexture("/esoui/art/miscellaneous/centerscreen_announceEdge.dds", 32, 4, 4)
    subtleEdge:SetEdgeColor(0.8, 0.15, 0.15, 0.35)
    subtleEdge:SetDrawLayer(DL_OVERLAY)
    subtleEdge:SetDrawLevel(1)

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

    Corner("HARDCORE_DeathCornerTL", "/esoui/art/reticle/border_topleft.dds", TOPLEFT, -1, -1, 16, 16)
    Corner("HARDCORE_DeathCornerTR", "/esoui/art/reticle/border_topright.dds", TOPRIGHT, 1, -1, 16, 16)
    Corner("HARDCORE_DeathCornerBL", "/esoui/art/reticle/border_bottomleft.dds", BOTTOMLEFT, -1, 1, 16, 16)
    Corner("HARDCORE_DeathCornerBR", "/esoui/art/reticle/border_bottomright.dds", BOTTOMRIGHT, 1, 1, 16, 16)

    local title = wm:CreateControl(nil, inner, CT_LABEL)
    title:SetAnchor(TOP, inner, TOP, 0, 40)
    title:SetFont("$(BOLD_FONT)|42|soft-shadow-thick")
    title:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    title:SetText("YOU DIED")
    title:SetColor(COLOR.red:UnpackRGBA())

    local divider = wm:CreateControl(nil, inner, CT_TEXTURE)
    divider:SetAnchor(TOP, title, BOTTOM, 0, 12)
    divider:SetDimensions(520, 8)
    divider:SetTexture("/esoui/art/miscellaneous/horizontaldivider.dds")
    divider:SetAlpha(0.55)
    divider:SetColor(COLOR.red:UnpackRGBA())

    local subTitle = wm:CreateControl(nil, inner, CT_LABEL)
    subTitle:SetAnchor(TOP, divider, BOTTOM, 0, 20)
    subTitle:SetFont("$(MEDIUM_FONT)|24|soft-shadow-thin")
    subTitle:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    subTitle:SetColor(COLOR.white:UnpackRGBA())
    subTitle:SetText("Your Hardcore journey has met a tragic end.")

    local desc = wm:CreateControl(nil, inner, CT_LABEL)
    desc:SetAnchor(TOP, subTitle, BOTTOM, 0, 45)
    desc:SetFont("$(MEDIUM_FONT)|20")
    desc:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    desc:SetColor(COLOR.gray:UnpackRGBA())
    desc:SetText("\nYou may continue on this character as a normal adventurer.")

    local btn = wm:CreateControlFromVirtual("HARDCORE_DeathActionButton", win, "ZO_DefaultButton")
    btn:SetAnchor(BOTTOM, win, BOTTOM, 0, -35)
    btn:SetDimensions(280, 44)
    btn:SetText("Accept Fate")
    btn:SetHandler("OnClicked", function()
        win:SetHidden(true)
        SetGameCameraUIMode(false)
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.ABILITY_SKILL_PURCHASED, "Hardcore Challenge Failed.")
        zo_callLater(function() ReloadUI() end, 500)
    end)

    local close = wm:CreateControlFromVirtual("HARDCORE_DeathClose", win, "ZO_CloseButton")
    close:SetAnchor(TOPRIGHT, win, TOPRIGHT, -18, 14)
    close:SetHandler("OnClicked", function()
        win:SetHidden(true)
        SetGameCameraUIMode(false)
    end)

    SetGameCameraUIMode(true)
    PlaySound(SOUNDS.ENDLESS_DUNGEON_RUN_COMPLETE)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
