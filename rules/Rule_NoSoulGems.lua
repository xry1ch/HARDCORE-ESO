-- Rule_NoSoulGems.lua
-- Blocks recharging weapons with Soul Gems.
-- Uses lightweight ZO_PreHook function hooks; only blocks when rule is active.
local Rule = {
    id = "NoSoulGems",
    title = "No Soul Gems (no recharging)",
    icon = "/esoui/art/inventory/inventory_tabicon_soulgem_down.dds",
    defaultEnabled = true
}

local NS = "HARDCORE_NoSoulGems"
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
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Recharging with Soul Gems is disabled.")
end

-- === Hooks ===
local function InstallHooks()
    if Rule._hooksInstalled then
        return
    end

    -- Block the actual recharge call
    ZO_PreHook("ChargeItemWithSoulGem", function(itemBag, itemSlot, gemBag, gemSlot)
        if Rule.active then
            AlertBlocked()
            return true
        end
    end)

    -- Block initiating a soulgem from inventory
    if UseItem then
        ZO_PreHook("UseItem", function(bagId, slotIndex)
            if not Rule.active then
                return false
            end
            local itemType = GetItemType(bagId, slotIndex)
            if itemType == ITEMTYPE_SOUL_GEM then
                AlertBlocked()
                return true
            end
            return false
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
