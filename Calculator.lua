-- CheapSkillUp :: Calculator
-- Snapshots learned recipes for any open profession and ranks the cheapest skill-ups
-- filtered by Red/Orange (Optimal), Yellow (Medium), and optional Green (Easy).

local _, CSU = ...
local Calc = {}
CSU.Calc = Calc

Calc.activeProfession = nil

-- Gathering professions have nothing to craft, so CheapSkillUp never shows or saves them.
-- Matched by skill line ID (any language) and by English name.
local GATHERING_IDS = { [182] = true, [393] = true, [356] = true, [794] = true } -- Herbalism, Skinning, Fishing, Archaeology
local GATHERING_NAMES = { herbalism = true, skinning = true, fishing = true, archaeology = true }

function Calc:IsGathering(name, professionID)
	if professionID and GATHERING_IDS[professionID] then return true end
	if type(name) == "string" and GATHERING_NAMES[name:lower()] then return true end
	return false
end

-- Removes gathering professions saved by older versions.
function Calc:PurgeGathering()
	if not (CSU.db and CSU.db.chars) then return end
	for _, char in pairs(CSU.db.chars) do
		if type(char.professions) == "table" then
			for name, data in pairs(char.professions) do
				if self:IsGathering(name, type(data) == "table" and data.professionID or nil) then
					char.professions[name] = nil
				end
			end
		end
	end
	if self.activeProfession and self:IsGathering(self.activeProfession) then
		self.activeProfession = nil
	end
end

-- Live skill of a profession the character has, by name: skillLevel, maxSkillLevel, icon, skillLine.
-- WoW Forever's GetProfessions() returns prof1, prof2, firstAid, fishing, cooking
-- (retail order is prof1, prof2, archaeology, fishing, cooking), so every returned slot is read.
local function GetLiveProfessions()
	local out = {}
	if not (GetProfessions and GetProfessionInfo) then return out end
	local res = { pcall(GetProfessions) }
	if not res[1] then return out end
	for i = 2, 8 do
		local idx = res[i]
		if idx then
			local ok, name, icon, skillLevel, maxSkillLevel, _, _, skillLine = pcall(GetProfessionInfo, idx)
			if ok and name and name ~= "" and not out[name] then
				out[name] = { name = name, icon = icon, skillLevel = skillLevel, maxSkillLevel = maxSkillLevel, skillLine = skillLine, order = i }
			end
		end
	end
	return out
end
Calc.GetLiveProfessions = GetLiveProfessions

local function BasicReagentType()
	return (Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic) or 0
end

local function NormalizeDifficulty(relDiff)
	local diff = Enum and Enum.TradeskillRelativeDifficulty
	if diff then
		if relDiff == diff.Optimal then return "optimal" end
		if relDiff == diff.Medium then return "medium" end
		if relDiff == diff.Easy then return "easy" end
		if relDiff == diff.Trivial then return "trivial" end
	end
	-- Numeric fallbacks if Enum differs
	if relDiff == 0 then return "optimal" end
	if relDiff == 1 then return "medium" end
	if relDiff == 2 then return "easy" end
	return "trivial"
end

function Calc:GetDifficultyMeta(key)
	if key == "optimal" then
		return "RED/ORG", CSU.COLORS.optimal, 1
	elseif key == "medium" then
		return "YELLOW", CSU.COLORS.medium, 2
	elseif key == "easy" then
		return "GREEN", CSU.COLORS.easy, 3
	end
	return "GRAY", CSU.COLORS.trivial, 4
end

---------------------------------------------------------------------------
-- Profession Snapshot Capture (works for any profession via C_TradeSkillUI)
---------------------------------------------------------------------------

local function IsPlayerOwnTradeSkill()
	local T = C_TradeSkillUI
	if not T then return false end
	if T.IsTradeSkillReady and not T.IsTradeSkillReady() then return false end
	if T.IsTradeSkillLinked and T.IsTradeSkillLinked() then return false end
	if T.IsTradeSkillGuild and T.IsTradeSkillGuild() then return false end
	if T.IsNPCCrafting and T.IsNPCCrafting() then return false end
	return true
end

local function GetOpenProfessionMeta()
	local T = C_TradeSkillUI
	if not T then return nil end
	local info
	if T.GetChildProfessionInfo then
		local ok, child = pcall(T.GetChildProfessionInfo)
		if ok and child and child.professionName and child.professionName ~= "" then
			info = child
		end
	end
	if not info and T.GetBaseProfessionInfo then
		local ok, base = pcall(T.GetBaseProfessionInfo)
		if ok and base and base.professionName and base.professionName ~= "" then
			info = base
		end
	end
	if not info then return nil end
	return {
		name = info.professionName,
		skillLevel = info.skillLevel or 0,
		maxSkillLevel = info.maxSkillLevel or 0,
		professionID = info.professionID,
		icon = info.professionIcon,
	}
end

