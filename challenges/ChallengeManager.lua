-- File: challenges/ChallengeManager.lua
-- Minimal manager for registering challenges, tracking state, points and UI updates.
-- API (under HARDCORE): 
--   HARDCORE.ChallengeManager:Register(chal)
--   HARDCORE.ChallengeManager:SetActive(isActive)
--   HARDCORE.ChallengeManager:GetPoints()
--   HARDCORE.ChallengeManager:GetStatus(id) -> "ACTIVE"|"COMPLETED"|"FAILED"
--   HARDCORE.ChallengeManager:ForEach(fn)
--   HARDCORE.ChallengeManager:NotifyDirty() -- tell UI to refresh

local CM = {}
CM.__index = CM

local function log(msg) d(("[HARDCORE][Challenge] %s"):format(tostring(msg))) end

-- === SavedVars (per character) ============================================
local function GetSV()
  HARDCORE = HARDCORE or {}
  if not HARDCORE.challengeSaved then
    HARDCORE.challengeSaved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_Challenge_SV", 1, nil, {
      points = 0,
      state = {},   -- [id] = "ACTIVE"|"COMPLETED"|"FAILED"
      meta  = {},   -- [id] = {progress=0, completedAt=nil, failedAt=nil}
    })
  end
  return HARDCORE.challengeSaved
end

-- === Runtime ===============================================================
CM.challenges = {}     -- id -> challenge table
CM.enabled = {}        -- id -> bool (active in session)
CM._listeners = {}     -- UI listeners to refresh

local function fireDirty()
  for _, fn in ipairs(CM._listeners) do
    pcall(fn)
  end
end

function CM:On(event, fn)
  table.insert(self._listeners, fn)
end

local function setState(id, newState)
  local sv = GetSV()
  sv.state[id] = newState
  fireDirty()
end

local function getState(id)
  return GetSV().state[id] or "ACTIVE"
end

local function setMeta(id, k, v)
  local sv = GetSV()
  sv.meta[id] = sv.meta[id] or {}
  sv.meta[id][k] = v
end

local function getMeta(id)
  local m = GetSV().meta[id]
  if not m then m = {progress=0}; GetSV().meta[id] = m end
  return m
end

local function addPoints(n)
  local sv = GetSV()
  sv.points = math.max(0, (sv.points or 0) + (n or 0))
  fireDirty()
end

-- === Public API ============================================================
function CM:Register(chal)
  assert(type(chal)=="table" and chal.id, "Challenge must have unique id")
  assert(not self.challenges[chal.id], "Duplicate challenge id: "..tostring(chal.id))
  -- required fields with sane defaults
  chal.title       = chal.title or chal.id
  chal.points      = tonumber(chal.points) or 0
  chal.icon        = chal.icon or "/esoui/art/achievements/achievement_skills_tabicon_up.dds"
  chal.getProgress = chal.getProgress or function() return 0, 1 end -- cur, max
  chal.onEnable    = chal.onEnable or function() end
  chal.onDisable   = chal.onDisable or function() end
  chal.onComplete  = chal.onComplete or function() end
  chal.onFail      = chal.onFail or function() end
  self.challenges[chal.id] = chal
  -- seed state
  getState(chal.id); getMeta(chal.id)
end

function CM:GetPoints()
  return GetSV().points or 0
end

function CM:GetStatus(id)
  return getState(id)
end

function CM:ForEach(fn)
  for id, c in pairs(self.challenges) do fn(id, c) end
end

function CM:_enableOne(id)
  local c = self.challenges[id]; if not c or self.enabled[id] then return end
  self.enabled[id] = true
  pcall(c.onEnable, c, function()
    -- allow challenges to push partial progress
    fireDirty()
  end)
end

function CM:_disableOne(id)
  local c = self.challenges[id]; if not c or not self.enabled[id] then return end
  self.enabled[id] = false
  pcall(c.onDisable, c)
end

function CM:SetActive(isActive)
  if isActive then
    for id in pairs(self.challenges) do self:_enableOne(id) end
  else
    for id in pairs(self.challenges) do self:_disableOne(id) end
  end
end

function CM:Complete(id)
  if self:GetStatus(id) ~= "COMPLETED" then
    setState(id, "COMPLETED")
    setMeta(id, "completedAt", GetTimeStamp())
    addPoints(self.challenges[id] and self.challenges[id].points or 0)
    if self.challenges[id] and self.challenges[id].onComplete then
      pcall(self.challenges[id].onComplete, self.challenges[id])
    end
  end
end

function CM:Fail(id)
  if self:GetStatus(id) ~= "FAILED" then
    setState(id, "FAILED")
    setMeta(id, "failedAt", GetTimeStamp())
    if self.challenges[id] and self.challenges[id].onFail then
      pcall(self.challenges[id].onFail, self.challenges[id])
    end
  end
end

function CM:GetProgress(id)
  local c = self.challenges[id]; if not c then return 0,1 end
  local cur, max = 0, 1
  local ok, a, b = pcall(c.getProgress, c)
  if ok and type(a)=="number" and type(b)=="number" and b>0 then cur, max = a, b end
  local m = getMeta(id); m.progress = cur
  return cur, max
end

function CM:NotifyDirty()
  fireDirty()
end

-- attach globally
HARDCORE = HARDCORE or {}
HARDCORE.ChallengeManager = CM
