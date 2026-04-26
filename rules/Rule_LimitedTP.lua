local Rule = {
    id = "LimitedTP",
    title = "Wayshrine-to-wayshrine only",
    icon = "/esoui/art/poi/poi_wayshrine_complete.dds",
    defaultEnabled = true,
}

local NS = "HARDCORE_LimitedTP"
Rule.active = false
Rule._hooksInstalled = false
Rule._lastAlertMs = 0

local function ShouldThrottleAlert()
    local now = GetFrameTimeMilliseconds()
    if (now - Rule._lastAlertMs) > 1200 then
        Rule._lastAlertMs = now
        return false
    end
    return true
end

local function AlertBlocked()
    if ShouldThrottleAlert() then return end
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK,
        "HARDCORE: Fast travel is limited to wayshrine → wayshrine. Recall from map is disabled.")
end

local function IsAtWayshrine()
    local itype = GetInteractionType()
    return itype == INTERACTION_FAST_TRAVEL
end

local function InstallHooks()
    if Rule._hooksInstalled then return end

    ZO_PreHook("FastTravelToNode", function(nodeIndex)
        if not Rule.active then return false end
        if not IsAtWayshrine() then
            AlertBlocked()
            return true
        end
        return false
    end)

    local worldMapScene = SCENE_MANAGER and SCENE_MANAGER:GetScene("worldMap")
    if worldMapScene then
        worldMapScene:RegisterCallback("StateChange", function(_, newState)
            if Rule.active and newState == SCENE_SHOWING and not IsAtWayshrine() then
            end
        end)
    end

    Rule._hooksInstalled = true
end

function Rule:OnEnable()
    self.active = true
    InstallHooks()
end

function Rule:OnDisable()
    self.active = false
end

HARDCORE.RuleManager:RegisterRule(Rule)
