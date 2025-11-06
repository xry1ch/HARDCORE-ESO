local Rule = {
    id = "NoHealthBar",
    title = "Hide player Health bar (vision fades with missing health)",
    icon = "/esoui/art/tutorial/examples/help-gamepad-statusbars-health_mini.dds",
    defaultEnabled = true
}

local NS = "HARDCORE_NoHealthBar"
Rule.active = false
Rule._installed = false

-- === Tweakables ============================================================
local MAX_DARKEN_ALPHA = 0.85 -- maximum darkness at 0% health
local CURVE_STRENGTH = 1.15 -- >1 pushes more darkness into low health, <1 linear
local LOW_HP_THRESHOLD = 0.35 -- start red pulse below 35% HP
local PULSE_MIN_ALPHA = 0.08 -- minimum red pulse alpha
local PULSE_MAX_ALPHA = 0.25 -- maximum red pulse alpha (added on top of darken)
local PULSE_PERIOD_MS = 900 -- full in-out period

-- === Logging ===============================================================
local function log(msg)
    if msg then
        d(string.format("[HARDCORE][%s] %s", Rule.id, tostring(msg)))
    end
end

-- === Health helpers ========================================================
local function GetPlayerHealthPercent()
    -- GetUnitPower returns: current, max, effectiveMax
    local cur, max = GetUnitPower("player", POWERTYPE_HEALTH)
    if not max or max <= 0 then
        return 1
    end
    return zo_clamp(cur / max, 0, 1)
end

-- === Hide the vanilla Health bar ===========================================
local function ApplyHide()
    if not Rule.active then
        return
    end

    local ctrl = _G["ZO_PlayerAttributeHealth"]
    if ctrl and ctrl.SetHidden then
        ctrl:SetHidden(true)
    end

    local fb = _G["ZO_PlayerAttributeHealthFrame"]
    if fb and fb.SetHidden then
        fb:SetHidden(true)
    end

    local bar = _G["ZO_PlayerAttributeHealthStatusBar"]
    if bar and bar.SetAlpha then
        bar:SetAlpha(0)
    end
end

local function RemoveHide()
    local ctrl = _G["ZO_PlayerAttributeHealth"]
    if ctrl and ctrl.SetHidden then
        ctrl:SetHidden(false)
    end

    local fb = _G["ZO_PlayerAttributeHealthFrame"]
    if fb and fb.SetHidden then
        fb:SetHidden(false)
    end

    local bar = _G["ZO_PlayerAttributeHealthStatusBar"]
    if bar and bar.SetAlpha then
        bar:SetAlpha(1)
    end
end

-- === Fullscreen overlay ====================================================
local overlayTLW -- top-level window (container)
local darkMask -- solid black mask (backdrop)
local darkVignette -- black vignette texture (subtle shape)
local pulseVignette -- red vignette pulse
local pulseTimeline -- animation timeline

