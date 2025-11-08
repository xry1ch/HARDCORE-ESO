-- File: challenges/Challenge_KillWorldBoss_Under30.lua
-- Challenge: Defeat a World Boss before Level 30
-- Mirrors the normal World Boss challenge, but adds a level restriction and auto-fail on reaching 30.

local CM = HARDCORE and HARDCORE.ChallengeManager
if not CM then return end

local Chal = {
    id = "KillWorldBoss_Under30",
    title = "Defeat a World Boss before Level 30",
    points = 180,                      -- a bit higher than the base one since it's gated
    icon = "/esoui/art/icons/poi/poi_groupboss_complete.dds",
    order = 7,                         -- place after the base challenge
}

-- ---------- Optional LibGPS ----------
local GPS = LibGPS3 or (LibGPS and LibGPS)
local function HasGPS() return GPS and GPS.MapToGlobal and GPS.GlobalToWorld end

-- ---------- Tunables ----------
local RECENT_BOSS_TOUCH_MS = 20 * 1000
local NEAR_POI_NORM = 0.08
local NEAR_POI_WORLD_M = 180

-- ---------- State ----------
local lastBossTouchedMs = 0
local function nowMs() return GetFrameTimeMilliseconds() end

-- ---------- Helpers ----------
local function inOverland()
    return not IsUnitInDungeon("player") and not IsPlayerInAvAWorld()
end

local function playerBelow30()
    -- If a character is CP-based, GetUnitLevel("player") returns 50.
    -- We still only want <30. Anyone >=30 (or 50) should be blocked/fail.
    local lvl = GetUnitLevel("player") or 1
    return lvl < 30
end

local function currentPOIIsGroupBoss()
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    if not (zoneIndex and poiIndex) then return false end
    local _, _, _, _, _, poiType = GetPOIInfo(zoneIndex, poiIndex)
    return poiType == POI_TYPE_GROUP_BOSS
end

local function nearestGroupBossPOI()
    local zoneIndex = GetCurrentMapZoneIndex()
    if not zoneIndex then return nil end
    local px, py = GetMapPlayerPosition("player")
    if not (px and py and px > 0 and py > 0) then return nil end

    local best
    for poiIndex = 1, GetNumPOIs(zoneIndex) do
        local _, _, _, x, y, poiType = GetPOIInfo(zoneIndex, poiIndex)
        if poiType == POI_TYPE_GROUP_BOSS and x and y and x > 0 and y > 0 then
            local dx, dy = (px - x), (py - y)
            local d2 = dx * dx + dy * dy
            if not best or d2 < best.d2 then
                best = { zoneIndex = zoneIndex, poiIndex = poiIndex, x = x, y = y, d2 = d2 }
            end
        end
    end
    return best
end

local function isNearGroupBossPOI()
    local n = nearestGroupBossPOI()
    if not n then return false end

    if HasGPS() then
        local mapId = GetCurrentMapId()
        local px, py = GetMapPlayerPosition("player")
        local gx_p, gy_p = GPS:MapToGlobal(mapId, px, py)
        local gx_b, gy_b = GPS:MapToGlobal(mapId, n.x, n.y)
        if gx_p and gy_p and gx_b and gy_b then
            local wx_p, wy_p = GPS:GlobalToWorld(gx_p, gy_p)
            local wx_b, wy_b = GPS:GlobalToWorld(gx_b, gy_b)
            if wx_p and wy_p and wx_b and wy_b then
                local dx, dy = wx_p - wx_b, wy_p - wy_b
                local dist = math.sqrt(dx * dx + dy * dy)
                return dist <= NEAR_POI_WORLD_M
            end
        end
    end

    return (n.d2 or 1) <= (NEAR_POI_NORM * NEAR_POI_NORM)
end

local function recentlySawBoss()
    return (nowMs() - lastBossTouchedMs) <= RECENT_BOSS_TOUCH_MS
end

local function tryCountKill(source)
    if CM:GetStatus(Chal.id) == "COMPLETED" then return end
    if not inOverland() then return end
    if not recentlySawBoss() then return end
    if not (isNearGroupBossPOI() or currentPOIIsGroupBoss()) then return end

    -- Level gate
    if not playerBelow30() then
        -- If you want it to *fail* immediately when trying at >=30, uncomment:
        -- CM:Fail(Chal.id)
        return
    end

    CM:Complete(Chal.id)
end

-- ---------- Event Handlers ----------
local function onBossesChanged()
    for i = 1, 6 do
        local tag = "boss" .. i
        if DoesUnitExist(tag) then
            lastBossTouchedMs = nowMs()
            break
        end
    end
end

local function onUnitDeathStateChanged(_, unitTag, isDead)
    if not isDead then return end
    if not unitTag or type(unitTag) ~= "string" then return end
    if not unitTag:find("^boss%d") then return end
    tryCountKill("boss dead")
end

local function onPOIStateChanged(_, _, _, newState)
    if newState ~= POI_STATE_COMPLETE then return end
    tryCountKill("poi complete")
end

local function onPlayerCombatState(_, inCombat)
    if inCombat == false then
        tryCountKill("combat ended")
    end
end

-- Auto-fail guard: if you’re already (or become) >=30, mark FAILED.
local function evaluateLevelAutoFail()
    if not playerBelow30() and CM:GetStatus(Chal.id) ~= "COMPLETED" then
        CM:Fail(Chal.id)
    end
end

local function onLevelUpdate(_, unitTag, level)
    if unitTag == "player" then
        if level and level >= 30 then
            evaluateLevelAutoFail()
        end
    end
end

-- ---------- Challenge API ----------
function Chal.getProgress()
    return CM:GetStatus(Chal.id) == "COMPLETED" and 1 or 0, 1
end

function Chal.onEnable(self)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_BOSSSET", EVENT_BOSSES_CHANGED, onBossesChanged)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_DEATH",    EVENT_UNIT_DEATH_STATE_CHANGED, onUnitDeathStateChanged)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_POI",      EVENT_POI_STATE_CHANGED, onPOIStateChanged)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_COMBAT",   EVENT_PLAYER_COMBAT_STATE, onPlayerCombatState)
    EVENT_MANAGER:RegisterForEvent(self.id .. "_LVL",      EVENT_LEVEL_UPDATE, onLevelUpdate)

    -- Evaluate immediately on enable (covers /reload or logins)
    evaluateLevelAutoFail()

    CM:NotifyDirty()
end

function Chal.onDisable(self)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_BOSSSET", EVENT_BOSSES_CHANGED)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_DEATH",   EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_POI",     EVENT_POI_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_COMBAT",  EVENT_PLAYER_COMBAT_STATE)
    EVENT_MANAGER:UnregisterForEvent(self.id .. "_LVL",     EVENT_LEVEL_UPDATE)
end

function Chal.onComplete(self)
    -- handled in tryCountKill
end

CM:Register(Chal)
