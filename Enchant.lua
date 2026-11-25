-- SkillUp & Profit :: Enchant
-- Enchants are cast onto an item, not crafted. This finds the item to put the enchant on
-- (gear with no enchant first, in your bags or worn; else your own worn gear) and casts it
-- there in one click, so you can level Enchanting by re-enchanting.

local _, CSU = ...
local E = {}
CSU.Enchant = E

-- "Enchant Bracer - Minor Health" -> wrist ... Only slots a normal enchant goes on.
local SLOTS = {
	["bracer"]    = { slot = 9,  label = "Wrist",  locs = { INVTYPE_WRIST = true } },
	["chest"]     = { slot = 5,  label = "Chest",  locs = { INVTYPE_CHEST = true, INVTYPE_ROBE = true } },
	["cloak"]     = { slot = 15, label = "Cloak",  locs = { INVTYPE_CLOAK = true } },
	["boots"]     = { slot = 8,  label = "Boots",  locs = { INVTYPE_FEET = true } },
	["gloves"]    = { slot = 10, label = "Gloves", locs = { INVTYPE_HAND = true } },
	["shield"]    = { slot = 17, label = "Shield", locs = { INVTYPE_SHIELD = true } },
	["weapon"]    = { slot = 16, alt = 17, label = "Weapon",
		locs = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_2HWEAPON = true } },
	["2h weapon"] = { slot = 16, label = "2H Weapon", locs = { INVTYPE_2HWEAPON = true } },
}

-- Which slot an enchant recipe goes on (nil = not an item enchant: rods, oils, wands... craft normally)
function E:SlotFor(entry)
	if not entry or entry.outputItemID then return nil end
	local name = entry.name or ""
	local what = name:match("^Enchant ([%w%s]-)%s*%-") or name:match("^Enchant ([%w%s]+)$")
	if not what then return nil end
	return SLOTS[what:lower()]
end

---------------------------------------------------------------------------
-- Finding the item
---------------------------------------------------------------------------
local function EquipLoc(itemID)
	if not itemID then return nil end
	local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not fn then return nil end
	local ok, _, _, _, loc = pcall(fn, itemID)
	return ok and loc or nil
end

-- item:ID:ENCHANT:... -> has an enchant?
local function HasEnchant(link)
	if type(link) ~= "string" then return false end
	local ench = link:match("item:%-?%d+:(%-?%d*)")
	return ench ~= nil and ench ~= "" and ench ~= "0"
end
E.HasEnchant = HasEnchant

local function GUIDOf(loc)
	if not (loc and C_Item and C_Item.GetItemGUID) then return nil end
	local ok, guid = pcall(C_Item.GetItemGUID, loc)
	return ok and guid or nil
end

local function Practice()
	local char = CSU:GetCharDB()
	char.practiceItems = char.practiceItems or {}
	return char.practiceItems
end

local function Candidate(kind, a, b, link, itemID)
	local loc
	if ItemLocation then
		if kind == "equip" then
			loc = ItemLocation:CreateFromEquipmentSlot(a)
		else
			loc = ItemLocation:CreateFromBagAndSlot(a, b)
		end
	end
	local guid = GUIDOf(loc)
	return {
		kind = kind, slot = (kind == "equip") and a or nil, bag = (kind == "bag") and a or nil,
		bagSlot = (kind == "bag") and b or nil, link = link, itemID = itemID, loc = loc, guid = guid,
		enchanted = HasEnchant(link), practice = guid and Practice()[guid] or false,
		name = (link and link:match("%[(.-)%]")) or CSU:GetItemName(itemID),
	}
end

