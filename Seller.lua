-- Sell crafted: remembers what you craft and puts a "Sell crafted" button on the Auction House.
-- Each click does one step for the next item: check its price, then post it (1 silver under the
-- cheapest other seller). Mats you make for other recipes (bolts, bars...) are left alone, and so
-- is anything that sells for more at a vendor.
local CSU = CheapSkillUp
local S = {}
CSU.Seller = S

S.FRESH = 90 -- seconds a price check stays good

local function Now() return GetTime and GetTime() or 0 end

local function Crafted()
	local char = CSU:GetCharDB()
	char.crafted = char.crafted or {}
	return char.crafted
end

-- every craftable thing the character knows, by spell / recipe id; and the items that are mats
local function Index()
	local byRecipe, mats = {}, {}
	local char = CSU:GetCharDB()
	for _, prof in pairs(char.professions or {}) do
		for key, rec in pairs(prof.recipes or {}) do
			local id = rec.recipeID or key
			if id then byRecipe[id] = rec end
			for _, slot in ipairs(rec.slots or {}) do
				for _, itemID in ipairs(slot.items or {}) do mats[itemID] = true end
			end
		end
	end
	return byRecipe, mats
end

-- a craft finished: remember what it made
CSU:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
	if unit ~= "player" or not spellID then return end
	local byRecipe = Index()
	local rec = byRecipe[spellID]
	if not (rec and rec.outputItemID) then return end
	local c = Crafted()
	local n = math.max(1, math.floor((rec.outputQty or 1) + 0.5))
	c[rec.outputItemID] = (c[rec.outputItemID] or 0) + n
	if S.button then S:Update() end
end)

-- what's gone from your bags is no longer "to sell" (tidied when you open the AH,
-- not while crafting, when the new item may not be in the bags yet)
local function Tidy()
	if not CSU.db then return end
	local c = Crafted()
	for itemID, n in pairs(c) do
		local have = CSU:GetBagCount(itemID)
		if have <= 0 then c[itemID] = nil elseif have < n then c[itemID] = have end
	end
end
CSU:RegisterEvent("BAG_UPDATE_DELAYED", function()
	if S.button and CSU.Prices and CSU.Prices.ahOpen then S:Update() end
end)

-- first bag slot holding this item, as an ItemLocation (and whether it's bound)
local function FindInBags(itemID)
	local C = C_Container
	if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo) then return nil end
	for bag = 0, (NUM_BAG_SLOTS or 4) do
		local okN, n = pcall(C.GetContainerNumSlots, bag)
		for slot = 1, (okN and type(n) == "number") and n or 0 do
			local ok, info = pcall(C.GetContainerItemInfo, bag, slot)
			if ok and type(info) == "table" and info.itemID == itemID then
				local loc = ItemLocation and ItemLocation.CreateFromBagAndSlot and ItemLocation:CreateFromBagAndSlot(bag, slot)
				return loc, info.isBound
			end
		end
	end
	return nil
end

-- What's ready to sell: { itemID, count, name }
function S:List()
	local out = {}
	if not CSU.db then return out end
	local _, mats = Index()
	S.skip = S.skip or {}
	for itemID, n in pairs(Crafted()) do
		local have = math.min(n, CSU:GetBagCount(itemID))
		if have > 0 and not mats[itemID] and not S.skip[itemID] then
			table.insert(out, { itemID = itemID, count = have, name = CSU:GetItemName(itemID) })
		end
	end
	table.sort(out, function(a, b) return (a.name or "") < (b.name or "") end)
	return out
end

-- Price to post at (per item, whole silver), or nil + why not
function S:PriceFor(itemID)
	local Buyer = CSU.Buyer
	local sc = Buyer and Buyer.scans and Buyer.scans[itemID]
	if not (sc and sc.at and (Now() - sc.at) < S.FRESH) then return nil, "scan" end
	local lowest = sc.listings and sc.listings[1] and sc.listings[1].unit
	local price
	if lowest then
		price = math.floor((lowest - 1) / 100) * 100 -- 1 silver under the cheapest
	else
		price = CSU.Prices:GetAHPrice(itemID)
		if not price then
			local _, _, _, _, vendor = CSU:GetItemInfoSafe(itemID)
			price = (vendor or 0) * 3
		end
		price = math.floor(price / 100) * 100
	end
	price = math.max(100, price)
	local _, _, _, _, vendor = CSU:GetItemInfoSafe(itemID)
	if vendor and vendor > 0 and price * (1 - (CSU.Prices.AH_CUT or 0.05)) <= vendor then
		return nil, "vendor", price
	end
	return price
end

local DURATION = { [2] = 1, [8] = 2, [24] = 3 }

