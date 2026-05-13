local HARDCORE = HARDCORE

local ID = "RoadWeariness"
local NS = "HARDCORE_RoadWeariness"

local TICK_MS = 1000
local FATIGUE_DRAIN_MS = 150 * 60 * 1000
local RESTORE_MS = 3 * 60 * 1000
local STAMINA_DRAIN_MULTIPLIER = 18
local ACTION_DRAIN = 0.35
local COMBAT_DRAIN = 0.20
local WARNING_LOW = 35
local WARNING_CRITICAL = 15
local WEAPON_LOCK_THRESHOLD = 10

local ICON_FATIGUE = "/esoui/art/ava/ava_rankicon64_prefect.dds"
local METER_FRAME_TEXTURE = "/esoui/art/actionbar/abilityframe64_up.dds"
local METER_GLOW_TEXTURE = "/esoui/art/actionbar/abilityframe64_glow.dds"

local Rule = {
    id = ID,
    title = "Road Weariness: fatigue from exertion and battle",
    icon = ICON_FATIGUE,
    defaultEnabled = false
}

Rule.active = false
Rule._installed = false
Rule._lastStamina = nil
Rule._lastCombatDrainMs = 0
Rule._resting = false
Rule._previousSlash = {}

local hudTLW
local fatigueFill
local fatigueValue
local fatigueLabel
local fatiguePulse
local fatigueShade
local pulseTimeline

local function GetSV()
    HARDCORE = HARDCORE or {}
    if not HARDCORE.roadWearinessSaved then
        HARDCORE.roadWearinessSaved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_ROAD_WEARINESS_SV", 1, nil, {
            fatigue = 100,
            lastUpdateMs = 0,
            hud = {
                x = 478,
                y = 710,
                unlocked = false,
                showLabels = true
            },
            warnings = {
                low = false,
                critical = false,
                empty = false,
                weapons = false
            }
        }, GetWorldName())
    end

    local sv = HARDCORE.roadWearinessSaved
    sv.fatigue = tonumber(sv.fatigue) or 100
    sv.lastUpdateMs = tonumber(sv.lastUpdateMs) or 0
    sv.hud = sv.hud or {}
    if sv.hud.x == nil then sv.hud.x = 478 end
    if sv.hud.y == nil then sv.hud.y = 710 end
    if sv.hud.unlocked == nil then sv.hud.unlocked = false end
    if sv.hud.showLabels == nil then sv.hud.showLabels = true end
    sv.warnings = sv.warnings or {}
    return sv
end

local function IsOnHud()
    return SCENE_MANAGER and (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui") or SCENE_MANAGER:IsShowing("gamepad_hud"))
end

local function IsDead()
    return IsUnitDead and IsUnitDead("player")
end

local function ClampMeter(value)
    return zo_clamp(tonumber(value) or 0, 0, 100)
end

local function Alert(text, sound)
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, sound or SOUNDS.NEGATIVE_CLICK, text)
end

local function IsHardcoreActive()
    return HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive
end

local function ResetWarningFlags()
    local sv = GetSV()
    sv.warnings.low = false
    sv.warnings.critical = false
    sv.warnings.empty = false
    sv.warnings.weapons = false
end

local function IsRestingInteraction()
    if IsInteracting and IsPlayerInteractingWithObject and GetInteractionType then
        return IsInteracting() and IsPlayerInteractingWithObject() and GetInteractionType() == INTERACTION_FURNITURE
    end
    return false
end

local function StartResting(reason)
    if not Rule.active then
        return
    end
    Rule._resting = true
    if reason then
        Alert("HARDCORE: Resting. Weariness is recovering.", SOUNDS.QUEST_OBJECTIVE_STARTED)
    end
end

local function StopResting()
    Rule._resting = false
end

local REST_SLASHES = {
    ["/sit"] = true,
    ["/sleep"] = true,
    ["/liedown"] = true,
    ["/sleeping"] = true
}

local function IsRestEmoteSlash(slashName)
    slashName = string.lower(tostring(slashName or ""))
    return REST_SLASHES[slashName] == true
