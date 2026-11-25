-- SkillUp & Profit :: Queue
-- Craft queue: recipes and how many, the materials they need all together, what you have
-- in your bags, bank and mailbox, and what's left to buy. At the bank it can move the
-- missing mats into your bags. Crafting counts the queue down by itself.

local _, CSU = ...
local Q = {}
CSU.Queue = Q

Q.bankOpen = false

-- "list": the queue itself changed; "bank": only what we know about the bank changed
local function Fire(kind) CSU:Fire("QUEUE_CHANGED", kind or "list") end

---------------------------------------------------------------------------
-- The queue (saved per character)
---------------------------------------------------------------------------
function Q:List()
	local char = CSU:GetCharDB()
	char.queue = char.queue or {}
	return char.queue
end

function Q:Count()
	local n = 0
	for _, it in ipairs(self:List()) do n = n + (it.count or 0) end
	return n
end

-- How many of this item the queue will make, and how many the queue needs
function Q:Produced(itemID)
	local n = 0
	for _, it in ipairs(self:List()) do
		if it.outputItemID == itemID then n = n + (it.count or 0) * (it.outputQty or 1) end
	end
	return n
end

function Q:Needed(itemID)
	local n = 0
	for _, it in ipairs(self:List()) do
		for _, r in ipairs(it.reagents or {}) do
			if r.itemID == itemID then n = n + (r.qty or 1) * (it.count or 0) end
		end
	end
	return n
end

local function FindIndex(list, recipeID)
	for i, it in ipairs(list) do
		if it.recipeID == recipeID then return i end
	end
end

-- entry: a recipe from the calculator (has recipeID, name, reagents)
-- Mats you make yourself (bolts, cured hides, bars...) are queued in front of it.
function Q:Add(entry, count, prof)
	if not (entry and entry.recipeID) then return false end
	count = math.max(1, math.floor(tonumber(count) or 1))
	local list = self:List()

	-- what you make yourself for it: how many more of those to make
	local preps = {}
	for _, r in ipairs(entry.reagents or {}) do
		if r.how == "make" and r.maker and r.subs then
			local need = (r.qty or 1) * count
			local spare = CSU:GetOwnedCount(r.itemID) + self:Produced(r.itemID) - self:Needed(r.itemID)
			local toMake = need - math.max(0, spare)
			if toMake > 0 then
				local rec = r.maker.rec
				local outQ = (rec.outputQty and rec.outputQty > 0) and rec.outputQty or 1
				local subR = {}
				for _, sub in ipairs(r.subs) do
					table.insert(subR, { itemID = sub.itemID, name = CSU:GetItemName(sub.itemID), qty = sub.qty,
						vendor = CSU.Calc:IsVendorMat(sub.itemID) or nil })
				end
				table.insert(preps, {
					recipeID = rec.id, name = rec.name, icon = rec.icon, outputItemID = rec.outputItemID,
					outputQty = outQ, prof = r.maker.prof, count = math.ceil(toMake / outQ), reagents = subR, prep = true,
				})
			end
		end
	end

	local pos = FindIndex(list, entry.recipeID)
	for _, p in ipairs(preps) do
		local i = FindIndex(list, p.recipeID)
		if i then
			list[i].count = list[i].count + p.count
		elseif pos then
			table.insert(list, pos, p)
			pos = pos + 1
		else
			table.insert(list, p)
		end
	end

	if pos then
		list[pos].count = list[pos].count + count
	else
		local reagents = {}
		for _, r in ipairs(entry.reagents or {}) do
			table.insert(reagents, { itemID = r.itemID, name = r.name, qty = r.qty, vendor = (r.source == "vendor") or nil })
		end
		table.insert(list, {
			recipeID = entry.recipeID,
			name = entry.name,
			icon = entry.icon,
			outputItemID = entry.outputItemID,
			outputQty = entry.outputQty,
			prof = prof,
			count = count,
			reagents = reagents,
		})
	end
	Fire()
	return true, #preps
end

function Q:SetCount(i, n)
	local list = self:List()
	local it = list[i]
	if not it then return end
	n = math.floor(tonumber(n) or 0)
	if n <= 0 then
		table.remove(list, i)
	else
		it.count = n
	end
	Fire()