-- Best item for this enchant:
-- 1) an item you practised on before (re-enchanting it is fine)
-- 2) gear with no enchant: in your bags, then worn
-- 3) your own worn gear (it has an enchant: needs a second click to confirm)
function E:FindTarget(info)
	if not info then return nil end
	local practice, freeBag, freeWorn, worn
	local slots = { info.slot }
	if info.alt then table.insert(slots, info.alt) end
	for _, s in ipairs(slots) do
		local link = GetInventoryItemLink and GetInventoryItemLink("player", s)
		local id = GetInventoryItemID and GetInventoryItemID("player", s)
		if link and id and info.locs[EquipLoc(id) or ""] then
			local c = Candidate("equip", s, nil, link, id)
			if c.practice then practice = practice or c
			elseif not c.enchanted then freeWorn = freeWorn or c
			else worn = worn or c end
		end
	end
	if C_Container and C_Container.GetContainerNumSlots then
		for bag = 0, (NUM_BAG_SLOTS or 4) do
			for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
				local ok, it = pcall(C_Container.GetContainerItemInfo, bag, slot)
				if ok and type(it) == "table" and it.itemID and info.locs[EquipLoc(it.itemID) or ""] then
					local c = Candidate("bag", bag, slot, it.hyperlink, it.itemID)
					if c.practice then practice = practice or c
					elseif not c.enchanted then freeBag = freeBag or c end
				end
			end
		end
	end
	return practice or freeBag or freeWorn or worn
end

function E:Describe(t)
	if not t then return "no item to enchant" end
	local where = (t.kind == "equip") and "worn" or "in your bags"
	if t.practice then return string.format("%s (%s, practice item)", t.name or "?", where) end
	if not t.enchanted then return string.format("%s (%s, no enchant)", t.name or "?", where) end
	return string.format("%s (%s, HAS an enchant)", t.name or "?", where)
end

---------------------------------------------------------------------------
-- Casting
---------------------------------------------------------------------------
local confirmUntil, confirmKey = 0, nil

-- open: function that opens the profession to the recipe (from the UI)
function E:Cast(entry, openRecipe)
	local info = self:SlotFor(entry)
	if not info then return false end
	local t = self:FindTarget(info)
	if not t then
		CSU:Print("No %s to enchant. Put on or carry any %s (a cheap vendor one is fine for levelling).", info.label:lower(), info.label:lower())
		return false
	end
	-- worn gear with someone else's enchant: click twice
	if t.enchanted and not t.practice then
		local key = (t.guid or t.link or "") .. ":" .. tostring(entry.recipeID)
		local now = GetTime and GetTime() or 0
		if confirmKey ~= key or now > confirmUntil then
			confirmKey, confirmUntil = key, now + 6
			CSU:Print("%s already has an enchant. Click Enchant again within 6 seconds to replace it.", t.name or "That item")
			return false
		end
		confirmKey = nil
	end

	local T = C_TradeSkillUI
	local ready = T and T.IsTradeSkillReady and T.IsTradeSkillReady()
	local live = ready and T.GetRecipeInfo and select(2, pcall(T.GetRecipeInfo, entry.recipeID)) or nil
	if not (live and live.learned) then
		if openRecipe then openRecipe(entry.recipeID) end
		CSU:Print("Opened Enchanting: click Enchant again.")
		return false
	end

	local can, why = true, nil
	if CSU.UI and CSU.UI.CheckCraft then can, why = CSU.UI.CheckCraft(entry.recipeID, 1) end
	if not can then
		CSU:ShowError(why)
		return false
	end
	if CSU.CastBar then CSU.CastBar:WatchErrors(3) end

	local cast = false
	if T.CraftEnchant and t.loc then
		cast = pcall(T.CraftEnchant, entry.recipeID, 1, nil, t.loc)
	end
	if not cast and T.CraftRecipe then
		-- older way: cast, then put it on the item
		cast = pcall(T.CraftRecipe, entry.recipeID, 1)
		if cast and SpellIsTargeting and SpellIsTargeting() then
			if t.kind == "equip" and PickupInventoryItem then
				PickupInventoryItem(t.slot)
			elseif C_Container and C_Container.PickupContainerItem then
				C_Container.PickupContainerItem(t.bag, t.bagSlot)
			end
		end
	end
	if cast then
		if t.guid then Practice()[t.guid] = true end
		CSU:Print("Enchanting %s.", self:Describe(t))
	else
		CSU:Print("Couldn't cast the enchant here. Cast it from the profession window and click the item.")
	end
	return cast
end