end

local function FindRestEmoteIndex(slashName)
    slashName = string.lower(slashName)
    if GetNumEmotes and GetEmoteInfo then
        for i = 1, GetNumEmotes() do
            local candidate = GetEmoteInfo(i)
            if candidate and string.lower(candidate) == slashName then
                return i
            end
        end
    end
    if GetEmoteIndex then
        local id = tonumber(string.match(slashName, "%d+"))
        if id then
            return GetEmoteIndex(id)
        end
    end
    return nil
end

local function PlayRestEmote(slashName)
    local emoteIndex = FindRestEmoteIndex(slashName)
    if emoteIndex and PlayEmoteByIndex then
        PlayEmoteByIndex(emoteIndex)
    else
        local previous = Rule._previousSlash[slashName]
        if previous then
            previous("")
        end
    end
    StartResting(true)
end

local function ApplyHudPosition()
    if not hudTLW then
        return
    end
    local sv = GetSV()
    local rootW = GuiRoot and GuiRoot.GetWidth and GuiRoot:GetWidth() or 0
    local rootH = GuiRoot and GuiRoot.GetHeight and GuiRoot:GetHeight() or 0
    local hudW = hudTLW.GetWidth and hudTLW:GetWidth() or 58
    local hudH = hudTLW.GetHeight and hudTLW:GetHeight() or 76
    if rootW > 0 then
        sv.hud.x = zo_clamp(tonumber(sv.hud.x) or 478, 0, zo_max(0, rootW - hudW))
    end
    if rootH > 0 then
        sv.hud.y = zo_clamp(tonumber(sv.hud.y) or 710, 0, zo_max(0, rootH - hudH))
    end
    hudTLW:ClearAnchors()
    hudTLW:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, sv.hud.x, sv.hud.y)
end

local function CreateMeter(parent, name, iconTexture, colorR, colorG, colorB)
    local wm = WINDOW_MANAGER
    local meter = wm:CreateControl(name, parent, CT_CONTROL)
    meter:SetAnchor(LEFT, parent, LEFT, 2, 0)
    meter:SetDimensions(54, 74)

    local glow = wm:CreateControl(nil, meter, CT_TEXTURE)
    glow:SetAnchor(TOP, meter, TOP, 0, 1)
    glow:SetDimensions(54, 54)
    glow:SetTexture(METER_GLOW_TEXTURE)
    glow:SetColor(colorR, colorG, colorB, 1)
    glow:SetAlpha(0.20)
    glow:SetBlendMode(TEX_BLEND_ADD)

    local bg = wm:CreateControl(nil, meter, CT_BACKDROP)
    bg:SetAnchor(TOP, meter, TOP, 0, 2)
    bg:SetDimensions(50, 50)
    bg:SetCenterColor(0.01, 0.012, 0.012, 0.94)
    bg:SetEdgeColor(0, 0, 0, 0)

    local fill = wm:CreateControl(nil, meter, CT_BACKDROP)
    fill:SetAnchor(TOP, meter, TOP, 0, 2)
    fill:SetDimensions(48, 48)
    fill:SetCenterColor(colorR, colorG, colorB, 0.90)
    fill:SetEdgeColor(0, 0, 0, 0)
    fill:SetAlpha(0.62)

    local shade = wm:CreateControl(nil, meter, CT_BACKDROP)
    shade:SetAnchor(TOP, meter, TOP, 0, 2)
    shade:SetDimensions(48, 48)
    shade:SetCenterColor(0, 0, 0, 1)
    shade:SetEdgeColor(0, 0, 0, 0)
    shade:SetAlpha(0)

    local pulse = wm:CreateControl(nil, meter, CT_TEXTURE)
    pulse:SetAnchor(TOP, meter, TOP, 0, 2)
    pulse:SetDimensions(50, 50)
    pulse:SetTexture("/esoui/art/quest/texthighlight.dds")
    pulse:SetColor(colorR, colorG, colorB, 1)
    pulse:SetAlpha(0)
    pulse:SetBlendMode(TEX_BLEND_ADD)

    local icon = wm:CreateControl(nil, meter, CT_TEXTURE)
    icon:SetAnchor(TOP, meter, TOP, 0, 12)
    icon:SetDimensions(27, 27)
    icon:SetTexture(iconTexture)
    icon:SetColor(0.95, 0.98, 0.96, 1)

    local frame = wm:CreateControl(nil, meter, CT_TEXTURE)
    frame:SetAnchor(TOP, meter, TOP, 0, 0)
    frame:SetDimensions(54, 54)
    frame:SetTexture(METER_FRAME_TEXTURE)
    frame:SetColor(0.94, 0.82, 0.48, 0.96)

    local value = wm:CreateControl(nil, meter, CT_LABEL)
    value:SetAnchor(TOP, meter, TOP, 0, 38)
    value:SetDimensions(34, 13)
    value:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    value:SetFont("$(BOLD_FONT)|11|soft-shadow-thick")
    value:SetColor(1, 0.96, 0.82, 0.96)

    local label = wm:CreateControl(nil, meter, CT_LABEL)
    label:SetAnchor(TOP, meter, TOP, 0, 58)
    label:SetDimensions(54, 13)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetFont("$(MEDIUM_FONT)|10|soft-shadow-thin")
    label:SetColor(0.82, 0.78, 0.66, 0.92)
    label:SetText("REST")

    return fill, value, label, pulse, shade