end

function Q:Remove(i) self:SetCount(i, 0) end

function Q:Clear()
	local char = CSU:GetCharDB()
	char.queue = {}
	Fire()
end

-- All the materials the queue needs, added up, A to Z
function Q:Materials()
	local byID, out = {}, {}
	for _, it in ipairs(self:List()) do
		for _, r in ipairs(it.reagents or {}) do
			local m = byID[r.itemID]
			if not m then
				m = { itemID = r.itemID, name = r.name or CSU:GetItemName(r.itemID), need = 0, vendor = r.vendor }
				byID[r.itemID] = m
				table.insert(out, m)
			end
			m.need = m.need + (r.qty or 1) * (it.count or 1)
		end
	end
	for _, m in ipairs(out) do m.produced = self:Produced(m.itemID) end
	table.sort(out, function(a, b) return (a.name or "") < (b.name or "") end)
	return out
end

-- How many of this queued item the mats in your bags make right now
function Q:CanMakeFromBags(it)
	local n = math.huge
	for _, r in ipairs(it.reagents or {}) do
		n = math.min(n, math.floor(CSU:GetBagCount(r.itemID) / math.max(1, r.qty or 1)))
	end
	if n == math.huge then n = 0 end
	return n
end

-- Each finished craft counts the queue down (the recipe ID is the craft's spell ID)
local function OnCast(_, unit, _, spellID)
	if unit ~= "player" or not spellID then return end
	local list = Q:List()
	for i, it in ipairs(list) do
		if it.recipeID == spellID then
			it.count = (it.count or 1) - 1
			if it.count <= 0 then
				table.remove(list, i)
				CSU:Print("Queue: %s done.", it.name or "?")
			end
			Fire()
			return
		end
	end
end

---------------------------------------------------------------------------
-- Bank
---------------------------------------------------------------------------
-- Your own bags (never "bank"): backpack, 4 bags, and the reagent bag if this game has one
local IC = Constants and Constants.InventoryConstants
local REAGENT = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
if not (IC and (IC.NumReagentBagSlots or 0) > 0) then REAGENT = nil end
local IS_BAG = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true }
if REAGENT then IS_BAG[REAGENT] = true end

-- Bank containers (same as Rucksack Bags):
--  * WoW Forever keeps the bank in "bank tabs": the bank itself is the first tab (container 6),
--    each bank bag slot you bought is the next tab (7, 8 ... 14). Container -1 is the keyring there.
--  * Classic style: the bank is container -1 and its bag slots come right after your bags.
local function BankBags()
	local EB = Enum and Enum.BagIndex
	local tab1 = EB and EB.CharacterBankTab_1
	local main = BANK_CONTAINER or (EB and EB.Bank)
	local list, seen = {}, {}
	local function add(b)
		if type(b) == "number" and not seen[b] and not IS_BAG[b] then
			seen[b] = true
			table.insert(list, b)
		end
	end
	if tab1 and (not main or (C_Container and C_Container.GetContainerNumSlots and (C_Container.GetContainerNumSlots(main) or 0) == 0)) then
		for id = tab1, tab1 + 12 do add(id) end
		for i = 1, 16 do add(EB["CharacterBankTab_" .. i]) end
	else
		add(main or -1)
		local first = (NUM_BAG_SLOTS or 4) + 1 + (REAGENT and 1 or 0)
		for i = 0, math.max(NUM_BANKBAGSLOTS or 7, 7) - 1 do add(first + i) end
	end
	return list
end
Q.BankBags = BankBags

local function SlotInfo(bag, slot)
	if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
	local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
	if ok and type(info) == "table" then return info end
	return nil
end

local function NumSlots(bag)
	if not (C_Container and C_Container.GetContainerNumSlots) then return 0 end
	local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
	return (ok and tonumber(n)) or 0
end

