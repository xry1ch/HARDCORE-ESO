local HARDCORE = HARDCORE

local ID = "NoWayshrines"
local NS = "HARDCORE_NoWayshrines"

local ICON_NO_WAYSHRINES = "/esoui/art/poi/poi_wayshrine_complete.dds"

local Rule = {
    id = ID,
    title = "No Wayshrines: fast travel is forbidden",
    icon = ICON_NO_WAYSHRINES,
    defaultEnabled = false
}

Rule.active = false
Rule._hooksInstalled = false
Rule._lastAlertMs = 0

local function IsHardcoreActive()
    return HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive
end

function HARDCORE.IsNoWayshrinesFeatActive()
    return Rule.active and IsHardcoreActive()
end

local function AnnounceBlocked()
    local now = GetFrameTimeMilliseconds()
    if now - Rule._lastAlertMs > 1200 then
        Rule._lastAlertMs = now
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK,
            "HARDCORE: Wayshrine travel is forbidden.")
    end
end

local function ShouldBlockWayshrineTravel()
    return HARDCORE.IsNoWayshrinesFeatActive()
end

local function CloseFastTravelInteraction()
    EndInteraction(INTERACTION_FAST_TRAVEL)

    if ZO_Dialogs_ReleaseDialog then
        ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
        ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
        ZO_Dialogs_ReleaseDialog("TRAVEL_TO_HOUSE_CONFIRM")
    end

    if ZO_WorldMap_HideWorldMap and ZO_WorldMap_IsWorldMapShowing and ZO_WorldMap_IsWorldMapShowing() then
        ZO_WorldMap_HideWorldMap()
    end
end

local function BlockAndCloseFastTravel()
    CloseFastTravelInteraction()
    AnnounceBlocked()
end

local function OnFastTravelInteractionStarted()
    if ShouldBlockWayshrineTravel() then
        BlockAndCloseFastTravel()
        zo_callLater(CloseFastTravelInteraction, 0)
    end
end

local function InstallHooks()
    if Rule._hooksInstalled then
        return
    end

    ZO_PreHook("ZO_Dialogs_ShowPlatformDialog", function(dialogName)
        if ShouldBlockWayshrineTravel() and
            (dialogName == "FAST_TRAVEL_CONFIRM" or dialogName == "RECALL_CONFIRM" or dialogName == "TRAVEL_TO_HOUSE_CONFIRM") then
            BlockAndCloseFastTravel()
            return true
        end
    end)

    ZO_PreHook("FastTravelToNode", function()
        if ShouldBlockWayshrineTravel() then
            BlockAndCloseFastTravel()
            return true
        end
    end)

    Rule._hooksInstalled = true
end

local function RegisterEvents()
    EVENT_MANAGER:UnregisterForEvent(NS .. "_START", EVENT_START_FAST_TRAVEL_INTERACTION)
    EVENT_MANAGER:RegisterForEvent(NS .. "_START", EVENT_START_FAST_TRAVEL_INTERACTION, OnFastTravelInteractionStarted)
end

local function UnregisterEvents()
    EVENT_MANAGER:UnregisterForEvent(NS .. "_START", EVENT_START_FAST_TRAVEL_INTERACTION)
end

function Rule:OnEnable()
    self.active = true
    InstallHooks()
    RegisterEvents()
    if GetInteractionType() == INTERACTION_FAST_TRAVEL then
        BlockAndCloseFastTravel()
    end
end

function Rule:OnDisable()
    self.active = false
    UnregisterEvents()
end

HARDCORE.RuleManager:RegisterRule(Rule)
