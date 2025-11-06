-- Rule_NoRepair.lua
-- Blocks repairs from vendors and repair kits.
-- Uses lightweight ZO_PreHook Function hooks; only blocks when rule is active.
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

-- === Helpers ===
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

-- (ESO API functions we intercept)
-- RepairAll()                            -> vendor “Repair All”
-- RepairItem(bagId, slotIndex)           -> vendor single-item repair
-- RepairItemWithRepairKit(itemBag, itemSlot, kitBag, kitSlot) -> kit repair
-- UseItem(bagId, slotIndex)              -> starting a repair kit from inventory (filter)
-- See: ESO_API.txt entries for RepairAll/RepairItem/RepairItemWithRepairKit. :contentReference[oaicite:0]{index=0}

local function InstallHooks()
    if Rule._hooksInstalled then
        return
    end

    -- Block vendor "Repair All"
    ZO_PreHook("RepairAll", function()
        if Rule.active then
            AlertBlocked()
            return true -- swallow call
        end
    end)

    -- Block vendor single-item repair
    ZO_PreHook("RepairItem", function(bagId, slotIndex)
        if Rule.active then
            AlertBlocked()
            return true
        end
    end)

    -- Block repair kit consumption (final call)
    ZO_PreHook("RepairItemWithRepairKit", function(itemBag, itemSlot, kitBag, kitSlot)
        if Rule.active then
            AlertBlocked()
            return true
        end
    end)

    -- Block initiating repair kits from inventory (stops the repair cursor from starting)
    if UseItem then
        ZO_PreHook("UseItem", function(bagId, slotIndex)
            if not Rule.active then
                return false
            end
            local itemType = GetItemType(bagId, slotIndex)
            -- ITEMTYPE_REPAIR_KIT covers normal kits; Crown repair kits are also ITEMTYPE_REPAIR_KIT.
            if itemType == ITEMTYPE_REPAIR_KIT then
                AlertBlocked()
                return true
            end
            return false
        end)
    end

    -- Defensive: close/deny the Repair scene if somehow opened
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

-- Deferred registration with the RuleManager
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