-- Reads the whole bank (only works while the bank is open) and remembers it
function Q:ScanBank()
	if not self.bankOpen then return false end
	local counts, slots = {}, {}
	for _, bag in ipairs(BankBags()) do
		for slot = 1, NumSlots(bag) do
			local info = SlotInfo(bag, slot)
			if info and info.itemID then
				local c = info.stackCount or 1
				counts[info.itemID] = (counts[info.itemID] or 0) + c
				slots[info.itemID] = slots[info.itemID] or {}
				table.insert(slots[info.itemID], { bag = bag, slot = slot, count = c })
			end
		end
	end
	local char = CSU:GetCharDB()
	char.bank = counts
	char.bankAt = time and time() or 0
	self.bankSlots = slots
	return true
end

-- In the bank: live while it's open, else what we saw last time you were there
function CSU:GetBankCount(itemID)
	if not (itemID and self.db) then return 0 end
	local char = self:GetCharDB()
	if char.bankAt and char.bank then return char.bank[itemID] or 0 end
	-- never seen the bank: ask the game (works on clients that keep bank counts)
	if C_Item and C_Item.GetItemCount then
		local ok, withBank = pcall(C_Item.GetItemCount, itemID, true, false, false)
		if ok and type(withBank) == "number" then
			return math.max(0, withBank - self:GetBagCount(itemID))
		end
	end
	return 0
end

function CSU:HasSeenBank()
	local char = self.db and self:GetCharDB()
	return char and char.bankAt ~= nil
end

-- Bank items count as yours only when Count bank is on
function CSU:GetBankIncluded(itemID)
	if not (self.settings and self.settings.includeBank) then return 0 end
	return self:GetBankCount(itemID)
end

---------------------------------------------------------------------------
-- Take from bank: moves what the queue still misses into your bags
---------------------------------------------------------------------------
local BAG_FIRST, BAG_LAST = 0, (NUM_BAG_SLOTS or 4)

local function FreeBagSlot()
	for bag = BAG_FIRST, BAG_LAST do
		local n = NumSlots(bag)
		local okFree, free, bagType = pcall(C_Container.GetContainerNumFreeSlots, bag)
		if n > 0 and okFree and (free or 0) > 0 and (bagType == nil or bagType == 0) then
			for slot = 1, n do
				if not SlotInfo(bag, slot) then return bag, slot end
			end
		end
	end
end

local function FreeBagSlots()
	local total = 0
	for bag = BAG_FIRST, BAG_LAST do
		local ok, free, bagType = pcall(C_Container.GetContainerNumFreeSlots, bag)
		if ok and (bagType == nil or bagType == 0) then total = total + (free or 0) end
	end
	return total
end

-- What to move: per material, the part bags + mailbox don't cover, up to what the bank has
function Q:PlanBankMoves()
	local moves, summary = {}, {}
	if not self.bankSlots then return moves, summary end
	for _, m in ipairs(self:Materials()) do
		local missing = m.need - CSU:GetBagCount(m.itemID) - CSU:GetIncoming(m.itemID) - (m.produced or 0)
		local slots = self.bankSlots[m.itemID]
		if missing > 0 and slots then
			local inBank = 0
			for _, s in ipairs(slots) do inBank = inBank + s.count end
			local take = math.min(missing, inBank)
			if take > 0 then
				table.insert(summary, { name = m.name, qty = take })
				-- whole stacks first, biggest first; one split for the rest
				local sorted = {}
				for _, s in ipairs(slots) do table.insert(sorted, s) end
				table.sort(sorted, function(a, b) return a.count > b.count end)
				local left = take
				for _, s in ipairs(sorted) do
					if left <= 0 then break end
					if s.count <= left then
						table.insert(moves, { kind = "use", bag = s.bag, slot = s.slot, itemID = m.itemID, qty = s.count })
						left = left - s.count
						s.used = true
					end
				end
				if left > 0 then
					local src
					for i = #sorted, 1, -1 do
						local s = sorted[i]
						if not s.used and s.count > left then src = s break end
					end
					if src then
						table.insert(moves, { kind = "split", bag = src.bag, slot = src.slot, itemID = m.itemID, qty = left })
					end
				end
			end
		end
	end
	return moves, summary
end

