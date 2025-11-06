-- Rule_HardcoreHUD.lua
-- Hides nameplates/healthbars/target frame/combat cues/action bar on enable,
-- briefly & faintly peeks the action bar on entering combat / weapon swap,
-- restores/unhides on disable.
local ID = "HardcoreHUD"

-- >>> Tweakables for the action bar peek <<<
local PEEK_FADE_IN_MS = 120
local PEEK_HOLD_MS = 300 -- shorter hold
local PEEK_FADE_OUT_MS = 120
local PEEK_MAX_ALPHA = 0.30 -- harder to see (30%)

local function log(msg)
    if msg then
        d(string.format("[HARDCORE][%s] %s", ID, tostring(msg)))
    end
end

-- Per-character saved vars for this rule
local function GetSV()
    HARDCORE = HARDCORE or {}
    if not HARDCORE.hudSaved then
        HARDCORE.hudSaved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_HUD_SV", 1, nil, {
            prev = {
                allNameplates = nil,
                allHealthbars = nil,
                combatCues = nil
            }
        })
    end
    return HARDCORE.hudSaved
end

-- Helpers
local function toSetting(v)
    return v and "1" or "0"
end

-- Nameplates/Healthbars
local function getNameplates()
    return GetSetting_Bool(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_NAMEPLATES)
end
local function setNameplates(enabledBool)
    SetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_NAMEPLATES, toSetting(enabledBool))
end
local function getHealthbars()
    return GetSetting_Bool(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_HEALTHBARS)
end
local function setHealthbars(enabledBool)
    SetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_HEALTHBARS, toSetting(enabledBool))
end

-- Combat Cues (Monster Tells / AOEs etc.)
local function getCombatCues()
    return GetSetting_Bool(SETTING_TYPE_COMBAT, COMBAT_SETTING_MONSTER_TELLS_ENABLED)
end
local function setCombatCues(enabledBool)
    SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_MONSTER_TELLS_ENABLED, toSetting(enabledBool))
end

-- Target frame (unitTag "reticleover")
local HIDE_REASON = "HardcoreHUD"
local function hideTargetFrame(yes)
    if UNIT_FRAMES and UNIT_FRAMES.SetFrameHiddenForReason then
        UNIT_FRAMES:SetFrameHiddenForReason("reticleover", HIDE_REASON, yes and true or false)
    end
end

-- Action bar base hide/unhide
local function hideActionBar(yes)
    if ACTION_BAR_FRAGMENT and ACTION_BAR_FRAGMENT.SetHiddenForReason then
        ACTION_BAR_FRAGMENT:SetHiddenForReason(HIDE_REASON, yes and true or false)
    end
    if ZO_ActionBar1 then
        ZO_ActionBar1:SetHidden(yes and true or false)
    end
end

-- --- Action bar "peek" animation (shorter + fainter) ---
local fadeTimeline
local function EnsureFadeTimeline()
    if fadeTimeline or not ZO_ActionBar1 then
        return
    end

    local tl = ANIMATION_MANAGER:CreateTimeline()

    local aIn = tl:InsertAnimation(ANIMATION_ALPHA, ZO_ActionBar1, 0)
    aIn:SetAlphaValues(0, PEEK_MAX_ALPHA)
    aIn:SetDuration(PEEK_FADE_IN_MS)
    if aIn.SetEasingFunction and ZO_EaseInQuadratic then
        aIn:SetEasingFunction(ZO_EaseInQuadratic)
    end

    local hold = tl:InsertAnimation(ANIMATION_NONE, ZO_ActionBar1, PEEK_FADE_IN_MS)
    hold:SetDuration(PEEK_HOLD_MS)

    local aOut = tl:InsertAnimation(ANIMATION_ALPHA, ZO_ActionBar1, PEEK_FADE_IN_MS + PEEK_HOLD_MS)
    aOut:SetAlphaValues(PEEK_MAX_ALPHA, 0)
    aOut:SetDuration(PEEK_FADE_OUT_MS)
    if aOut.SetEasingFunction and ZO_EaseOutQuadratic then
        aOut:SetEasingFunction(ZO_EaseOutQuadratic)
    end

    tl:SetHandler("OnPlay", function()
        if ACTION_BAR_FRAGMENT and ACTION_BAR_FRAGMENT.SetHiddenForReason then
            ACTION_BAR_FRAGMENT:SetHiddenForReason(HIDE_REASON, false)
        end
        ZO_ActionBar1:SetHidden(false)
        ZO_ActionBar1:SetAlpha(0)
        -- make it non-interactive during the peek (optional, defensive)
        if ZO_ActionBar1.SetMouseEnabled then
            ZO_ActionBar1:SetMouseEnabled(false)
        end
    end)

    tl:SetHandler("OnStop", function()
        ZO_ActionBar1:SetAlpha(1) -- reset for next time
        if ZO_ActionBar1.SetMouseEnabled then
            ZO_ActionBar1:SetMouseEnabled(true)
        end
        hideActionBar(true) -- hide again under our reason
    end)

    fadeTimeline = tl
