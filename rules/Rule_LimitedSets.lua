local Rule = {
  id = "LimitedSets",
  title = "Max 2 pieces per set",
  icon = "/esoui/art/icons/icon_1handed.dds",
  defaultEnabled = true,
}

local NS = "HARDCORE_LimitedSets"
Rule.active = false
Rule._installed = false
Rule._lastAlert = 0

-- === Config ===
local LIMIT = 2
local ALERT_COOLDOWN_MS = 1500
local ENFORCE_DELAY_MS = 60 -- slight delay lets the game finish the equip transaction

-- All worn equipment slots we care about (armor, jewelry, both weapon bars)
local WORN_SLOTS = {
  EQUIP_SLOT_HEAD,
  EQUIP_SLOT_SHOULDERS,
  EQUIP_SLOT_CHEST,
  EQUIP_SLOT_HAND,
  EQUIP_SLOT_WAIST,
  EQUIP_SLOT_LEGS,
  EQUIP_SLOT_FEET,
  EQUIP_SLOT_NECK,
  EQUIP_SLOT_RING1,
  EQUIP_SLOT_RING2,
  EQUIP_SLOT_MAIN_HAND,
  EQUIP_SLOT_OFF_HAND,
  EQUIP_SLOT_BACKUP_MAIN,
  EQUIP_SLOT_BACKUP_OFF,
}

-- === Helpers ===

local function canActNow()
  -- Don’t shuffle gear while in combat
  return not IsUnitInCombat("player")
end

local function alertOnce(msg)
  local now = GetFrameTimeMilliseconds()
  if now - Rule._lastAlert > ALERT_COOLDOWN_MS then
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, msg or "HARDCORE: Max 2 pieces per set.")
    Rule._lastAlert = now
  end
end

-- Returns counts[setId] = numberEquipped, and slotsBySet[setId] = {equipSlot, ...}
local function getEquippedSetTallies()
  local counts = {}
  local slotsBySet = {}

  for _, slot in ipairs(WORN_SLOTS) do
    local link = GetItemLink(BAG_WORN, slot)
    if link and link ~= "" then
      -- GetItemLinkSetInfo: hasSet, setName, numBonuses, numNormalEquipped, maxEquipped, setId, numPerfectedEquipped
      local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(link, true) -- equipped=true for consistency
      -- (Function signature from ESO_API.txt confirms availability and return values.) :contentReference[oaicite:0]{index=0}
      if hasSet and setId and setId > 0 then
        counts[setId] = (counts[setId] or 0) + 1
        local arr = slotsBySet[setId]
        if not arr then
          arr = {}
          slotsBySet[setId] = arr
        end
        table.insert(arr, slot)
      end
    end
  end

  return counts, slotsBySet
end

-- Unequip extras if any set exceeds LIMIT. If recentSlot is provided, we try to unequip that one first.
local function enforceLimit(recentSlot)
  if not Rule.active or not canActNow() then return end

  local changed = false
  local counts, slotsBySet = getEquippedSetTallies()

  for setId, count in pairs(counts) do
    if count > LIMIT then
      local slots = slotsBySet[setId] or {}

      -- Prefer to drop the most recently-changed slot if it belongs to this set
      if recentSlot then
        for i, slot in ipairs(slots) do
          if slot == recentSlot and count > LIMIT then
            UnequipItem(slot)
            changed = true
            count = count - 1
            table.remove(slots, i)
            break
          end
        end
      end

      -- If still over the limit, unequip arbitrary extras (from the end of the list)
      while count > LIMIT and #slots > 0 do
        local slot = table.remove(slots) -- pop last
        UnequipItem(slot)
        changed = true
        count = count - 1
      end
    end
  end

  if changed then
    alertOnce(string.format("HARDCORE: Max %d pieces per set. Extra item(s) unequipped.", LIMIT))
  end
end

-- === Event handlers & install ===

local function onInventoryChange(_, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
  if not Rule.active then return end
  if bagId ~= BAG_WORN then return end
  -- Run shortly after to let equipment settle
  zo_callLater(function() enforceLimit(slotIndex) end, ENFORCE_DELAY_MS)
end

local function onWeaponSwap()
  if not Rule.active then return end
  zo_callLater(function() enforceLimit(nil) end, ENFORCE_DELAY_MS)
end

local function onActivated()
  zo_callLater(function() enforceLimit(nil) end, 200)
end

local function onCombatState(_, inCombat)
  if not inCombat then
    zo_callLater(function() enforceLimit(nil) end, 120)
  end
end

local function Install()
  if Rule._installed then return end

  EVENT_MANAGER:RegisterForEvent(NS .. "_ACTIVATED", EVENT_PLAYER_ACTIVATED, onActivated)

  EVENT_MANAGER:RegisterForEvent(NS .. "_INV", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onInventoryChange)
  EVENT_MANAGER:AddFilterForEvent(NS .. "_INV", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)

  EVENT_MANAGER:RegisterForEvent(NS .. "_SWAP", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, onWeaponSwap)
  EVENT_MANAGER:RegisterForEvent(NS .. "_OOC", EVENT_PLAYER_COMBAT_STATE, onCombatState)

  Rule._installed = true
end

function Rule:OnEnable()
  self.active = true
  Install()
  zo_callLater(function() enforceLimit(nil) end, 100)
end

function Rule:OnDisable()
  self.active = false
end

-- Deferred registration with the RuleManager
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
