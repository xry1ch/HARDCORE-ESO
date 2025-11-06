--[[
File: HARDCORE/RuleManager.lua
Author: You + ChatGPT
Purpose: Lightweight rule system manager for HARDCORE.

Design goals:
- Minimal complexity; single place to register and toggle rules.
- Each rule lives in its own file and calls RuleManager:RegisterRule({...}).
- Per-character enable/disable for each rule (defaults come from the rule file).
- Manager turns rules on/off when Hardcore Mode is toggled in the UI.

Public API (attach under global HARDCORE table):
  HARDCORE.RuleManager:RegisterRule(rule)
  HARDCORE.RuleManager:EnableRule(id)
  HARDCORE.RuleManager:DisableRule(id)
  HARDCORE.RuleManager:SetActive(isActive)      -- called by UI after Accept/Surrender
  HARDCORE.RuleManager:RefreshActiveState()     -- re-applies based on saved.isActive
  HARDCORE.RuleManager:GetRule(id)
  HARDCORE.RuleManager:ForEachRule(fn)

Rule contract (simple):
  local Rule = {
    id = "NoGrouping",                -- unique string id
    title = "No grouping",            -- display title
    icon = "/esoui/.../icon.dds",    -- optional
    defaultEnabled = true,             -- rule enabled by default (per character)

    OnEnable = function(self)
      -- Register events / hooks here
    end,
    OnDisable = function(self)
      -- Unregister events / hooks here
    end,
  }
  HARDCORE.RuleManager:RegisterRule(Rule)

Saved variables:
  Account-wide (already exists): HARDCORE.saved.isActive (bool)
  Per-character: HARDCORE_Rules_SV.enabled[ruleId] = true/false
]] local RuleManager = {}
RuleManager.__index = RuleManager

-- Runtime containers
RuleManager.rules = {} -- id -> rule table
RuleManager.enabledRuntime = {} -- id -> bool (currently enabled in session)

-- Light wrapper for debug printing
local function log(msg)
    if msg then
        d(string.format("[HARDCORE] %s", tostring(msg)))
    end
end

-- Per-character saved vars (rule enable states)
local function GetCharSV()
    if not HARDCORE or not HARDCORE.rulesSaved then
        -- version 1, default structure
        HARDCORE.rulesSaved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_Rules_SV", 1, nil, {
            enabled = {}
        })
    end
    return HARDCORE.rulesSaved
end

-- Ensure saved state for a rule exists (defaults to rule.defaultEnabled)
local function EnsureSavedEnable(rule)
    local sv = GetCharSV()
    if sv.enabled[rule.id] == nil then
        sv.enabled[rule.id] = (rule.defaultEnabled ~= false) -- default true unless explicitly false
    end
    return sv.enabled[rule.id]
end

-- Register a rule provided by a rule file
function RuleManager:RegisterRule(rule)
    assert(type(rule) == "table" and rule.id, "Rule must be a table with a unique 'id'")
    assert(not self.rules[rule.id], ("Duplicate rule id '%s'"):format(tostring(rule.id)))
    self.rules[rule.id] = rule
    EnsureSavedEnable(rule)
    -- If Hardcore is active at the time of registration and the rule is enabled, enable it now
    if HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive then
        local sv = GetCharSV()
        if sv.enabled[rule.id] then
            self:EnableRule(rule.id)
        end
    end
    log("Registered rule: " .. rule.id)
end

function RuleManager:GetRule(id)
    return self.rules[id]
end

function RuleManager:ForEachRule(fn)
    for id, rule in pairs(self.rules) do
        fn(id, rule)
    end
end

-- Internal helper to safely call rule methods
local function safeCall(what, rule, fnName)
    local ok, err = pcall(rule[fnName], rule)
    if not ok then
        log(string.format("%s failed for rule '%s': %s", what, tostring(rule.id), tostring(err)))
    end
end

-- Enable a single rule (if not already enabled)
function RuleManager:EnableRule(id)
    local rule = self.rules[id]
    if not rule then
        return
    end
    if self.enabledRuntime[id] then
        return
    end -- already enabled
    if type(rule.OnEnable) == "function" then
        safeCall("OnEnable", rule, "OnEnable")
    end
    self.enabledRuntime[id] = true
    GetCharSV().enabled[id] = true
    log("Enabled rule: " .. id)
end

-- Disable a single rule (if currently enabled)
function RuleManager:DisableRule(id)
    local rule = self.rules[id]
    if not rule then
        return
    end
    if not self.enabledRuntime[id] then
        return
    end
    if type(rule.OnDisable) == "function" then
        safeCall("OnDisable", rule, "OnDisable")
    end
    self.enabledRuntime[id] = false
    GetCharSV().enabled[id] = false
    log("Disabled rule: " .. id)
end

-- Apply all rules according to saved per-character enabled flags
function RuleManager:ApplyAll()
    local sv = GetCharSV()
    for id, rule in pairs(self.rules) do
        if sv.enabled[id] then
            self:EnableRule(id)
        else
            self:DisableRule(id)
        end
    end
end

-- Disable all rules (used when Hardcore Mode is turned off)
function RuleManager:DisableAll()
    for id, _ in pairs(self.enabledRuntime) do
        if self.enabledRuntime[id] then
            self:DisableRule(id)
        end
    end
end

-- To be called from UI code when mode toggles (Accept / Surrender)
function RuleManager:SetActive(isActive)
    if not HARDCORE or not HARDCORE.saved then
        return
    end
    HARDCORE.saved.isActive = isActive and true or false
    if HARDCORE.saved.isActive then
        self:ApplyAll()
    else
        self:DisableAll()
    end
end

-- Re-apply rules based on current saved.isActive (call on load or if you suspect drift)
function RuleManager:RefreshActiveState()
    local active = HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive
    if active then
        self:ApplyAll()
    else
        self:DisableAll()
    end
end

-- Initialize manager (call once after saved vars are ready)
function RuleManager:Init()
    GetCharSV() -- ensure SV created
    self:RefreshActiveState()
    log("RuleManager initialized (active=" .. tostring(HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive) .. ")")
end

-- Expose under global HARDCORE table
HARDCORE = HARDCORE or {}
HARDCORE.RuleManager = RuleManager

return RuleManager
