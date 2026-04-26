local HARDCORE = HARDCORE

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

local BLOCKED_SCENES = {
    ["champion"] = true,
    ["champion_perks"] = true,
    ["championperks"] = true,
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
    return string.find(sceneName, "champion", 1, true) ~= nil
end

local function GetSceneName(arg)
    if type(arg) == "string" then
        return arg
    end
    if type(arg) == "table" and arg.GetName then
        return arg:GetName()
    end
    return nil
end

local function InstallHooks()
    if Rule._hooksInstalled then return end

    ZO_PreHook(SCENE_MANAGER, "Show", function(_, arg)
        if not Rule.active then return false end
        local sceneName = GetSceneName(arg)
        if IsBlockedSceneName(sceneName) then
            Announce()
            return true
        end
        return false
    end)

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

    for name in pairs(BLOCKED_SCENES) do
        AttachCloseOnShow(name)
    end
    AttachCloseOnShow("champion")

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

function Rule:OnEnable()
    self.active = true
    InstallHooks()
end

function Rule:OnDisable()
    self.active = false
end

HARDCORE.RuleManager:RegisterRule(Rule)
