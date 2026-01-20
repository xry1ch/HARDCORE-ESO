-- Rule_NoCP.lua
-- Blocks access to the Champion Points UI (keyboard & gamepad).

local Rule = {
    id = "NoCP",
    title = "No Champion Points UI",
    icon = "/esoui/art/armory/buildicons/buildicon_5.dds",
    defaultEnabled = true,
}

local NS = "HARDCORE_NoCP"
Rule.active = false
Rule._hooksInstalled = false
Rule._lastAlertMs = 0

-- Helpers
local BLOCKED_SCENES = {
    ["champion"] = true,                 -- main CP scene (keyboard)
    ["champion_perks"] = true,           -- fallback name
    ["championperks"] = true,            -- defensive variants
    ["championperkskeyboard"] = true,
    ["championperksgamepad"] = true,
    ["gamepad_champion_perks_root"] = true
}

local function ShouldThrottle()
    local now = GetFrameTimeMilliseconds()
    if (now - Rule._lastAlertMs) > 1200 then
        Rule._lastAlertMs = now
        return false
    end
    return true
end

local function Announce()
    if ShouldThrottle() then return end
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Champion Points are disabled.")
end

local function IsBlockedSceneName(sceneName)
    if not sceneName then return false end
    sceneName = string.lower(tostring(sceneName))
    if BLOCKED_SCENES[sceneName] then
        return true
    end
    -- Defensive: any scene name containing "champion"
    return string.find(sceneName, "champion", 1, true) ~= nil
end

-- Install hooks
local function InstallHooks()
    if Rule._hooksInstalled then return end

    -- Intercept attempts to show the CP scene from anywhere (menus, keybind, API).
    ZO_PreHook(SCENE_MANAGER, "Show", function(_, sceneName)
        if not Rule.active then return false end
        if IsBlockedSceneName(sceneName) then
            Announce()
            return true -- block
        end
        return false
    end)

    -- If some other addon/flow forces the scene open, slam it shut.
    local function AttachCloseOnShow(sceneName)
        local scene = SCENE_MANAGER and SCENE_MANAGER:GetScene(sceneName)
        if not scene then return end
        scene:RegisterCallback("StateChange", function(_, newState)
            if Rule.active and newState == SCENE_SHOWING then
                Announce()
                SCENE_MANAGER:HideCurrentScene()
            end
        end)
    end

    -- Attach to known scene names (if they exist in this client)
    for name in pairs(BLOCKED_SCENES) do
        AttachCloseOnShow(name)
    end
    -- Also attach to the canonical "champion" scene if present
    AttachCloseOnShow("champion")

    -- Defensive: block a few global togglers if present
    if ToggleChampionPerksScene then
        ZO_PreHook("ToggleChampionPerksScene", function()
            if Rule.active then Announce() return true end
        end)
    end
    if ZO_ChampionPerks_ToggleChampionWindow then
        ZO_PreHook("ZO_ChampionPerks_ToggleChampionWindow", function()
            if Rule.active then Announce() return true end
        end)
    end

    Rule._hooksInstalled = true
end

-- Rule interface
function Rule:OnEnable()
    self.active = true
    InstallHooks()
end

function Rule:OnDisable()
    self.active = false
end

-- Register with RuleManager (deferred for load order)
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