end

local function EnsureHud()
    if hudTLW then
        return
    end

    local wm = WINDOW_MANAGER
    hudTLW = wm:CreateTopLevelWindow("HARDCORE_RoadWearinessHUD")
    hudTLW:SetDimensions(58, 76)
    hudTLW:SetDrawTier(DT_HIGH)
    hudTLW:SetDrawLayer(DL_OVERLAY)
    hudTLW:SetDrawLevel(9201)
    hudTLW:SetMouseEnabled(false)
    hudTLW:SetMovable(false)
    hudTLW:SetClampedToScreen(true)
    hudTLW:SetHidden(true)

    local bg = wm:CreateControl(nil, hudTLW, CT_TEXTURE)
    bg:SetAnchor(TOP, hudTLW, TOP, 0, 4)
    bg:SetDimensions(58, 54)
    bg:SetTexture("/esoui/art/actionbar/backrow_abilityframe_overlay.dds")
    bg:SetColor(0.025, 0.020, 0.014, 0.46)
    bg:SetAlpha(0.42)

    fatigueFill, fatigueValue, fatigueLabel, fatiguePulse, fatigueShade = CreateMeter(hudTLW, "HARDCORE_RoadWearinessFatigue", ICON_FATIGUE, 0.72, 0.60, 0.92)

    hudTLW:SetHandler("OnMoveStop", function()
        local sv = GetSV()
        sv.hud.x = zo_round(hudTLW:GetLeft())
        sv.hud.y = zo_round(hudTLW:GetTop())
        ApplyHudPosition()
    end)

    pulseTimeline = ANIMATION_MANAGER:CreateTimeline()
    local aIn = pulseTimeline:InsertAnimation(ANIMATION_ALPHA, fatiguePulse, 0)
    aIn:SetAlphaValues(0.05, 0.38)
    aIn:SetDuration(450)
    local aOut = pulseTimeline:InsertAnimation(ANIMATION_ALPHA, fatiguePulse, 450)
    aOut:SetAlphaValues(0.38, 0.05)
    aOut:SetDuration(450)
    pulseTimeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)

    ApplyHudPosition()
end

local function UpdateLockState()
    if not hudTLW then
        return
    end
    local unlocked = GetSV().hud.unlocked == true
    hudTLW:SetMouseEnabled(unlocked)
    hudTLW:SetMovable(unlocked)
end

local function UpdateVisibility()
    if hudTLW then
        hudTLW:SetHidden(not (Rule.active and IsOnHud()))
    end
end

