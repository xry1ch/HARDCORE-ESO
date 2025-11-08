-- Challenge: Kill Any Enemy (robust)
-- Completes once when YOU kill any non-player enemy.
local CM = HARDCORE and HARDCORE.ChallengeManager
if not CM then return end

local Chal = {
    id     = "KillAnyEnemy",
    title  = "Kill Any Enemy",
    points = 20,
    icon   = "/esoui/art/icons/poi/poi_groupboss_complete.dds",
    order  = 99
}

function Chal.getProgress(self)
    return (CM:GetStatus(self.id) == "COMPLETED") and 1 or 0, 1
end

-- ACTION_RESULTs that represent a kill (depends on what ESO fires in your locale/zone).
local KILL_RESULTS = {
    [ACTION_RESULT_DIED] = true,
    [ACTION_RESULT_DIED_XP] = true,
}

local function onCombatEvent(_, result, isError, abilityName, _, _, sourceName, sourceType,
                             targetName, targetType, _, _, _, _, _, _, _)
    if CM:GetStatus(Chal.id) == "COMPLETED" then return end
    if isError then return end
    if not KILL_RESULTS[result] then return end
    -- we only care about kills where the SOURCE is the player (or player pet if you prefer)
    if sourceType ~= COMBAT_UNIT_TYPE_PLAYER then return end
    -- ignore player/companion targets
    if targetType == COMBAT_UNIT_TYPE_PLAYER or targetType == COMBAT_UNIT_TYPE_COMPANION then return end

    -- Extra safety: don't count self-kills or nil names
    if not targetName or targetName == "" or targetName == GetUnitName("player") then return end

    -- Boom. Completed.
    CM:Complete(Chal.id)
    PlaySound(SOUNDS.ACHIEVEMENT_AWARDED)
    d("[HARDCORE] KillAnyEnemy: completed on target '" .. zo_strformat("<<1>>", targetName) .. "'.")
end

function Chal.onEnable(self)
    -- Show in chat that the challenge came alive
    d("[HARDCORE] KillAnyEnemy: listening for kills…")
    EVENT_MANAGER:RegisterForEvent(self.id .. "_COMBAT", EVENT_COMBAT_EVENT, onCombatEvent)
    -- Filters: only results we care about + only events originating from the player
    EVENT_MANAGER:AddFilterForEvent(self.id .. "_COMBAT", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED)
    EVENT_MANAGER:AddFilterForEvent(self.id .. "_COMBAT", EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    -- ACTION_RESULT_DIED_XP isn’t always covered by the single filter above; register a second filter for it:
    EVENT_MANAGER:RegisterForEvent(self.id .. "_COMBAT_XP", EVENT_COMBAT_EVENT, onCombatEvent)
    EVENT_MANAGER:AddFilterForEvent(self.id .. "_COMBAT_XP", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED_XP)
    EVENT_MANAGER:AddFilterForEvent(self.id .. "_COMBAT_XP", EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)

    CM:NotifyDirty()
end

function Chal.onDisable(self)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_COMBAT", EVENT_COMBAT_EVENT)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_COMBAT_XP", EVENT_COMBAT_EVENT)
end

CM:Register(Chal)
