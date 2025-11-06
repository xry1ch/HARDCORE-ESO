-- Rule_LimitedTP.lua
-- Blocks traveling to wayshrines from the map (recall). Only allow travel while using a wayshrine.
-- Implementation: PreHook FastTravelToNode and allow it ONLY if currently interacting with a wayshrine.

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

-- ===== Helpers =====
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

-- Are we currently interacting with a wayshrine?
-- ESO exposes GetInteractionType() which is INTERACTION_FAST_TRAVEL when at a shrine.
local function IsAtWayshrine()
    local itype = GetInteractionType()
    -- If you want to also allow keep transitus (Cyrodiil), add checks here for its interaction type.
    return itype == INTERACTION_FAST_TRAVEL
end

-- ===== Hooks =====
local function InstallHooks()
    if Rule._hooksInstalled then return end

    -- Block any attempt to FastTravelToNode unless we are at a wayshrine.
    ZO_PreHook("FastTravelToNode", function(nodeIndex)
        if not Rule.active then return false end
        if not IsAtWayshrine() then
            -- Not at a shrine → this is a recall or remote trigger; block it.
            AlertBlocked()
            return true -- swallow the call
        end
        -- At a shrine → allow.
        return false
    end)

    -- Optional: if the world map is opened without a wayshrine interaction,
    -- we can still let the user look around; the actual travel will be blocked by the hook above.
    -- Defensive UX: if somehow a confirm dialog appears (edge UIs), close it.
    local worldMapScene = SCENE_MANAGER and SCENE_MANAGER:GetScene("worldMap")
    if worldMapScene then
        worldMapScene:RegisterCallback("StateChange", function(_, newState)
            if Rule.active and newState == SCENE_SHOWING and not IsAtWayshrine() then
                -- No hard close; we just ensure any attempted travel is blocked.
                -- If you want to be stricter, uncomment to auto-close:
                -- SCENE_MANAGER:HideCurrentScene()
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

-- Deferred registration with the RuleManager (same pattern as other rules)
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
