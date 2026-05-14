local HARDCORE = HARDCORE

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

local function Announce()
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Skills can only be managed in a city/town!")
end

local function Install()
    if Rule._hooksInstalled then
        return
    end

    local scene = SCENE_MANAGER and SCENE_MANAGER:GetScene("skills")
    if scene then
        scene:RegisterCallback("StateChange", function(_, newState)
            if Rule.active and newState == SCENE_SHOWING and not IsPlayerInCity() then
                Announce()
                SCENE_MANAGER:HideCurrentScene()
            end
        end)
    end

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