local function EnsureOverlay()
    if overlayTLW then
        return
    end

    local wm = WINDOW_MANAGER
    overlayTLW = wm:CreateTopLevelWindow("HARDCORE_HealthVisionOverlay")
    -- CRITICAL: anchor to GuiRoot or the TLW is 0x0 and invisible
    overlayTLW:SetAnchorFill(GuiRoot)
    overlayTLW:SetDrawTier(DT_HIGH)
    overlayTLW:SetDrawLayer(DL_OVERLAY)
    overlayTLW:SetDrawLevel(9999)
    overlayTLW:SetClampedToScreen(true)
    overlayTLW:SetHidden(true)
    overlayTLW:SetMouseEnabled(false)

    -- Solid black mask that actually darkens the entire screen
    darkMask = wm:CreateControl(nil, overlayTLW, CT_BACKDROP)
    darkMask:SetAnchorFill()
    darkMask:SetAlpha(0) -- driven by health
    darkMask:SetCenterColor(0, 0, 0, 1)
    darkMask:SetEdgeColor(0, 0, 0, 0)
    darkMask:SetEdgeTexture(nil, 1, 1, 0, 0)

    -- Soft black vignette to make edges feel heavier (purely cosmetic)
    darkVignette = wm:CreateControl(nil, overlayTLW, CT_TEXTURE)
    darkVignette:SetAnchorFill()
    darkVignette:SetTexture("/esoui/art/miscellaneous/centerscreen_announceEdge.dds")
    darkVignette:SetTextureCoords(0, 1, 0, 1)
    darkVignette:SetAlpha(0) -- follows darkMask alpha so it scales together
    darkVignette:SetBlendMode(TEX_BLEND_COLOR_ALPHA)

    -- Low-HP red pulse layer
    pulseVignette = wm:CreateControl(nil, overlayTLW, CT_TEXTURE)
    pulseVignette:SetAnchorFill()
    pulseVignette:SetTexture("/esoui/art/miscellaneous/centerscreen_announceEdge.dds")
    pulseVignette:SetColor(1, 0, 0, 1)
    pulseVignette:SetAlpha(0)
    pulseVignette:SetBlendMode(TEX_BLEND_COLOR_ALPHA)

    -- Pulse animation: alpha in-out forever while below threshold
    pulseTimeline = ANIMATION_MANAGER:CreateTimeline()
    local aIn = pulseTimeline:InsertAnimation(ANIMATION_ALPHA, pulseVignette, 0)
    aIn:SetAlphaValues(PULSE_MIN_ALPHA, PULSE_MAX_ALPHA)
    aIn:SetDuration(PULSE_PERIOD_MS / 2)

    local aOut = pulseTimeline:InsertAnimation(ANIMATION_ALPHA, pulseVignette, PULSE_PERIOD_MS / 2)
    aOut:SetAlphaValues(PULSE_MAX_ALPHA, PULSE_MIN_ALPHA)
    aOut:SetDuration(PULSE_PERIOD_MS / 2)
    pulseTimeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
end

local function SetOverlayHidden(hidden)
    if overlayTLW then
        overlayTLW:SetHidden(hidden)
    end
end

local function ApplyOverlayAlpha(alpha)
    -- Drive both dark layers with the same alpha for a stronger feel
    if darkMask then
        darkMask:SetAlpha(alpha)
    end
    if darkVignette then
        darkVignette:SetAlpha(alpha * 0.9)
    end -- a touch softer than base
end

local function UpdateOverlayFromHealth()
    if not Rule.active then
        return
    end
    EnsureOverlay()

    local hp = GetPlayerHealthPercent()
    local missing = 1 - hp
    local curve = math.pow(missing, CURVE_STRENGTH)
    local alpha = zo_clamp(curve * MAX_DARKEN_ALPHA, 0, MAX_DARKEN_ALPHA)

    ApplyOverlayAlpha(alpha)

    -- Low HP pulse gating
    if hp <= LOW_HP_THRESHOLD then
        if pulseTimeline and not pulseTimeline:IsPlaying() then
            pulseVignette:SetAlpha(PULSE_MIN_ALPHA)
            pulseTimeline:PlayFromStart()
        end
    else
        if pulseTimeline and pulseTimeline:IsPlaying() then
            pulseTimeline:Stop()
        end
        pulseVignette:SetAlpha(0)
    end
end

-- Only show the overlay on HUD scenes (not while in menus/maps)
local function HookScenes()
    local function SetupScene(sceneName)
        local scn = SCENE_MANAGER and SCENE_MANAGER:GetScene(sceneName)
        if not scn then
            return
        end
        scn:RegisterCallback("StateChange", function(_, newState)
            if not Rule.active then
                return
            end
            if newState == SCENE_SHOWING then
                SetOverlayHidden(false)
                zo_callLater(function()
                    ApplyHide()
                    UpdateOverlayFromHealth()
                end, 10)
            elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN then
                SetOverlayHidden(true)
            end
        end)
    end
    SetupScene("hud")
    SetupScene("hudui")
end