local function CheckWarnings()
    local sv = GetSV()
    local fatigue = ClampMeter(sv.fatigue)
    if fatigue <= 0 and not sv.warnings.empty then
        sv.warnings.empty = true
        Alert("HARDCORE: You are exhausted.", SOUNDS.NEGATIVE_CLICK)
    elseif fatigue <= WARNING_CRITICAL and not sv.warnings.critical then
        sv.warnings.critical = true
        Alert("HARDCORE: Weariness is critical.", SOUNDS.DUEL_START)
    elseif fatigue <= WARNING_LOW and not sv.warnings.low then
        sv.warnings.low = true
        Alert("HARDCORE: Weariness is setting in.", SOUNDS.QUEST_ACCEPTED)
    end
end

local function UpdateHud()
    EnsureHud()
    local sv = GetSV()
    local fatigue = ClampMeter(sv.fatigue)

    fatigueFill:SetAlpha(0.07 + (fatigue / 100) * 0.48)
    fatigueShade:SetAlpha(0.18 + ((1 - (fatigue / 100)) * 0.78))
    fatigueValue:SetText(tostring(zo_round(fatigue)))

    if fatigue <= WARNING_CRITICAL then
        fatigueValue:SetColor(0.86, 0.64, 1, 1)
    else
        fatigueValue:SetColor(1, 0.96, 0.82, 0.96)
    end

    fatigueLabel:SetHidden(not (sv.hud.showLabels == true))
    local critical = fatigue <= WARNING_CRITICAL
    fatiguePulse:SetHidden(not critical)
    if critical then
        if pulseTimeline and not pulseTimeline:IsPlaying() then
            pulseTimeline:PlayFromStart()
        end
    elseif pulseTimeline and pulseTimeline:IsPlaying() then
        pulseTimeline:Stop()
        fatiguePulse:SetAlpha(0)
    end

    UpdateLockState()
    UpdateVisibility()
end

local function ChangeFatigue(delta)
    if not Rule.active or delta == 0 then
        return
    end
    local sv = GetSV()
    local old = ClampMeter(sv.fatigue)
    sv.fatigue = ClampMeter(old + delta)
    if sv.fatigue > WARNING_LOW then
        ResetWarningFlags()
    end
    CheckWarnings()
    UpdateHud()
end

local WEAPON_SLOTS = {
    EQUIP_SLOT_MAIN_HAND,
    EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_BACKUP_MAIN,
    EQUIP_SLOT_BACKUP_OFF
}

local function EnforceWeaponFatigue()
    if not Rule.active or IsDead() or (IsUnitInCombat and IsUnitInCombat("player")) then
        return
    end
    local sv = GetSV()
    if ClampMeter(sv.fatigue) > WEAPON_LOCK_THRESHOLD then
        sv.warnings.weapons = false
        return
    end

    local removedAny = false
    for _, equipSlot in ipairs(WEAPON_SLOTS) do
        local hasItem, _icon, _heldSlot, _heldNow, locked = GetWornItemInfo(BAG_WORN, equipSlot)
        if hasItem and not locked then
            RequestUnequipItem(BAG_WORN, equipSlot)
            removedAny = true
        end
    end
    if removedAny and not sv.warnings.weapons then
        sv.warnings.weapons = true
        Alert("HARDCORE: Too weary to keep weapons equipped. Rest first.", SOUNDS.NEGATIVE_CLICK)
    end
end