-- one step for the next item: check its price, or post it
function S:Click()
	local A = C_AuctionHouse
	if not (A and CSU.Prices and CSU.Prices.ahOpen) then return end
	if self.posting and (Now() - self.posting.at) < 10 then return end
	if A.IsThrottledMessageSystemReady and not A.IsThrottledMessageSystemReady() then
		CSU:ShowError("The Auction House is busy. Click again in a second.")
		return
	end
	local list = self:List()
	local it = list[1]
	if not it then
		CSU:Print("Nothing crafted to sell. Items you craft show up here (mats like bolts and bars are left alone).")
		return
	end
	local price, why = self:PriceFor(it.itemID)
	if why == "scan" then
		CSU.Buyer:Scan(it.itemID)
		self.checking = it.itemID
		self:Update()
		return
	end
	if why == "vendor" then
		S.skip[it.itemID] = true
		CSU:Print("%s sells for more at a vendor than on the AH. Skipped: sell it to a vendor.", it.name or "?")
		self:Update()
		return
	end
	local loc, bound = FindInBags(it.itemID)
	if not loc then
		S.skip[it.itemID] = true
		self:Update()
		return
	end
	if bound or (C_Item and C_Item.IsBound and select(2, pcall(C_Item.IsBound, loc)) == true) then
		S.skip[it.itemID] = true
		CSU:Print("%s is soulbound and can't go on the AH. Skipped.", it.name or "?")
		self:Update()
		return
	end
	local dur = DURATION[CSU.Prices:GetAHHours()] or 2
	local commodity = false
	if A.GetItemCommodityStatus and Enum and Enum.ItemCommodityStatus then
		local ok, st = pcall(A.GetItemCommodityStatus, loc)
		commodity = ok and st == Enum.ItemCommodityStatus.Commodity
	end
	local ok, err
	if commodity then
		ok, err = pcall(A.PostCommodity, loc, dur, it.count, price)
	else
		ok, err = pcall(A.PostItem, loc, dur, it.count, nil, price)
		if not ok and it.count > 1 then
			it.count = 1
			ok, err = pcall(A.PostItem, loc, dur, 1, nil, price)
		end
	end
	if not ok then
		CSU:ShowError("Couldn't post %s (%s).", it.name or "?", tostring(err))
		return
	end
	self.posting = { itemID = it.itemID, count = it.count, price = price, at = Now() }
	CSU:Print("Posting %dx %s at %s each.", it.count, it.name or "?", CSU:FormatMoney(price))
	self:Update()
end

local function Posted()
	local p = S.posting
	if not p then return end
	S.posting = nil
	local c = Crafted()
	if c[p.itemID] then
		c[p.itemID] = c[p.itemID] - p.count
		if c[p.itemID] <= 0 then c[p.itemID] = nil end
	end
	if CSU.Buyer and CSU.Buyer.ClearScan then CSU.Buyer:ClearScan(p.itemID) end
	S:Update()
end
CSU:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED", Posted)
CSU:RegisterEvent("AUCTION_MULTISELL_COMPLETE", Posted)

---------------------------------------------------------------------------
-- The button on the Auction House
---------------------------------------------------------------------------
function S:Update()
	local b = self.button
	if not b then return end
	local list = self:List()
	local it = list[1]
	if not it then
		b.status = nil
		b:SetText("")
		b:SetEnabledLook(false)
		return
	end
	b:SetEnabledLook(true)
	local price, why = self:PriceFor(it.itemID)
	if self.posting then
		b.status = "Posting..."
		b:SetText("...")
	elseif why == "scan" then
		b.status = self.checking == it.itemID and ("Checking the price of " .. (it.name or "?") .. "...")
			or ("Next click: check the price of " .. (it.name or "?"))
		b:SetText(self.checking == it.itemID and "..." or tostring(#list))
	elseif price then
		b.status = string.format("Next click: post %dx %s at %s each", it.count, it.name or "?", CSU:FormatMoney(price))
		b:SetText(tostring(#list))
	else
		b.status = nil
		b:SetText(tostring(#list))
	end
	if GameTooltip.IsOwned and GameTooltip:IsOwned(b) and b:GetScript("OnEnter") then b:GetScript("OnEnter")(b) end
end

local function Place()
	if CSU.Prices and CSU.Prices.PlaceScanButton then CSU.Prices:PlaceScanButton() end
end

local function Create()
	if S.button or not _G.AuctionHouseFrame then return end
	if not (CSU.Prices and CSU.Prices.MakeAHIcon) then return end
	local b = CSU.Prices.MakeAHIcon("SkillUpProfitSellButton", "Interface\\Icons\\INV_Misc_Coin_02")
	b:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" or (IsShiftKeyDown and IsShiftKeyDown()) then
			local it = S:List()[1]
			if it then
				S.skip[it.itemID] = true
				CSU:Print("Skipped %s for now.", it.name or "?")
				S:Update()
			end
			return
		end
		S:Click()
	end)
	if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Sell what you crafted", 1, 0.82, 0)
		if self.status then GameTooltip:AddLine(self.status, 0.4, 0.85, 0.4, true) end
		local list = S:List()
		if #list == 0 then
			GameTooltip:AddLine("Nothing to sell yet. What you craft shows up here.", 1, 1, 1, true)
		end
		for i, it in ipairs(list) do
			if i > 12 then GameTooltip:AddLine("...", 0.7, 0.7, 0.7) break end
			local price, why = S:PriceFor(it.itemID)
			local right = price and CSU:FormatMoney(price) .. " each"
				or (why == "vendor" and "better at a vendor" or "click to check price")
			GameTooltip:AddDoubleLine(string.format("%dx %s", it.count, it.name or "?"), right, 1, 1, 1, 0.7, 0.7, 0.7)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Each click does one step: check the price, then post 1 silver under the cheapest other seller.", 0.7, 0.7, 0.7, true)
		GameTooltip:AddLine("Right-click (or Shift-click) skips the item. Mats you make for other recipes are left alone.", 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
	end)
	S.button = b
	Place()
	S:Update()
end

CSU:On("BUYER_STATE_CHANGED", function() if S.button then S:Update() end end)
CSU:RegisterEvent("AUCTION_HOUSE_SHOW", function()
	S.skip = {}
	S.posting, S.checking = nil, nil
	Tidy()
	Create()
	Place()
	if C_Timer and C_Timer.After then C_Timer.After(0.2, function() Place() S:Update() end) end
	S:Update()
end)
CSU:RegisterEvent("ADDON_LOADED", function(_, name)
	if name == "Blizzard_AuctionHouseUI" then Create() end
end)