end

local function FlashActionBar()
    if not ZO_ActionBar1 then
        return
    end
    EnsureFadeTimeline()
    if not fadeTimeline then
        return
    end
    if fadeTimeline:IsPlaying() then
        fadeTimeline:Stop()
    end
    fadeTimeline:PlayFromStart()
end

-- Re-apply hides on load
local function applyAllHides()
    setNameplates(false)
    setHealthbars(false)
    setCombatCues(false)
    hideTargetFrame(true)
    hideActionBar(true)
end

-- Rule
local Rule = {
    id = ID,
    title = "Hide nameplates, healthbars, target frame, combat cues & action bar (subtle peek)",
    icon = "/esoui/art/tutorial/examples/help-gamepad-statusbars-health_mini.dds",
    defaultEnabled = true
}

function Rule:OnEnable()
    local sv = GetSV()

    -- snapshot
    sv.prev.allNameplates = getNameplates()
    sv.prev.allHealthbars = getHealthbars()
    sv.prev.combatCues = getCombatCues()

    -- apply now
    applyAllHides()

    -- ensure UI-ready apply
    if not self._appliedListener then
        self._appliedListener = true
        local function OnPlayerActivated()
            applyAllHides()
            EVENT_MANAGER:UnregisterForEvent(ID .. "_APPLY", EVENT_PLAYER_ACTIVATED)
        end
        EVENT_MANAGER:RegisterForEvent(ID .. "_APPLY", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    end

    -- peek triggers
    local function OnCombatState(_, inCombat)
        if inCombat then
            FlashActionBar()
        end
    end
    local function OnWeaponSwap()
        FlashActionBar()
    end

    EVENT_MANAGER:RegisterForEvent(ID .. "_COMBAT", EVENT_PLAYER_COMBAT_STATE, OnCombatState)
    EVENT_MANAGER:RegisterForEvent(ID .. "_WEAPON", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnWeaponSwap)

    log("Hardcore HUD active: action bar hidden with a short, faint peek on combat enter / weapon swap")
end

function Rule:OnDisable()
    local sv = GetSV()

    -- unregister events
    EVENT_MANAGER:UnregisterForEvent(ID .. "_COMBAT", EVENT_PLAYER_COMBAT_STATE)
    EVENT_MANAGER:UnregisterForEvent(ID .. "_WEAPON", EVENT_ACTIVE_WEAPON_PAIR_CHANGED)
    EVENT_MANAGER:UnregisterForEvent(ID .. "_APPLY", EVENT_PLAYER_ACTIVATED)

    -- stop any running animation
    if fadeTimeline and fadeTimeline:IsPlaying() then
        fadeTimeline:Stop()
    end

    -- restore settings
    if sv.prev.allNameplates ~= nil then
        setNameplates(sv.prev.allNameplates)
    end
    if sv.prev.allHealthbars ~= nil then
        setHealthbars(sv.prev.allHealthbars)
    end
    if sv.prev.combatCues ~= nil then
        setCombatCues(sv.prev.combatCues)
    end

    -- unhide HUD elements
    hideTargetFrame(false)
    hideActionBar(false)

    -- clear snapshot
    sv.prev.allNameplates = nil
    sv.prev.allHealthbars = nil
    sv.prev.combatCues = nil

    log("Hardcore HUD disabled: restored settings and HUD")
end

-- Register
HARDCORE = HARDCORE or {}
HARDCORE.RuleManager = HARDCORE.RuleManager or {}
if HARDCORE.RuleManager.RegisterRule then
    HARDCORE.RuleManager:RegisterRule(Rule)
end