local function AdvanceFatigue()
    if not Rule.active then
        return
    end

    local sv = GetSV()
    local now = GetFrameTimeMilliseconds()
    if sv.lastUpdateMs <= 0 then
        sv.lastUpdateMs = now
        return
    end

    local elapsed = now - sv.lastUpdateMs
    if elapsed <= 0 then
        return
    end
    sv.lastUpdateMs = now

    if not IsHardcoreActive() or IsDead() then
        UpdateHud()
        return
    end

    if Rule._resting and ((IsPlayerMoving and IsPlayerMoving()) or (IsUnitInCombat and IsUnitInCombat("player"))) then
        StopResting()
    end

    local resting = Rule._resting or IsRestingInteraction()
    local delta = 0
    if resting then
        delta = (elapsed / RESTORE_MS) * 100
    else
        delta = -((elapsed / FATIGUE_DRAIN_MS) * 100)
        if IsPlayerMoving and IsPlayerMoving() and GetUnitPower then
            local stamina, maxStamina = GetUnitPower("player", COMBAT_MECHANIC_FLAGS_STAMINA)
            if Rule._lastStamina and stamina and maxStamina and maxStamina > 0 and stamina < Rule._lastStamina then
                delta = delta - (((Rule._lastStamina - stamina) / maxStamina) * STAMINA_DRAIN_MULTIPLIER)
            end
            Rule._lastStamina = stamina
        end
    end

    ChangeFatigue(delta)
    EnforceWeaponFatigue()
end

local function RegisterUpdateLoops()
    EVENT_MANAGER:UnregisterForUpdate(NS .. "_TICK")
    if Rule.active then
        EVENT_MANAGER:RegisterForUpdate(NS .. "_TICK", TICK_MS, AdvanceFatigue)
    end
end

local function HookScenes()
    local function SetupScene(sceneName)
        local scene = SCENE_MANAGER and SCENE_MANAGER:GetScene(sceneName)
        if not scene then
            return
        end
        scene:RegisterCallback("StateChange", function(_, newState)
            if not Rule.active then
                return
            end
            if newState == SCENE_SHOWING then
                UpdateHud()
            elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN then
                UpdateVisibility()
            end
        end)
    end
    SetupScene("hud")
    SetupScene("hudui")
    SetupScene("gamepad_hud")
end

local function RegisterRestSlashCommands()
    for slashName in pairs(REST_SLASHES) do
        if not Rule._previousSlash[slashName] then
            Rule._previousSlash[slashName] = SLASH_COMMANDS[slashName]
        end
        SLASH_COMMANDS[slashName] = function()
            PlayRestEmote(slashName)
        end
    end
end

local function Install()
    if Rule._installed then
        return
    end

    EnsureHud()
    HookScenes()
    RegisterRestSlashCommands()

    if ZO_PreHook and PlayEmoteByIndex then
        ZO_PreHook("PlayEmoteByIndex", function(emoteIndex)
            if not Rule.active then
                return
            end
            local slashName = GetEmoteSlashNameByIndex and GetEmoteSlashNameByIndex(emoteIndex)
            if IsRestEmoteSlash(slashName) then
                StartResting(true)
            end
        end)
    end

    EVENT_MANAGER:RegisterForEvent(NS .. "_ACTION", EVENT_ACTION_SLOT_ABILITY_USED, function()
        if Rule.active and IsHardcoreActive() then
            StopResting()
            ChangeFatigue(-ACTION_DRAIN)
        end
    end)
    EVENT_MANAGER:RegisterForEvent(NS .. "_COMBAT", EVENT_COMBAT_EVENT, function(_, result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType, _sourceName, sourceType)
        if not Rule.active or isError or sourceType ~= COMBAT_UNIT_TYPE_PLAYER then
            return
        end
        if result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_BLOCKED_DAMAGE or result == ACTION_RESULT_DAMAGE_SHIELDED then
            local now = GetFrameTimeMilliseconds()
            if now - Rule._lastCombatDrainMs >= 650 then
                Rule._lastCombatDrainMs = now
                StopResting()
                ChangeFatigue(-COMBAT_DRAIN)
            end
        end
    end)
    EVENT_MANAGER:RegisterForEvent(NS .. "_INTERACTION_END", EVENT_INTERACTION_ENDED, function(_, interactType)
        if interactType == INTERACTION_FURNITURE then
            StopResting()
        end
    end)
    EVENT_MANAGER:RegisterForEvent(NS .. "_ACTIVATED", EVENT_PLAYER_ACTIVATED, function()
        if not Rule.active then
            return
        end
        GetSV().lastUpdateMs = GetFrameTimeMilliseconds()
        Rule._lastStamina = nil
        UpdateHud()
    end)
    EVENT_MANAGER:RegisterForEvent(NS .. "_RESIZE", EVENT_SCREEN_RESIZED, ApplyHudPosition)

    Rule._installed = true
