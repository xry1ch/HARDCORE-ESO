-- File: challenges/Challenge_Level40.lua
-- Challenge: Reach character level 40.
local CM = HARDCORE and HARDCORE.ChallengeManager

local Chal = {
    id = "ReachLevel40",
    title = "Reach Level 40",
    points = 200,
    icon = "/esoui/art/achievements/achievement_icon_category_character.dds",
    order = 3
}

function Chal:getProgress()
    local lvl = GetUnitLevel("player") or 1
    return math.min(lvl, 40), 40
end

local function check()
    if not CM then
        return
    end
    local cur = GetUnitLevel("player") or 1
    if cur >= 40 then
        CM:Complete(Chal.id)
    else
        CM:NotifyDirty()
    end
end

function Chal.onEnable(self)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_LVL", EVENT_LEVEL_UPDATE, function(_, unitTag)
        if unitTag == "player" then
            check()
        end
    end)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_ACT", EVENT_PLAYER_ACTIVATED, function()
        check()
    end)
    check()
end

function Chal.onDisable(self)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_LVL", EVENT_LEVEL_UPDATE)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_ACT", EVENT_PLAYER_ACTIVATED)
end

if CM and CM.Register then
    CM:Register(Chal)
end