-- Runs by itself at the bank (and again when the queue changes while you're there).
-- pass: 1st run, then one more to pick up anything that was busy (locked) the first time.
function Q:TakeFromBank(pass)
	pass = pass or 1
	if not self.bankOpen or self.moving then return end
	self:ScanBank()
	local moves, summary = self:PlanBankMoves()
	if #moves == 0 then return end
	if FreeBagSlots() == 0 then
		CSU:Print("The bank has mats for your craft queue, but your bags are full. Make room and they'll be taken.")
		self.waitingForRoom = true
		return
	end
	self.waitingForRoom = false
	local parts = {}
	for _, s in ipairs(summary) do table.insert(parts, string.format("%dx %s", s.qty, s.name)) end
	CSU:Print("Craft queue: taking %s from the bank.", table.concat(parts, ", "))

	self.moving = true
	local i, waits = 1, 0
	local ticker
	local function finish(msg)
		if ticker and ticker.Cancel then ticker:Cancel() end
		Q.moving = false
		if ClearCursor then ClearCursor() end
		if msg then CSU:Print(msg) end
		Q:ScanBank()
		Fire("bank")
		-- one more go for anything that was busy, once the bags have settled
		if pass < 2 and Q.bankOpen and C_Timer and C_Timer.After then
			C_Timer.After(1, function() Q:TakeFromBank(pass + 1) end)
		end
	end
	local function step()
		if not Q.bankOpen then return finish("Bank closed, stopped taking items.") end
		local mv = moves[i]
		if not mv then return finish(pass == 1 and "Craft queue: done taking from the bank." or nil) end
		local info = SlotInfo(mv.bag, mv.slot)
		if not info or info.itemID ~= mv.itemID then
			i = i + 1 -- moved or changed meanwhile
			return
		end
		if info.isLocked or (CursorHasItem and CursorHasItem()) then
			waits = waits + 1
			if waits > 12 then
				if ClearCursor then ClearCursor() end
				i, waits = i + 1, 0
			end
			return
		end
		waits = 0
		if mv.kind == "use" then
			if FreeBagSlots() == 0 then return finish("Your bags are full, stopped taking items.") end
			pcall(C_Container.UseContainerItem, mv.bag, mv.slot)
		else
			local fb, fs = FreeBagSlot()
			if not fb then return finish("No empty bag slot for a part stack, stopped taking items.") end
			pcall(C_Container.SplitContainerItem, mv.bag, mv.slot, mv.qty)
			pcall(C_Container.PickupContainerItem, fb, fs)
		end
		i = i + 1
	end
	if C_Timer and C_Timer.NewTicker then
		ticker = C_Timer.NewTicker(0.3, step)
	else
		for _ = 1, #moves do step() end
		finish(nil)
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- At the bank: read it (the bank tabs load a moment after it opens), then take what the queue misses
local function AutoTake(delay)
	if not (C_Timer and C_Timer.After) then return Q:TakeFromBank() end
	Q.autoToken = (Q.autoToken or 0) + 1
	local my = Q.autoToken
	C_Timer.After(delay or 0.6, function()
		if my ~= Q.autoToken or not Q.bankOpen then return end
		Q:ScanBank()
		Fire("bank")
		if #Q:List() > 0 then Q:TakeFromBank() end
	end)
end

CSU:RegisterEvent("BANKFRAME_OPENED", function()
	Q.bankOpen = true
	Q:ScanBank()
	Fire("bank")
	AutoTake(0.6)
end)
-- queue changed while at the bank: take the new mats too
CSU:On("QUEUE_CHANGED", function(kind)
	if kind == "list" and Q.bankOpen and not Q.moving then AutoTake(0.3) end
end)
CSU:RegisterEvent("BANKFRAME_CLOSED", function()
	Q.bankOpen = false
	Fire("bank")
end)
CSU:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function()
	if Q.bankOpen and Q:ScanBank() then Fire("bank") end
end)
CSU:RegisterEvent("BAG_UPDATE_DELAYED", function()
	if Q.bankOpen and not Q.moving and Q:ScanBank() then
		Fire("bank")
		if Q.waitingForRoom then AutoTake(0.3) end -- you made room in your bags
	end
end)
Q.OnCast = OnCast
CSU:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", OnCast)
