-- File: challenges/Challenge_Level20.lua
-- Example: Reach character level 20.

local CM = HARDCORE and HARDCORE.ChallengeManager

local Chal = {
  id = "ReachLevel20",
  title = "Reach Level 20",
  points = 300,
  icon = "/esoui/art/achievements/achievement_icon_category_character.dds",
}

function Chal:getProgress()
  -- return current, target
  local lvl = GetUnitLevel("player") or 1
  return math.min(lvl, 20), 20
end

local function check()
  if not CM then return end
  local cur = GetUnitLevel("player") or 1
  if cur >= 20 then
    CM:Complete(Chal.id)
  else
    CM:NotifyDirty()
  end
end

function Chal.onEnable(self)
  EVENT_MANAGER:RegisterForEvent(self.id.."_LVL", EVENT_LEVEL_UPDATE, function(_, unitTag)
    if unitTag=="player" then check() end
  end)
  EVENT_MANAGER:RegisterForEvent(self.id.."_ACT", EVENT_PLAYER_ACTIVATED, function() check() end)
  check()
end

function Chal.onDisable(self)
  EVENT_MANAGER:UnregisterForEvent(self.id.."_LVL", EVENT_LEVEL_UPDATE)
  EVENT_MANAGER:UnregisterForEvent(self.id.."_ACT", EVENT_PLAYER_ACTIVATED)
end

if CM and CM.Register then CM:Register(Chal) end