end

function Rule:OnEnable()
    self.active = true
    local sv = GetSV()
    sv.lastUpdateMs = GetFrameTimeMilliseconds()
    Install()
    RegisterUpdateLoops()
    UpdateHud()
end

function Rule:OnDisable()
    self.active = false
    EVENT_MANAGER:UnregisterForUpdate(NS .. "_TICK")
    StopResting()
    if pulseTimeline and pulseTimeline:IsPlaying() then
        pulseTimeline:Stop()
    end
    if hudTLW then
        hudTLW:SetHidden(true)
        hudTLW:SetMouseEnabled(false)
        hudTLW:SetMovable(false)
    end
end

function Rule:RefreshOptions()
    UpdateHud()
end

function Rule:ResetMeter()
    local sv = GetSV()
    sv.fatigue = 100
    sv.lastUpdateMs = GetFrameTimeMilliseconds()
    sv.warnings = {}
    UpdateHud()
end

function Rule:ResetHudPosition()
    local sv = GetSV()
    sv.hud.x = 478
    sv.hud.y = 710
    ApplyHudPosition()
    UpdateHud()
end

function HARDCORE.GetRoadWearinessSV()
    return GetSV()
end

function HARDCORE.RefreshRoadWearinessOptions()
    Rule:RefreshOptions()
end

function HARDCORE.ResetRoadWearinessMeter()
    Rule:ResetMeter()
end

function HARDCORE.ResetRoadWearinessHudPosition()
    Rule:ResetHudPosition()
end

function HARDCORE.DebugRoadWearinessStatus()
    local sv = GetSV()
    d("Road Weariness active=" .. tostring(Rule.active) ..
        " fatigue=" .. tostring(zo_round(ClampMeter(sv.fatigue))) ..
        " resting=" .. tostring(Rule._resting) ..
        " hud=(" .. tostring(sv.hud.x) .. "," .. tostring(sv.hud.y) .. ")" ..
        " unlocked=" .. tostring(sv.hud.unlocked))
end

function HARDCORE.DebugRoadWearinessCommand(action, arg1)
    action = action or "help"
    local sv = GetSV()

    if action == "help" then
        d("Road Weariness debug:")
        d("/hc debug weariness full")
        d("/hc debug weariness empty")
        d("/hc debug weariness set <fatigue>")
        d("/hc debug weariness rest")
        d("/hc debug weariness stop")
        d("/hc debug weariness hud")
        return
    end

    if action == "full" then
        Rule:ResetMeter()
        d("Road Weariness: fatigue set to full.")
        return
    end

    if action == "empty" then
        sv.fatigue = 0
        sv.lastUpdateMs = GetFrameTimeMilliseconds()
        CheckWarnings()
        EnforceWeaponFatigue()
        UpdateHud()
        d("Road Weariness: fatigue emptied.")
        return
    end

    if action == "set" then
        local fatigue = tonumber(arg1)
        if not fatigue then
            d("Usage: /hc debug weariness set <fatigue>")
            return
        end
        sv.fatigue = ClampMeter(fatigue)
        sv.lastUpdateMs = GetFrameTimeMilliseconds()
        CheckWarnings()
        UpdateHud()
        d("Road Weariness: fatigue=" .. tostring(zo_round(sv.fatigue)))
        return
    end

    if action == "rest" then
        StartResting(true)
        d("Road Weariness: forced rest started.")
        return
    end

    if action == "stop" then
        StopResting()
        d("Road Weariness: forced rest stopped.")
        return
    end

    if action == "hud" then
        EnsureHud()
        UpdateHud()
        if hudTLW then
            hudTLW:SetHidden(false)
        end
        d("Road Weariness: HUD forced visible until the next scene/update refresh.")
        return
    end

    d("Unknown Road Weariness debug action: " .. tostring(action))
end

HARDCORE.RuleManager:RegisterRule(Rule)
