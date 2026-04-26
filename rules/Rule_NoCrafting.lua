local Rule = {
    id = "NoCrafting",
    title = "No crafting stations (except Alchemy & Cooking)",
    icon = "/esoui/art/inventory/inventory_craft_tabicon_active.dds",
    defaultEnabled = true
}

local NS = "HARDCORE_NoCrafting"
Rule.active = false
Rule._hooksInstalled = false

local CRAFTING_SCENES = {
    smithing = true,
    enchanting = true,
    retrait = true,
    universalDeconstruction = true
}

local function Announce()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Only Alchemy and Cooking are allowed.")
end

local function CleanExit()
    zo_callLater(function()
        if IsInteracting and IsInteracting() and EndInteraction then
            EndInteraction(INTERACTION_CRAFT)
        end
        if SCENE_MANAGER then
            SCENE_MANAGER:ShowBaseScene()
        end
    end, 60)
end

local function InstallHooks()
    if Rule._hooksInstalled then
        return
    end

    ZO_PreHook(SCENE_MANAGER, "Show", function(_, arg)
        if not Rule.active then
            return false
        end
        local sceneName
        if type(arg) == "string" then
            sceneName = arg
        elseif type(arg) == "table" and arg.GetName then
            sceneName = arg:GetName()
        end
        if sceneName and CRAFTING_SCENES[sceneName] then
            Announce()
            CleanExit()
            return true
        end
    end)

    for name in pairs(CRAFTING_SCENES) do
        local scene = SCENE_MANAGER:GetScene(name)
        if scene then
            scene:RegisterCallback("StateChange", function(_, newState)
                if Rule.active and newState == SCENE_SHOWING then
                    Announce()
                    SCENE_MANAGER:HideCurrentScene()
                    CleanExit()
                end
            end)
        end
    end

    EVENT_MANAGER:RegisterForEvent(NS .. "_INTERACT", EVENT_CRAFTING_STATION_INTERACT, function(_, craftSkill)
        if not Rule.active then
            return
        end
        if craftSkill ~= CRAFTING_TYPE_ALCHEMY and craftSkill ~= CRAFTING_TYPE_PROVISIONING then
            Announce()
            CleanExit()
        end
    end)

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
