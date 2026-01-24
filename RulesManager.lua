local RuleManager = {}
RuleManager.__index = RuleManager

RuleManager.rules = {}
RuleManager.enabledRuntime = {}

local function log(msg)
    if msg then
        d(string.format("[HARDCORE] %s", tostring(msg)))
    end
end

local function GetCharSV()
    if not HARDCORE or not HARDCORE.rulesSaved then
        HARDCORE.rulesSaved = ZO_SavedVars:NewCharacterIdSettings("HARDCORE_Rules_SV", 1, nil, {
            enabled = {}
        })
    end
    return HARDCORE.rulesSaved
end

local function EnsureSavedEnable(rule)
    local sv = GetCharSV()
    if sv.enabled[rule.id] == nil then
        sv.enabled[rule.id] = (rule.defaultEnabled ~= false) and true or false
    end
    return sv.enabled[rule.id]
end

function RuleManager:RegisterRule(rule)
    assert(type(rule) == "table" and rule.id, "Rule must be a table with a unique 'id'")
    assert(not self.rules[rule.id], ("Duplicate rule id '%s'"):format(tostring(rule.id)))
    self.rules[rule.id] = rule
    EnsureSavedEnable(rule)
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

local function safeCall(what, rule, fnName)
    local ok, err = pcall(rule[fnName], rule)
    if not ok then
        log(string.format("%s failed for rule '%s': %s", what, tostring(rule.id), tostring(err)))
    end
end

function RuleManager:EnableRule(id)
    local rule = self.rules[id]
    if not rule then
        return
    end
    if self.enabledRuntime[id] then
        return
    end
    if type(rule.OnEnable) == "function" then
        safeCall("OnEnable", rule, "OnEnable")
    end
    self.enabledRuntime[id] = true
    GetCharSV().enabled[id] = true
    log("Enabled rule: " .. id)
end

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

function RuleManager:DisableAll()
    for id, _ in pairs(self.enabledRuntime) do
        if self.enabledRuntime[id] then
            self:DisableRule(id)
        end
    end
end

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

function RuleManager:RefreshActiveState()
    local active = HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive
    if active then
        self:ApplyAll()
    else
        self:DisableAll()
    end
end

function RuleManager:Init()
    GetCharSV()
    self:RefreshActiveState()
    log("RuleManager initialized (active=" .. tostring(HARDCORE and HARDCORE.saved and HARDCORE.saved.isActive) .. ")")
end

HARDCORE = HARDCORE or {}
HARDCORE.RuleManager = RuleManager

return RuleManager
