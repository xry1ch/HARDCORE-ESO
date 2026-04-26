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
        local poiName, _, _, _, _, poiType = GetPOIInfo(zoneIndex, poiIndex)
        return poiName and poiName ~= "" and poiType == POI_TYPE_STANDARD and IsInJusticeEnabledZone() and not IsInAvAZone()
    end
    return false
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

local function Announce()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Skills can only be managed in a city/town!")
end

local function Install()
    if Rule._hooksInstalled then
        return
    end

    ZO_PreHook(SCENE_MANAGER, "Show", function(_, arg)
        if not Rule.active then
            return false
        end
        local sceneName = GetSceneName(arg)
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

HARDCORE.RuleManager:RegisterRule(Rule)
