local Rule = {
  id = "NoMail",
  title = "No mail",
  icon = "/esoui/art/addons/gamepad/gp_mod_listing_category_mail.dds",
  defaultEnabled = true,
}

local NS = "HARDCORE_NoMail"
Rule.active = false
Rule._hooksInstalled = false

local function Announce()
  ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, "HARDCORE: Mail is disabled until level 50.")
end

local function Below50()
  local level = GetUnitLevel("player") or 1
  return level < 50
end

local function InstallHooks()
  if Rule._hooksInstalled then return end

  ZO_PreHook(SCENE_MANAGER, "Show", function(_, arg)
    local sceneName
    if type(arg) == "string" then
      sceneName = arg
    elseif type(arg) == "table" and arg.GetName then
      sceneName = arg:GetName()
    end
    if sceneName and Rule.active and Below50() and (sceneName == "mailInbox" or sceneName == "mailSend") then
      Announce()
      return true
    end
  end)

  local inbox = SCENE_MANAGER:GetScene("mailInbox")
  if inbox then
    inbox:RegisterCallback("StateChange", function(_, newState)
      if Rule.active and Below50() and newState == SCENE_SHOWING then
        Announce()
        SCENE_MANAGER:HideCurrentScene()
      end
    end)
  end
  local send = SCENE_MANAGER:GetScene("mailSend")
  if send then
    send:RegisterCallback("StateChange", function(_, newState)
      if Rule.active and Below50() and newState == SCENE_SHOWING then
        Announce()
        SCENE_MANAGER:HideCurrentScene()
      end
    end)
  end

  EVENT_MANAGER:RegisterForEvent(NS.."_MAILBOX", EVENT_MAIL_OPEN_MAILBOX, function()
    if Rule.active and Below50() then
      Announce()
      pcall(function() if CloseMailbox then CloseMailbox() end end)
      local current = SCENE_MANAGER:GetCurrentScene()
      if current then
        local name = current:GetName()
        if name == "mailInbox" or name == "mailSend" then
          SCENE_MANAGER:HideCurrentScene()
        end
      end
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

local function TryRegister()
  if HARDCORE and HARDCORE.RuleManager and HARDCORE.RuleManager.RegisterRule then
    HARDCORE.RuleManager:RegisterRule(Rule)
    EVENT_MANAGER:UnregisterForEvent(NS.."_DEFER", EVENT_ADD_ON_LOADED)
  end
end

if HARDCORE and HARDCORE.RuleManager then
  TryRegister()
else
  EVENT_MANAGER:RegisterForEvent(NS.."_DEFER", EVENT_ADD_ON_LOADED, TryRegister)
end