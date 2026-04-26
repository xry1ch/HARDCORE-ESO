local HARDCORE = HARDCORE

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

    for _, name in ipairs({ "Left", "Center", "Right" }) do
        local child = frame:GetNamedChild(name)
        if child then child:SetHidden(hidden) end
    end
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
    local shouldHide = not BossBarActive()
    HideCompassFrame(shouldHide)
end

local function EnsureHook(self)
    if self._hooked or not COMPASS_FRAME or not COMPASS_FRAME.SetBossBarActive then return end
    self._origSetBossBarActive = COMPASS_FRAME.SetBossBarActive

    function COMPASS_FRAME:SetBossBarActive(active)
        if active then
            HideCompassFrame(false)
            if self.RefreshVisible then
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


function Rule:OnEnable()
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
    HideCompassFrame(false)

    RemoveHook(self)
    if self._playerActivatedCallback then
        EVENT_MANAGER:UnregisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED)
        self._playerActivatedCallback = nil
    end
end

HARDCORE.RuleManager:RegisterRule(Rule)

return Rule
