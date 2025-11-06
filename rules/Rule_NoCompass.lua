--[[  HARDCORE - Rule: No Compass
     Hides the compass while Hardcore is active. Auto-shows during boss bars.
     Depends on the global COMPASS_FRAME/ZO_Compass controls provided by ESO UI.
]]

local Rule = {
    id = "NoCompass",
    title = "No compass",
    icon = "/esoui/art/addons/gamepad/gp_mod_listing_category_mapandcompass.dds",
    defaultEnabled = true,
}

-- Internal state
Rule._hooked = false
Rule._origSetBossBarActive = nil
Rule._playerActivatedCallback = nil

-- Helpers -------------------------------------------------------------

local function HideCompassFrame(hidden)
    local frame = (COMPASS_FRAME and COMPASS_FRAME.control) or nil
    if not frame then return end

    -- Hide the three child buckets (Left/Center/Right)
    for _, name in ipairs({ "Left", "Center", "Right" }) do
        local child = frame:GetNamedChild(name)
        if child then child:SetHidden(hidden) end
    end

    -- Do not hide pins (other addons rely on them). Instead offset them off-screen.
    local offset = hidden and 16384 or 0
    if ZO_Compass then
        ZO_Compass:ClearAnchors()
        ZO_Compass:SetAnchor(TOPLEFT, frame, TOPLEFT, offset, offset)
    end
end

local function BossBarActive()
    if not COMPASS_FRAME or not COMPASS_FRAME.GetBossBarActive then return false end
    return COMPASS_FRAME:GetBossBarActive()
end

local function ApplyDesiredState()
    -- While the rule is enabled we want the compass hidden, except during boss bars.
    local shouldHide = not BossBarActive()
    HideCompassFrame(shouldHide)
end

local function EnsureHook(self)
    if self._hooked or not COMPASS_FRAME or not COMPASS_FRAME.SetBossBarActive then return end
    self._origSetBossBarActive = COMPASS_FRAME.SetBossBarActive

    -- Hook to force-show during boss encounters, then restore our hidden state.
    function COMPASS_FRAME:SetBossBarActive(active)
        if active then
            HideCompassFrame(false)
            if self.RefreshVisible then
                -- keep parity with the original code path
                self:RefreshVisible(self)
            end
            Rule._origSetBossBarActive(self, true)
        else
            Rule._origSetBossBarActive(self, false)
            ApplyDesiredState()
        end
    end

    self._hooked = true
end

local function RemoveHook(self)
    if self._hooked and self._origSetBossBarActive and COMPASS_FRAME then
        COMPASS_FRAME.SetBossBarActive = self._origSetBossBarActive
    end
    self._hooked = false
    self._origSetBossBarActive = nil
end

-- Lifecycle -----------------------------------------------------------

function Rule:OnEnable()
    -- If UI not ready yet (very early login), defer once to PLAYER_ACTIVATED.
    if not COMPASS_FRAME or not ZO_Compass then
        if not self._playerActivatedCallback then
            self._playerActivatedCallback = function()
                EnsureHook(self)
                ApplyDesiredState()
                EVENT_MANAGER:UnregisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED)
                self._playerActivatedCallback = nil
            end
            EVENT_MANAGER:RegisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED, self._playerActivatedCallback)
        end
        return
    end

    EnsureHook(self)
    ApplyDesiredState()
end

function Rule:OnDisable()
    -- Always show the compass when the rule is disabled.
    HideCompassFrame(false)

    -- Remove boss-bar hook and any deferred callback.
    RemoveHook(self)
    if self._playerActivatedCallback then
        EVENT_MANAGER:UnregisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED)
        self._playerActivatedCallback = nil
    end
end

-- Register with RuleManager
HARDCORE = HARDCORE or {}
if HARDCORE.RuleManager and HARDCORE.RuleManager.RegisterRule then
    HARDCORE.RuleManager:RegisterRule(Rule)
end

return Rule