-- === Install / Events ======================================================
local function Install()
    if Rule._installed then
        return
    end

    EnsureOverlay()
    HookScenes()

    -- After login/zone load
    EVENT_MANAGER:RegisterForEvent(NS .. "_ACTIVATED", EVENT_PLAYER_ACTIVATED, function()
        if Rule.active then
            ApplyHide()
            UpdateOverlayFromHealth()
            local onHud = SCENE_MANAGER and (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui"))
            SetOverlayHidden(not onHud)
        end
    end)

    -- Interface tweaks can rebuild bars
    EVENT_MANAGER:RegisterForEvent(NS .. "_SETTING", EVENT_INTERFACE_SETTING_CHANGED, function()
        if Rule.active then
            zo_callLater(ApplyHide, 50)
        end
    end)

    -- Health changes: use provided values to avoid extra API calls
    EVENT_MANAGER:RegisterForEvent(NS .. "_POWER", EVENT_POWER_UPDATE,
        function(_, unitTag, powerIndex, powerType, powerValue, powerMax)
            if not Rule.active then
                return
            end
            if unitTag ~= "player" or powerType ~= POWERTYPE_HEALTH then
                return
            end
            EnsureOverlay()
            local hp = (powerMax and powerMax > 0) and zo_clamp(powerValue / powerMax, 0, 1) or 1
            local missing = 1 - hp
            local curve = math.pow(missing, CURVE_STRENGTH)
            local alpha = zo_clamp(curve * MAX_DARKEN_ALPHA, 0, MAX_DARKEN_ALPHA)
            ApplyOverlayAlpha(alpha)

            if hp <= LOW_HP_THRESHOLD then
                if pulseTimeline and not pulseTimeline:IsPlaying() then
                    pulseVignette:SetAlpha(PULSE_MIN_ALPHA)
                    pulseTimeline:PlayFromStart()
                end
            else
                if pulseTimeline and pulseTimeline:IsPlaying() then
                    pulseTimeline:Stop()
                end
                pulseVignette:SetAlpha(0)
            end
        end)

    -- Death / revive: keep overlay consistent
    EVENT_MANAGER:RegisterForEvent(NS .. "_DEATH", EVENT_UNIT_DEATH_STATE_CHANGED, function(_, unitTag, isDead)
        if not Rule.active or unitTag ~= "player" then
            return
        end
        if isDead then
            ApplyOverlayAlpha(MAX_DARKEN_ALPHA)
            if pulseTimeline and pulseTimeline:IsPlaying() then
                pulseTimeline:Stop()
            end
            pulseVignette:SetAlpha(0)
        else
            UpdateOverlayFromHealth()
        end
    end)

    -- Screen resize safety (rare, but helps on resolution changes)
    EVENT_MANAGER:RegisterForEvent(NS .. "_RESIZE", EVENT_SCREEN_RESIZED, function()
        if overlayTLW then
            overlayTLW:ClearAnchors();
            overlayTLW:SetAnchorFill(GuiRoot)
        end
    end)

    Rule._installed = true
end

-- === Rule lifecycle ========================================================
function Rule:OnEnable()
    self.active = true
    Install()
    ApplyHide()

    -- Make overlay visible on HUD (hidden elsewhere), and update immediately
    local onHud = SCENE_MANAGER and (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui"))
    SetOverlayHidden(not onHud)
    UpdateOverlayFromHealth()

    log("Player Health bar hidden. Vision overlay active and scales with missing health.")
end

function Rule:OnDisable()
    self.active = false

    if pulseTimeline and pulseTimeline:IsPlaying() then
        pulseTimeline:Stop()
    end
    if overlayTLW then
        overlayTLW:SetHidden(true)
    end

    RemoveHide()
    log("Player Health bar restored. Vision overlay disabled.")
end

-- === Registration (deferred-safe) =========================================
local function TryRegister()
    if HARDCORE and HARDCORE.RuleManager and HARDCORE.RuleManager.RegisterRule then
        HARDCORE.RuleManager:RegisterRule(Rule)
        EVENT_MANAGER:UnregisterForEvent(NS .. "_DEFER", EVENT_ADD_ON_LOADED)
    end
end

if HARDCORE and HARDCORE.RuleManager then
    TryRegister()
else
    EVENT_MANAGER:RegisterForEvent(NS .. "_DEFER", EVENT_ADD_ON_LOADED, TryRegister)
end
