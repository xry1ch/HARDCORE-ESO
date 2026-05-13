local HARDCORE = HARDCORE

local Rule = {
    id = "NoCompass",
    title = "No compass",
    icon = "/esoui/art/addons/gamepad/gp_mod_listing_category_mapandcompass.dds",
    defaultEnabled = true,
}

-- Internal state
Rule._playerActivatedCallback = nil

-- Helpers -------------------------------------------------------------

local function SetCompassHidden(hidden)
    if COMPASS_FRAME and COMPASS_FRAME.SetCompassHidden then
        COMPASS_FRAME:SetCompassHidden(hidden)
    end
end

function Rule:OnEnable()
    if not COMPASS_FRAME or not COMPASS_FRAME.SetCompassHidden then
        if not self._playerActivatedCallback then
            self._playerActivatedCallback = function()
                SetCompassHidden(true)
                EVENT_MANAGER:UnregisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED)
                self._playerActivatedCallback = nil
            end
            EVENT_MANAGER:RegisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED, self._playerActivatedCallback)
        end
        return
    end

    SetCompassHidden(true)
end

function Rule:OnDisable()
    SetCompassHidden(false)

    if self._playerActivatedCallback then
        EVENT_MANAGER:UnregisterForEvent("HARDCORE_NoCompass", EVENT_PLAYER_ACTIVATED)
        self._playerActivatedCallback = nil
    end
end

HARDCORE.RuleManager:RegisterRule(Rule)

return Rule
