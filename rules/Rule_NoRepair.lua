local Rule = {
    id = "NoRepair",
    title = "No repairs (kits & vendors)",
    icon = "/esoui/art/vendor/vendor_tabicon_repair_down.dds",
    defaultEnabled = true
}

local NS = "HARDCORE_NoRepair"
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
    if ShouldThrottleAlert() then
        return
    end
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Repairing gear is disabled.")
end

local function InstallHooks()
    if Rule._hooksInstalled then
        return
    end

    ZO_PreHook("RepairAll", function()
        if Rule.active then
            AlertBlocked()
            return true
        end
    end)

    ZO_PreHook("RepairItem", function(bagId, slotIndex)
        if Rule.active then
            AlertBlocked()
            return true
        end
    end)

    ZO_PreHook("RepairItemWithRepairKit", function(itemBag, itemSlot, kitBag, kitSlot)
        if Rule.active then
            AlertBlocked()
            return true
        end
    end)

    if UseItem then
        ZO_PreHook("UseItem", function(bagId, slotIndex)
            if not Rule.active then
                return false
            end
            local itemType = GetItemType(bagId, slotIndex)
            if itemType == ITEMTYPE_REPAIR_KIT then
                AlertBlocked()
                return true
            end
            return false
        end)
    end

    local repairScene = SCENE_MANAGER and SCENE_MANAGER:GetScene("repair")
    if repairScene then
        repairScene:RegisterCallback("StateChange", function(_, newState)
            if Rule.active and newState == SCENE_SHOWING then
                AlertBlocked()
                SCENE_MANAGER:HideCurrentScene()
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
