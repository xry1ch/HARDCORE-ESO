local Rule = {
    id = "NoBank",
    title = "No banks / guild stores",
    icon = "/esoui/art/vendor/vendor_tabicon_repair_down.dds",
    defaultEnabled = true
}

local NS = "HARDCORE_NoBank"
Rule.active = false
Rule._hooksInstalled = false

local function Announce(what)
    local msg = string.format("HARDCORE: %s is disabled.", what or "Banking / Guild Store")
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, msg)
end

local function HideIf(name)
    local current = SCENE_MANAGER:GetCurrentScene()
    if current and current.GetName and current:GetName() == name then
        SCENE_MANAGER:HideCurrentScene()
    end
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
        if not sceneName then
            return false
        end

        if sceneName == "bank" then
            Announce("Bank")
            return true
        elseif sceneName == "guildBank" then
            Announce("Guild Bank")
            return true
        elseif sceneName == "tradinghouse" then
            Announce("Guild Store")
            return true
        end
        return false
    end)

    local names = {"bank", "guildBank", "tradinghouse"}
    for _, sceneName in ipairs(names) do
        local scene = SCENE_MANAGER:GetScene(sceneName)
        if scene then
            scene:RegisterCallback("StateChange", function(_, newState)
                if Rule.active and newState == SCENE_SHOWING then
                    Announce(sceneName == "tradinghouse" and "Guild Store" or
                             (sceneName == "guildBank" and "Guild Bank" or "Bank"))
                    SCENE_MANAGER:HideCurrentScene()
                end
            end)
        end
    end

    EVENT_MANAGER:RegisterForEvent(NS .. "_BANK", EVENT_OPEN_BANK, function()
        if Rule.active then
            Announce("Bank")
            if EndInteraction then
                EndInteraction(INTERACTION_BANK)
            end
            HideIf("bank")
        end
    end)

    EVENT_MANAGER:RegisterForEvent(NS .. "_GBANK", EVENT_OPEN_GUILD_BANK, function()
        if Rule.active then
            Announce("Guild Bank")
            if EndInteraction then
                EndInteraction(INTERACTION_GUILDBANK)
            end
            HideIf("guildBank")
        end
    end)

    EVENT_MANAGER:RegisterForEvent(NS .. "_TH", EVENT_OPEN_TRADING_HOUSE, function()
        if Rule.active then
            Announce("Guild Store")
            if EndInteraction then
                EndInteraction(INTERACTION_TRADINGHOUSE)
            end
            HideIf("tradinghouse")
        end
    end)

    EVENT_MANAGER:RegisterForEvent(NS .. "_CHATTER", EVENT_CHATTER_BEGIN, function()
        if Rule.active and EndInteraction then
            EndInteraction(INTERACTION_BANK)
            EndInteraction(INTERACTION_GUILDBANK)
            EndInteraction(INTERACTION_TRADINGHOUSE)
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