function Calc:ScanOpenProfession()
	if not IsPlayerOwnTradeSkill() then return false end
	local T = C_TradeSkillUI
	if not (T.GetAllRecipeIDs and T.GetRecipeInfo and T.GetRecipeSchematic) then return false end

	local meta = GetOpenProfessionMeta()
	if not meta then return false end
	if self:IsGathering(meta.name, meta.professionID) then
		CSU:GetCharDB().professions[meta.name] = nil
		return false
	end

	local okIds, recipeIDs = pcall(T.GetAllRecipeIDs)
	if not okIds or type(recipeIDs) ~= "table" then return false end

	local basic = BasicReagentType()
	local recipes = {}

	for _, recipeID in ipairs(recipeIDs) do
		local okInfo, info = pcall(T.GetRecipeInfo, recipeID)
		if okInfo and info and info.learned and not info.disabled then
			local diffKey = NormalizeDifficulty(info.relativeDifficulty)
			if CSU.Thresholds then
				CSU.Thresholds:Observe(recipeID, meta.skillLevel, diffKey)
			end
			-- Every learned recipe is stored: grey ones are still wanted by the Best profit mode.
			do
				local okSchem, schematic = pcall(T.GetRecipeSchematic, recipeID, false)
				if okSchem and type(schematic) == "table" then
					local slots = {}
					for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
						if slot.reagentType == basic and slot.required ~= false then
							local itemIDs = {}
							for _, reagent in ipairs(slot.reagents or {}) do
								if reagent.itemID then
									table.insert(itemIDs, reagent.itemID)
								end
							end
							if #itemIDs > 0 then
								table.insert(slots, {
									qty = slot.quantityRequired or 1,
									items = itemIDs,
								})
							end
						end
					end

					if #slots > 0 then
						recipes[recipeID] = {
							id = recipeID,
							name = info.name or schematic.name or ("Recipe #" .. tostring(recipeID)),
							icon = info.icon or schematic.icon,
							difficulty = diffKey,
							numSkillUps = (info.numSkillUps and info.numSkillUps > 0) and info.numSkillUps or 1,
							outputItemID = (schematic.outputItemID and schematic.outputItemID > 0) and schematic.outputItemID or nil,
							outputQty = ((schematic.quantityMin or 1) + (schematic.quantityMax or schematic.quantityMin or 1)) / 2,
							noSkillUp = (info.canSkillUp == false) or nil,
							slots = slots,
						}
					end
				end
			end
		end
	end

	local charDB = CSU:GetCharDB()
	local prev = charDB.professions[meta.name]
	charDB.professions[meta.name] = {
		name = meta.name,
		skillLevel = meta.skillLevel,
		maxSkillLevel = meta.maxSkillLevel,
		professionID = meta.professionID,
		icon = meta.icon or (prev and prev.icon) or nil,
		updatedAt = time(),
		recipes = recipes,
	}

	self.activeProfession = meta.name
	self:InvalidateMakers()
	CSU:Fire("PROFESSION_UPDATED", meta.name)
	return true
end

function Calc:GetSavedProfessionNames()
	local charDB = CSU:GetCharDB()
	local names = {}
	for name, data in pairs(charDB.professions) do
		if not self:IsGathering(name, type(data) == "table" and data.professionID or nil) then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

-- Returns an ordered list of professions for the left sidebar, merging live character
-- professions (with icons & live skill levels) with saved recipe snapshots.
function Calc:GetSidebarProfessions()
	local charDB = CSU:GetCharDB()
	local byName = {}
	local order = {}

	local function AddOrMerge(name, icon, skill, maxSkill, saved)
		if not name or name == "" then return end
		local entry = byName[name]
		if not entry then
			local recCount = 0
			if saved and saved.recipes then
				for _ in pairs(saved.recipes) do recCount = recCount + 1 end
			end
			entry = {
				name = name,
				icon = icon or (saved and saved.icon) or 134400,
				skillLevel = skill or (saved and saved.skillLevel) or 0,
				maxSkillLevel = maxSkill or (saved and saved.maxSkillLevel) or 0,
				scanned = saved ~= nil,
				recipeCount = recCount,
			}
			byName[name] = entry
			table.insert(order, entry)
		else
			if icon then entry.icon = icon end
			if skill and skill > 0 then entry.skillLevel = skill end
			if maxSkill and maxSkill > 0 then entry.maxSkillLevel = maxSkill end
			if saved then
				entry.scanned = true
				local recCount = 0
				for _ in pairs(saved.recipes or {}) do recCount = recCount + 1 end
				entry.recipeCount = recCount
			end
		end
	end

	-- 1. Live character professions (primary 1, primary 2, then cooking, first aid; gathering skipped)
	local live = GetLiveProfessions()
	local liveList = {}
	for _, p in pairs(live) do table.insert(liveList, p) end
	local function rank(p)
		local lower = p.name:lower()
		if p.order <= 3 and lower ~= "first aid" and lower ~= "archaeology" then return p.order end -- primaries
		if lower == "cooking" then return 10 end
		if lower == "first aid" then return 11 end
		return 20 + p.order
	end
	table.sort(liveList, function(x, y) return rank(x) < rank(y) end)
	for _, p in ipairs(liveList) do
		if not self:IsGathering(p.name, p.skillLine) then
			AddOrMerge(p.name, p.icon, p.skillLevel, p.maxSkillLevel, charDB.professions[p.name])
		end
	end

	-- 2. Any other saved professions not returned by GetProfessions
	for _, name in ipairs(self:GetSavedProfessionNames()) do
		local saved = charDB.professions[name]
		if not byName[name] then
			-- Live skill (step 1) always wins over the saved snapshot's old numbers
			AddOrMerge(name, saved.icon, saved.skillLevel, saved.maxSkillLevel, saved)
		end
	end

	return order
end

function Calc:GetProfessionData(profName)
	local charDB = CSU:GetCharDB()
	local name = profName or self.activeProfession
	if name and charDB.professions[name] then
		return charDB.professions[name]
	end
	-- Fall back to first saved profession
	local names = self:GetSavedProfessionNames()
	if names[1] then
		self.activeProfession = names[1]
		return charDB.professions[names[1]]
	end
	return nil
