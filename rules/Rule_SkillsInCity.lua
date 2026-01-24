local Rule = {
    id = "EquipmentCitySkills",
    title = "Skills only in city/town",
    icon = "/esoui/art/icons/ability_uprising.dds",
    defaultEnabled = true
}

local NS = "HARDCORE_EquipmentCitySkills"
Rule.active = false
Rule._hooksInstalled = false

local function IsPlayerInCity()
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    if zoneIndex and poiIndex then
        local _, _, _, _, _, poiType = GetPOIInfo(zoneIndex, poiIndex)
        return poiType == POI_TYPE_CITY or poiType == POI_TYPE_TOWN
    end
    return false
end

local function Announce()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Skills can only be managed in a city/town!")
end

local function Install()
    if Rule._hooksInstalled then
        return
    end

    ZO_PreHook(SCENE_MANAGER, "Show", function(_, sceneName)
        if not Rule.active then
            return false
        end
        if sceneName == "skills" and not IsPlayerInCity() then
            Announce()
            return true
        end
    end)

    Rule._hooksInstalled = true
end

function Rule:OnEnable()
    self.active = true
    Install()
end

function Rule:OnDisable()
    self.active = false
end

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
