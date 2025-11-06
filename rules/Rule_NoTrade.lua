local Rule = {
    id = "NoTrade",
    title = "No trading (players)",
    icon = "/esoui/art/icons/emotes/emotecategoryicon_social.dds",
    defaultEnabled = true,
}

local NS = "HARDCORE_NoTrade"
Rule.active = false
Rule._hooksInstalled = false
Rule._lastAlertMs = 0

local function Throttle()
    local now = GetFrameTimeMilliseconds()
    if (now - Rule._lastAlertMs) > 1200 then
        Rule._lastAlertMs = now
        return false
    end
    return true
end

local function Announce()
    if Throttle() then return end
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Trading with other players is disabled.")
end

local function SafeHideTrade()
    zo_callLater(function()
        if TradeCancel then pcall(TradeCancel) end -- cancels any active trade. :contentReference[oaicite:0]{index=0}
        if SCENE_MANAGER and SCENE_MANAGER:GetCurrentScene() and SCENE_MANAGER:GetCurrentScene():GetName() == "trade" then
            SCENE_MANAGER:ShowBaseScene()
        end
    end, 50)
end

local function InstallHooks()
    if Rule._hooksInstalled then return end

    -- 1) Block initiating trades
    if TradeInvite then
        ZO_PreHook("TradeInvite", function(target)
            if Rule.active then
                Announce()
                return true
            end
        end)
    end
    if TradeInviteByName then
        ZO_PreHook("TradeInviteByName", function(playerName)
            if Rule.active then
                Announce()
                return true
            end
        end)
    end

    -- 2) Auto-decline incoming invites (handle both the invite and the accept)
    -- If any code tries to accept, block it.
    if TradeInviteAccept then
        ZO_PreHook("TradeInviteAccept", function()
            if Rule.active then
                Announce()
                -- proactively decline to be sure
                if TradeInviteDecline then TradeInviteDecline() end -- explicit decline. :contentReference[oaicite:1]{index=1}
                return true
            end
        end)
    end

    -- Try to auto-decline as soon as an invite arrives. If the invite event name ever changes,
    -- the defensive scene/accept hooks still keep the rule effective.
    if EVENT_TRADE_INVITE_CONSIDER then
        EVENT_MANAGER:RegisterForEvent(NS .. "_INVITE", EVENT_TRADE_INVITE_CONSIDER, function(_, inviterDisplayName)
            if Rule.active and TradeInviteDecline then
                TradeInviteDecline() -- decline incoming invite as it comes in. :contentReference[oaicite:2]{index=2}
                Announce()
            end
        end)
    end

    -- 3) Block placing items / editing the trade
    -- PlaceInTradeWindow is protected; we can still prehook to swallow the call before it fires.
    -- (ESO API lists PlaceInTradeWindow and trade edit functions.) 
    if PlaceInTradeWindow then
        ZO_PreHook("PlaceInTradeWindow", function(tradeIndex)
            if Rule.active then
                Announce()
                return true
            end
        end)
    end
    if TradeSetMoney then
        ZO_PreHook("TradeSetMoney", function(amount)
            if Rule.active then
                Announce()
                return true
            end
        end)
    end
    if TradeEdit then
        ZO_PreHook("TradeEdit", function()
            if Rule.active then
                Announce()
                return true
            end
        end)
    end
    if TradeRemoveItem then
        ZO_PreHook("TradeRemoveItem", function(idx)
            if Rule.active then
                Announce()
                return true
            end
        end)
    end

    -- 4) Defensive: if the Trade scene tries to show, cancel & hide it.
    local tradeScene = SCENE_MANAGER and SCENE_MANAGER:GetScene("trade")
    if tradeScene then
        tradeScene:RegisterCallback("StateChange", function(_, newState)
            if Rule.active and newState == SCENE_SHOWING then
                Announce()
                SafeHideTrade()
            end
        end)
    end

    -- Extra defensive hook on SCENE_MANAGER:Show in case something forces it
    ZO_PreHook(SCENE_MANAGER, "Show", function(_, arg)
        if not Rule.active then return false end
        local sceneName
        if type(arg) == "string" then
            sceneName = arg
        elseif type(arg) == "table" and arg.GetName then
            sceneName = arg:GetName()
        end
        if sceneName == "trade" then
            Announce()
            SafeHideTrade()
            return true
        end
    end)

    Rule._hooksInstalled = true
end

function Rule:OnEnable()
    self.active = true
    InstallHooks()
    -- In case a trade was already up when enabling the rule:
    SafeHideTrade()
end

function Rule:OnDisable()
    self.active = false
end

-- Register with RuleManager
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