end

function Calc:SetActiveProfession(profName)
	local charDB = CSU:GetCharDB()
	if profName and charDB.professions[profName] then
		self.activeProfession = profName
		CSU:Fire("PROFESSION_UPDATED", profName)
	end
end

---------------------------------------------------------------------------
-- Cheapest Skill-Up Evaluation
---------------------------------------------------------------------------

-- Modes:
--   cheap    = cheapest skill-up (mats only)
--   earnback = skill up, counting what the crafted item sells back for (vendor or AH, whichever pays more)
--   profit   = best earnings per craft, any colour, skill-ups ignored
Calc.MODES = { "normal", "cheap", "earnback", "profit" }
Calc.MODE_LABELS = { normal = "Normal", cheap = "Cheapest", earnback = "Level + Earn", profit = "Best Profit" }

function Calc:GetMode()
	local m = CSU.settings and CSU.settings.mode
	if m == "earnback" or m == "profit" or m == "normal" then return m end
	return "cheap"
end

function Calc:SetMode(m)
	if not self.MODE_LABELS[m] then m = "cheap" end
	CSU.settings.mode = m
	CSU:Fire("FILTER_CHANGED")
end

function Calc:CycleMode()
	local cur = self:GetMode()
	for i, m in ipairs(self.MODES) do
		if m == cur then
			self:SetMode(self.MODES[(i % #self.MODES) + 1])
			return
		end
	end
	self:SetMode("cheap")
end

---------------------------------------------------------------------------
-- Bag items mode: only use the items you have ticked in your bags
---------------------------------------------------------------------------

-- Item counts in the bags you carry, plus the bank when Mats From Bank is on.
-- Cached until the bags or the bank change.
function Calc:GetBagCounts()
	local bags = self:GetCarriedCounts()
	if not (CSU.settings and CSU.settings.includeBank) then return bags end
	local char = CSU:GetCharDB()
	local bank = char and char.bank
	if not bank then return bags end
	local key = tostring(bags) .. ":" .. tostring(char.bankAt)
	if self._withBank and self._withBankKey == key then return self._withBank end
	local out = {}
	for id, n in pairs(bags) do out[id] = n end
	for id, n in pairs(bank) do out[id] = (out[id] or 0) + n end
	self._withBank, self._withBankKey = out, key
	return out
end

function Calc:GetCarriedCounts()
	if self._bagCache then return self._bagCache end
	local counts = {}
	local C = C_Container
	if C and C.GetContainerNumSlots and C.GetContainerItemInfo then
		local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
		for bag = 0, last do
			local ok, n = pcall(C.GetContainerNumSlots, bag)
			if ok and type(n) == "number" then
				for slot = 1, n do
					local ok2, info = pcall(C.GetContainerItemInfo, bag, slot)
					if ok2 and type(info) == "table" and info.itemID then
						counts[info.itemID] = (counts[info.itemID] or 0) + (info.stackCount or 1)
					end
				end
			end
		end
	end
	self._bagCache = counts
	return counts
end

function Calc:IsBagMode()
	return CSU.settings and CSU.settings.bagOnly and true or false
end

function Calc:IsTicked(itemID)
	local un = CSU.settings and CSU.settings.bagUnticked
	return not (un and un[itemID])
end

function Calc:SetTicked(itemID, on)
	CSU.settings.bagUnticked = CSU.settings.bagUnticked or {}
	CSU.settings.bagUnticked[itemID] = (not on) or nil
	CSU:Fire("FILTER_CHANGED")
end

function Calc:IsVendorMat(itemID)
	return CSU.Prices and CSU.Prices.GetVendorPrice and CSU.Prices:GetVendorPrice(itemID) ~= nil
end

-- Reagents of this profession's known recipes that are in your bags right now, sorted by name.
-- Each: { itemID, count, name, icon, ticked, vendor }
function Calc:GetBagReagents(profName)
	local prof = self:GetProfessionData(profName)
	local out = {}
	if not prof then return out end
	local bags = self:GetBagCounts()
	local seen = {}
	for _, rec in pairs(prof.recipes or {}) do
		for _, slot in ipairs(rec.slots or {}) do
			for _, itemID in ipairs(slot.items or {}) do
				local n = bags[itemID]
				if n and n > 0 and not seen[itemID] then
					seen[itemID] = true
					local _, _, _, icon = CSU:GetItemInfoSafe(itemID)
					table.insert(out, {
						itemID = itemID,
						count = n,
						name = CSU:GetItemName(itemID),
						icon = icon,
						ticked = self:IsTicked(itemID),
						vendor = self:IsVendorMat(itemID),
					})
				end
			end
		end
	end
	table.sort(out, function(a, b) return (a.name or "") < (b.name or "") end)
	return out
end

function Calc:SetAllTicked(profName, on)
	CSU.settings.bagUnticked = CSU.settings.bagUnticked or {}
	for _, r in ipairs(self:GetBagReagents(profName)) do
		CSU.settings.bagUnticked[r.itemID] = (not on) or nil
	end
	CSU:Fire("FILTER_CHANGED")
end

---------------------------------------------------------------------------
-- Categories (Chest, Legs, Potion, Elixir...) and level filter
---------------------------------------------------------------------------

local categoryCache = {}

-- Group name for a recipe, from what it makes: the gear slot (Chest, Legs, Feet...),
-- else the item kind (Potion, Elixir, Bandage, Leather...). Enchants use "Enchant <Slot> - ...".
function Calc:GetCategory(outputItemID, name)
	local key = outputItemID or name
	if key and categoryCache[key] then return categoryCache[key] end
	local cat
	local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	local known = false
	if outputItemID and fn then
		local ok, _, itemType, subType, equipLoc = pcall(fn, outputItemID)
		if ok and itemType then
			known = true
			if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" and equipLoc ~= "INVTYPE_NON_EQUIP" then
				if equipLoc == "INVTYPE_ROBE" then equipLoc = "INVTYPE_CHEST" end
				cat = _G[equipLoc] or (equipLoc:gsub("^INVTYPE_", ""))
			elseif subType and subType ~= "" and subType ~= "Other" then
				cat = subType
			elseif itemType ~= "" then
				cat = itemType
			end
		end
	end
	if not cat and type(name) == "string" then
		cat = name:match("^Enchant (.-) %- ")
		if cat then known = true end
	end
	cat = cat or "Other"
	if key and known then categoryCache[key] = cat end
	return cat
end

-- Required level of the crafted item (nil while the item isn't loaded yet)
function Calc:GetRequiredLevel(itemID)
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if not (itemID and fn) then return nil end
	local ok, name, _, _, _, minLevel = pcall(fn, itemID)
	if ok and name then return tonumber(minLevel) end
	return nil
end

-- Item level and required level of the crafted item (0, 0 when unknown)
function Calc:GetItemLevels(itemID)
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if not (itemID and fn) then return 0, 0 end
	local ok, name, _, _, itemLevel, minLevel = pcall(fn, itemID)
	if ok and name then return tonumber(itemLevel) or 0, tonumber(minLevel) or 0 end
	return 0, 0
end

---------------------------------------------------------------------------
-- Training: when you can learn the next rank, and where (WoW Forever trainers)
---------------------------------------------------------------------------
-- Ranks: Apprentice (max 75) -> Journeyman (150) -> Expert (225) -> Artisan (300)
-- Learnable at skill 50 / 125 / 200 and character level 10 / 20 / 35.
-- Place: { npc, town, zone, x, y, map = fallback uiMapID (Classic map numbers) }
-- Source: Warcraft Tavern's WoW Forever profession trainer list.

local MAPS = {
	["Darnassus"] = 1457, ["Undercity"] = 1458, ["Ironforge"] = 1455, ["Orgrimmar"] = 1454,
	["Stormwind City"] = 1453, ["Thunder Bluff"] = 1456, ["Elwynn Forest"] = 1429,
	["Stonetalon Mountains"] = 1442, ["Ashenvale"] = 1440, ["Desolace"] = 1443,
	["Arathi Highlands"] = 1417, ["Dustwallow Marsh"] = 1445, ["Feralas"] = 1444,
	["Swamp of Sorrows"] = 1435, ["Stranglethorn Vale"] = 1434, ["Tanaris"] = 1446,
	["The Hinterlands"] = 1425, ["Hillsbrad Foothills"] = 1424, ["Badlands"] = 1418,
}
Calc.TRAIN_MAPS = MAPS

local function P(npc, town, zone, x, y) return { npc = npc, town = town, zone = zone, x = x, y = y } end

local TRAINING = {
	["Alchemy"] = {
		Expert = { Alliance = P("Ainethil", "Craftsmen's Terrace", "Darnassus", 55.5, 23.1), Horde = P("Doctor Herbert Halsey", "The Apothecarium", "Undercity", 48.3, 72.3) },
		Artisan = { Alliance = P("Kylanna Windwhisper", "Feathermoon Stronghold", "Feralas", 32.6, 43.7), Horde = P("Rogvar", "Stonard", "Swamp of Sorrows", 48.3, 55.5) },
	},
	["Blacksmithing"] = {
		Expert = { Alliance = P("Bengus Deepforge", "The Great Forge", "Ironforge", 51.6, 42.4), Horde = P("Saru Steelfury", "Valley of Honor", "Orgrimmar", 82.4, 23.5) },
		Artisan = { Both = P("Brikk Keencraft", "Booty Bay", "Stranglethorn Vale", 29.0, 75.5) },
	},
	["Enchanting"] = {
		Expert = { Alliance = P("Kitta Firewind", "Tower of Azora", "Elwynn Forest", 64.9, 70.7), Horde = P("Hgarth", "Sun Rock Retreat", "Stonetalon Mountains", 49.2, 57.2) },
		Artisan = { Both = { npc = "Annora", town = "inside the Uldaman dungeon, south of the Temple Hall", zone = "Badlands" } },
	},
	["Engineering"] = {
		Expert = { Alliance = P("Springspindle Fizzlegear", "Tinker Town", "Ironforge", 68.8, 45.2), Horde = P("Roxxik", "Valley of Honor", "Orgrimmar", 76.0, 25.0) },
		Artisan = { Both = P("Buzzek Bracketswing", "Gadgetzan", "Tanaris", 52.2, 27.6) },
	},
	["Leatherworking"] = {
		Expert = { Alliance = P("Telonis", "Craftsmen's Terrace", "Darnassus", 64.6, 21.5), Horde = P("Una", "Middle Rise", "Thunder Bluff", 41.7, 42.7) },
		Artisan = { Alliance = P("Drakk Stonehand", "Aerie Peak", "The Hinterlands", 13.4, 43.4), Horde = P("Hahrana Ironhide", "Camp Mojache", "Feralas", 74.4, 43.1) },
	},
	["Tailoring"] = {
		Expert = { Alliance = P("Georgio Bolero", "Mage Quarter", "Stormwind City", 53.3, 81.7), Horde = P("Josef Gregorian", "The Magic Quarter", "Undercity", 70.8, 30.6) },
		Artisan = { Alliance = P("Timothy Worthington", "Theramore Isle", "Dustwallow Marsh", 66.2, 51.6), Horde = P("Daryl Stack", "Tarren Mill", "Hillsbrad Foothills", 63.6, 20.8) },
	},
	["Cooking"] = {
		Expert = { book = "Expert Cookbook", Alliance = P("Shandrina", "Silverwind Refuge", "Ashenvale", 49.5, 67.0), Horde = P("Wulan", "Shadowprey Village", "Desolace", 26.1, 69.7) },
		Artisan = { quest = "Clamlette Surprise", skill = 225, Both = P("Dirge Quikcleave", "Gadgetzan", "Tanaris", 52.6, 27.9) },
	},
	["First Aid"] = {
		Expert = { book = "Expert First Aid - Under Wraps", Alliance = P("Deneb Walker", "Stromgarde Keep", "Arathi Highlands", 27.0, 58.8), Horde = P("Balai Lok'Wein", "Brackenwall Village", "Dustwallow Marsh", 36.5, 30.5) },
		Artisan = { quest = "Triage", skill = 225, Alliance = P("Doctor Gustaf VanHowzen", "Theramore Isle", "Dustwallow Marsh", 67.5, 48.8), Horde = P("Doctor Gregory Victor", "Hammerfall", "Arathi Highlands", 73.5, 36.9) },
	},
}

local RANKS = {
	[75]  = { name = "Journeyman", cap = 150, skill = 50,  level = 10 },
	[150] = { name = "Expert",     cap = 225, skill = 125, level = 20 },
	[225] = { name = "Artisan",    cap = 300, skill = 200, level = 35 },
}

-- What to do next for this profession, or nil when there's nothing to learn yet.
-- Returns { rank, cap, skillNeeded, levelNeeded, canLearn, tooLowLevel, capped, text, place, book, quest }
function Calc:GetTrainingAdvice(profName, skill, maxSkill)
	if not (profName and skill and maxSkill) then return nil end
	if self:IsGathering(profName) then return nil end
	local r = RANKS[maxSkill]
	if not r then return nil end
	local info = TRAINING[profName] and TRAINING[profName][r.name]
	local needSkill = (info and info.skill) or r.skill
	if skill < needSkill then return nil end

	local level = UnitLevel and UnitLevel("player") or 60
	local faction = UnitFactionGroup and UnitFactionGroup("player") or "Alliance"
	local place = info and (info[faction] or info.Both)
	local a = {
		rank = r.name, cap = r.cap, skillNeeded = needSkill, levelNeeded = r.level,
		tooLowLevel = level < r.level, capped = skill >= maxSkill, place = place,
		book = info and info.book, quest = info and info.quest,
	}
	a.canLearn = not a.tooLowLevel

	local what = string.format("%s %s (skill up to %d)", r.name, profName, r.cap)
	local where
	if place then
		local at = place.town and (place.town .. ", " .. place.zone) or place.zone
		if a.book then
			where = string.format("buy and read the %s from %s (%s)", a.book, place.npc, at)
		elseif a.quest then
			where = string.format("do the quest %s from %s (%s)", a.quest, place.npc, at)
		else
			where = string.format("trainer %s, %s", place.npc, at)
		end
	else
		where = "any " .. profName .. " trainer (every capital city has one)"
	end
	if a.tooLowLevel then
		a.text = string.format("At level %d you can learn %s: %s.", r.level, what, where)
	else
		a.text = string.format("Learn %s: %s.", what, where)
	end
	return a
end

local function IsDifficultySelected(diffKey)
	local s = CSU.settings
	if diffKey == "optimal" then return s.showOptimal end
	if diffKey == "medium" then return s.showMedium end
	if diffKey == "easy" then return s.showEasy end
	return false
end

---------------------------------------------------------------------------
-- Makeable mats: a mat one of your own recipes makes (Bolt of Silk Cloth from Silk Cloth,
-- Cured Medium Hide, Bronze Tube, smelted bars from Mining...). You choose Buy or Make per mat;
-- until you choose, the cheaper way is used.
---------------------------------------------------------------------------
local MAKE_DEPTH = 3
-- skill points a craft of this colour gives, roughly (for bolts etc. made on the way)
local DIFF_POINTS = { optimal = 1, medium = 1, easy = 0.25, trivial = 0 }
Calc.DIFF_POINTS = DIFF_POINTS

local makersCache
function Calc:InvalidateMakers() makersCache = nil end

-- itemID -> { rec = recipe that makes it, prof = profession name }, from every profession you've opened
function Calc:GetMakers()
	if makersCache then return makersCache end
	local m = {}
	local charDB = CSU:GetCharDB()
	for pname, data in pairs(charDB.professions or {}) do
		if type(data) == "table" and type(data.recipes) == "table" then
			for _, rec in pairs(data.recipes) do
				if rec.outputItemID and rec.slots and #rec.slots > 0 then
					local cur = m[rec.outputItemID]
					-- several recipes make the same thing: keep the one needing the fewest mat kinds
					if not cur or #rec.slots < #cur.rec.slots then
						m[rec.outputItemID] = { rec = rec, prof = pname }
					end
				end
			end
		end
	end
	makersCache = m
	return m
end

function Calc:GetMatChoice(itemID)
	local c = CSU.settings and CSU.settings.matChoice
	return c and c[itemID]
end

function Calc:SetMatChoice(itemID, choice)
	CSU.settings.matChoice = CSU.settings.matChoice or {}
	CSU.settings.matChoice[itemID] = choice
	CSU:Fire("MAT_CHOICE_CHANGED", itemID)
end

-- Cost of one of this mat the way you get it (buy or make). Returns unit, how, info
-- info = { buy, make, source, listed, maker, subs = { {itemID, qty} }, outQty }
function Calc:MatCost(itemID, depth, visiting)
	depth = depth or 0
	local buy, source, listed = CSU.Prices:GetUnitCost(itemID)
	local maker = (depth < MAKE_DEPTH) and self:GetMakers()[itemID] or nil
	local make, subs, outQty
	if maker and not (visiting and visiting[itemID]) then
		visiting = visiting or {}
		visiting[itemID] = true
		local rec = maker.rec
		outQty = (rec.outputQty and rec.outputQty > 0) and rec.outputQty or 1
		local total, ok = 0, true
		subs = {}
		for _, slot in ipairs(rec.slots) do
			local bestID, bestU
			for _, sid in ipairs(slot.items) do
				local u = self:MatCost(sid, depth + 1, visiting)
				if u and (not bestU or u < bestU) then bestID, bestU = sid, u end
			end
			bestID = bestID or slot.items[1]
			table.insert(subs, { itemID = bestID, qty = slot.qty or 1 })
			if bestU then total = total + bestU * (slot.qty or 1) else ok = false end
		end
		visiting[itemID] = nil
		if ok then make = total / outQty end
	end
	local how = "buy"
	if subs then
		local choice = self:GetMatChoice(itemID)
		if choice == "make" then how = "make"
		elseif choice == "buy" then how = "buy"
		elseif make and (not buy or make < buy) then how = "make" end
	end
	local unit = (how == "make") and make or buy
	return unit, how, { buy = buy, make = make, source = source, listed = listed, maker = subs and maker or nil, subs = subs, outQty = outQty }
end

function Calc:EvaluateRecipe(rec, currentSkill)
	local totalCost = 0
	local buyCost = 0
	local missingPrices = 0
	local reagents = {}
	local subPoints = 0

	local bagMode = self:IsBagMode()
	local bags = bagMode and self:GetBagCounts() or nil
	local allowVendor = CSU.settings and CSU.settings.bagVendor ~= false
	local bagCrafts = math.huge
	local bagBlocked = false

	for _, slot in ipairs(rec.slots or {}) do
		local qty = slot.qty or 1
		local bestItemID = slot.items[1]
		local bestUnit, bestSource, bestListed, bestHow, bestInfo

		-- If a slot accepts multiple alternative reagents, pick the cheapest one (bought or made)
		for _, itemID in ipairs(slot.items) do
			local unit, how, info = self:MatCost(itemID)
			if unit and (not bestUnit or unit < bestUnit) then
				bestItemID = itemID
				bestUnit = unit
				bestSource = (how == "make") and "make" or info.source
				bestListed = info.listed
				bestHow, bestInfo = how, info
			end
		end
		if not bestInfo then
			local _, how, info = self:MatCost(bestItemID)
			bestHow, bestInfo = how, info
		end

		if bagMode then
			-- Use a ticked item from the bags (the one you have most of); else a vendor mat if allowed
			local pick, pickHave
			for _, itemID in ipairs(slot.items) do
				local h = bags[itemID] or 0
				if h > 0 and self:IsTicked(itemID) and (not pickHave or h > pickHave) then
					pick, pickHave = itemID, h
				end
			end
			if pick then
				bestItemID = pick
				bestUnit, bestSource, bestListed = CSU.Prices:GetUnitCost(pick)
				bestHow, bestInfo = "buy", { buy = bestUnit }
				-- Vendor mats (thread, salt...) don't limit the count when vendor mats are allowed: buy more
				if not (allowVendor and self:IsVendorMat(pick)) then
					bagCrafts = math.min(bagCrafts, math.floor(pickHave / qty))
				end
			else
				local vend
				if allowVendor then
					for _, itemID in ipairs(slot.items) do
						if self:IsVendorMat(itemID) then vend = itemID break end
					end
				end
				if vend then
					bestItemID = vend
					bestUnit, bestSource, bestListed = CSU.Prices:GetUnitCost(vend)
					bestHow, bestInfo = "buy", { buy = bestUnit }
				else
					bagBlocked = true
				end
			end
		end

		local have = bagMode and (bags[bestItemID] or 0) or CSU:GetOwnedCount(bestItemID)
		local need = math.max(0, qty - have)
		local lineTotal, buyTotal

		if bestUnit then
			lineTotal = bestUnit * qty
			buyTotal = bestUnit * need
			totalCost = totalCost + lineTotal
			buyCost = buyCost + buyTotal
		else
			missingPrices = missingPrices + 1
		end

		table.insert(reagents, {
			itemID = bestItemID,
			name = CSU:GetItemName(bestItemID),
			qty = qty,
			have = have,
			need = need,
			unitPrice = bestUnit,
			lineTotal = lineTotal,
			buyTotal = buyTotal,
			source = bestSource,
			listedQty = bestListed,
			-- makeable mats
			how = bestHow,
			makeable = (bestInfo and bestInfo.maker) and true or nil,
			buyUnit = bestInfo and bestInfo.buy,
			makeUnit = bestInfo and bestInfo.make,
			maker = bestInfo and bestInfo.maker,
			subs = bestInfo and bestInfo.subs,
			makeOutQty = bestInfo and bestInfo.outQty,
		})
		-- making it in the same profession gives skill points too
		if bestHow == "make" and bestInfo and bestInfo.maker and bestInfo.maker.prof == self.evalProf then
			local pts = DIFF_POINTS[bestInfo.maker.rec.difficulty] or 0
			subPoints = subPoints + pts * qty / (bestInfo.outQty or 1)
		end
	end

	local skillUps = (rec.numSkillUps and rec.numSkillUps > 0) and rec.numSkillUps or 1
	local points = skillUps + subPoints -- + points from making its mats (bolts...) yourself
	local complete = (missingPrices == 0)

	-- What the crafted item sells back for (best of vendor / AH after the 5% cut)
	local outQty = (rec.outputQty and rec.outputQty > 0) and rec.outputQty or 1
	local sellUnit, sellChannel, sellAH, sellVendor
	if rec.outputItemID and CSU.Prices.GetSellValue then
		sellUnit, sellChannel, sellAH, sellVendor = CSU.Prices:GetSellValue(rec.outputItemID)
	end
	local sellTotal = sellUnit and math.floor(sellUnit * outQty) or 0
	-- Mats From Bags ON: mats you already have count as free (cost = what you still need to buy)
	local fromBags = CSU.settings and CSU.settings.subtractBags
	local costBasis = fromBags and buyCost or totalCost
	local profit = complete and (sellTotal - costBasis) or nil

	local craftsToYellow, yellowSkill, estY = 0, nil, true
	local craftsToGreen, greenSkill, estG = 0, nil, true
	if CSU.Thresholds then
		craftsToYellow, yellowSkill, estY = CSU.Thresholds:EstimateCraftsUntil(
			rec.id, rec.name, currentSkill, rec.difficulty, skillUps, "yellow")
		craftsToGreen, greenSkill, estG = CSU.Thresholds:EstimateCraftsUntil(
			rec.id, rec.name, currentSkill, rec.difficulty, skillUps, "green")
	end

	return {
		recipeID = rec.id,
		name = rec.name,
		icon = rec.icon,
		difficulty = rec.difficulty,
		numSkillUps = skillUps,
		outputItemID = rec.outputItemID,
		complete = complete,
		missingPrices = missingPrices,
		totalCost = complete and totalCost or nil,
		buyCost = complete and buyCost or nil,
		costPerSkillUp = complete and (totalCost / points) or nil,
		buyCostPerSkillUp = complete and (buyCost / points) or nil,
		subPoints = subPoints > 0 and subPoints or nil,
		partialCost = totalCost,
		reagents = reagents,
		craftsToYellow = craftsToYellow,
		yellowSkill = yellowSkill,
		craftsToGreen = craftsToGreen,
		greenSkill = greenSkill,
		thresholdEstimated = estY or estG,
		outputQty = outQty,
		sellUnit = sellUnit,
		sellChannel = sellChannel,
		sellAH = sellAH,
		sellVendor = sellVendor,
		sellTotal = sellTotal,
		profit = profit,
		costBasis = complete and costBasis or nil,
		netCost = complete and (costBasis - sellTotal) or nil,
		netCostPerSkillUp = complete and ((costBasis - sellTotal) / points) or nil,
		bagCrafts = bagMode and (bagCrafts == math.huge and 0 or bagCrafts) or nil,
		bagOK = bagMode and (not bagBlocked) and bagCrafts ~= math.huge and bagCrafts >= 1 or nil,
	}
end

-- Returns sorted list of evaluated recipes + profession metadata
function Calc:GetRankedRecipes(profName, modeOverride)
	local saved = self:GetProfessionData(profName)
	if not saved then return {}, nil end

	-- The saved recipe colours are from the last time the profession window was open.
	-- If the skill has gone up since (e.g. First Aid levelled from bandages made in bulk),
	-- work the colours out again for the live skill instead of showing stale ones.
	local prof = saved
	local liveInfo = GetLiveProfessions()[saved.name]
	local liveSkill = liveInfo and liveInfo.skillLevel
	if liveSkill and saved.skillLevel and liveSkill ~= saved.skillLevel then
		prof = {}
		for k, v in pairs(saved) do prof[k] = v end
		prof.skillLevel = liveSkill
		prof.maxSkillLevel = (liveInfo.maxSkillLevel and liveInfo.maxSkillLevel > 0) and liveInfo.maxSkillLevel or saved.maxSkillLevel
		prof.stale = true
		prof.recipes = {}
		for id, rec in pairs(saved.recipes or {}) do
			local diff = CSU.Thresholds and CSU.Thresholds:DifficultyAt(rec.id or id, rec.name, liveSkill)
			local copy = {}
			for k, v in pairs(rec) do copy[k] = v end
			if diff then copy.difficulty = diff end
			prof.recipes[id] = copy
		end
	end

	local mode = modeOverride or self:GetMode()
	local list = {}
	self.evalProf = saved.name
	for _, rec in pairs(prof.recipes or {}) do
		local include
		if mode == "profit" or mode == "normal" then
			include = true -- any colour, grey included
		else
			include = IsDifficultySelected(rec.difficulty) and not rec.noSkillUp
		end
		-- Hide crafted gear below the chosen required level (items with no level are kept)
		local minLvl = tonumber(CSU.settings and CSU.settings.minLevel) or 0
		if include and minLvl > 0 and rec.outputItemID then
			local req = self:GetRequiredLevel(rec.outputItemID)
			if req and req > 1 and req < minLvl then include = false end
		end
		if include then
			local e = self:EvaluateRecipe(rec, prof.skillLevel)
			if not self:IsBagMode() or e.bagOK then
				table.insert(list, e)
			end
		end
	end

	local useBags = CSU.settings and CSU.settings.subtractBags

	local function key(e)
		if mode == "profit" then
			return -(e.profit or 0) -- highest profit first
		elseif mode == "earnback" then
			return e.netCostPerSkillUp -- lowest cost after selling first (negative = you earn)
		end
		return useBags and e.buyCostPerSkillUp or e.costPerSkillUp
	end

	if mode == "normal" then
		table.sort(list, function(a, b)
			local _, _, rankA = self:GetDifficultyMeta(a.difficulty)
			local _, _, rankB = self:GetDifficultyMeta(b.difficulty)
			if rankA ~= rankB then return rankA < rankB end
			local ilvlA, reqA = self:GetItemLevels(a.outputItemID)
			local ilvlB, reqB = self:GetItemLevels(b.outputItemID)
			if ilvlA ~= ilvlB then return ilvlA > ilvlB end
			if reqA ~= reqB then return reqA > reqB end
			local skA, skB = a.yellowSkill or 0, b.yellowSkill or 0
			if skA ~= skB then return skA > skB end
			return (a.name or "") < (b.name or "")
		end)
		return list, prof
	end

	table.sort(list, function(a, b)
		-- Complete pricing always ranks ahead of missing prices
		if a.complete ~= b.complete then
			return a.complete
		end
		if a.complete and b.complete then
			local costA, costB = key(a), key(b)
			if costA ~= costB then
				return costA < costB
			end
		end
		-- Tie-breaker: prefer guaranteed skill-up (optimal > medium > easy)
		local _, _, rankA = self:GetDifficultyMeta(a.difficulty)
		local _, _, rankB = self:GetDifficultyMeta(b.difficulty)
		if rankA ~= rankB then
			return rankA < rankB
		end
		return (a.name or "") < (b.name or "")
	end)

	return list, prof
end

function Calc:PrintBestToChat()
	if self:GetMode() == "normal" then
		CSU:Print("Normal mode has no ranking. Switch to Cheapest, Level + Earn or Best Profit for /csu best.")
		return
	end
	local list, prof = self:GetRankedRecipes()
	if not prof then
		CSU:Print("No profession scanned yet. Open any profession window first!")
		return
	end
	if #list == 0 then
		CSU:Print("%s: no recipes match your selected skill-up filter.", prof.name)
		return
	end
	local best = list[1]
	local label, hex = self:GetDifficultyMeta(best.difficulty)
	if not best.complete then
		CSU:Print("%s: cheapest candidate is %s (%s), but some reagent prices are missing. Run an AH scan first!",
			prof.name, CSU:Color(hex, best.name), label)
		return
	end
	local mode = self:GetMode()
	local sellTxt = best.sellUnit and string.format("%s (%s)", CSU:FormatMoney(best.sellTotal), best.sellChannel == "ah" and "AH" or "vendor") or "nothing"
	if mode == "profit" then
		CSU:Print("Best %s profit: %s [%s] — Mats: %s, sells for %s, profit %s per craft",
			prof.name, CSU:Color(hex, best.name), CSU:Color(hex, label),
			CSU:FormatMoney(best.totalCost), sellTxt, CSU:FormatMoney(best.profit))
	elseif mode == "earnback" then
		local n = best.netCostPerSkillUp
		local netTxt = (n <= 0) and ("you earn " .. CSU:FormatMoney(-n)) or ("costs " .. CSU:FormatMoney(n))
		CSU:Print("Best %s skill-up with earn-back: %s [%s] — Mats: %s, sells for %s, %s per skill-up",
			prof.name, CSU:Color(hex, best.name), CSU:Color(hex, label),
			CSU:FormatMoney(best.totalCost), sellTxt, netTxt)
	else
		CSU:Print("Cheapest %s skill-up: %s [%s] — Cost: %s (To buy: %s)",
			prof.name,
			CSU:Color(hex, best.name),
			CSU:Color(hex, label),
			CSU:FormatMoney(best.totalCost),
			CSU:FormatMoney(best.buyCost))
	end
	for _, r in ipairs(best.reagents) do
		local srcTag = r.source == "vendor" and " (Vendor)" or ""
		CSU:Print("  - %dx %s: %s (have %d, buy %d)%s",
			r.qty, r.name, CSU:FormatMoney(r.lineTotal), r.have, r.need, srcTag)
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local scanPending = false
local function ScheduleProfessionScan()
	if scanPending then return end
	scanPending = true
	C_Timer.After(0.15, function()
		scanPending = false
		Calc:ScanOpenProfession()
	end)
end

function Calc:Init()
	self:PurgeGathering()
	CSU:RegisterEvent("TRADE_SKILL_SHOW", ScheduleProfessionScan)
	CSU:RegisterEvent("TRADE_SKILL_LIST_UPDATE", ScheduleProfessionScan)
	CSU:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED", ScheduleProfessionScan)
	CSU:RegisterEvent("SKILL_LINES_CHANGED", function()
		if IsPlayerOwnTradeSkill() then ScheduleProfessionScan() end
	end)
	CSU:RegisterEvent("BAG_UPDATE_DELAYED", function()
		Calc._bagCache = nil
		CSU:Fire("BAGS_UPDATED")
	end)
end
