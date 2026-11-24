-- CheapSkillUp :: Buyer
-- One-click material purchasing at the Auction House (C_AuctionHouse commodities + search fallback)
-- and at Vendors (BuyMerchantItem).

local _, CSU = ...
local Buyer = {}
CSU.Buyer = Buyer

Buyer.merchantOpen = false
Buyer.merchantIndexByItem = {} -- itemID -> { index, stack, maxStack }

-- Auction House state (see the "Scan AH -> Buy" section below)
Buyer.scans = {}       -- itemID -> { at, kind = "commodity" | "item", listings = { {unit, qty, auctionID, buyout} }, itemKey }
Buyer.scanning = {}    -- itemID -> { at, token }
Buyer.buying = nil     -- purchase in progress: { itemID, qty, expected, at, token, kind, confirm, auctionID }
Buyer.SCAN_TTL = 120   -- seconds a scan's prices are trusted
Buyer.TIMEOUT = 6      -- seconds to wait for the AH to answer
Buyer.PRICE_SLACK = 0.02 -- cancel if the real price is more than 2% above the scanned one

---------------------------------------------------------------------------
-- Merchant helpers
---------------------------------------------------------------------------

local function ScanMerchantInventory()
	wipe(Buyer.merchantIndexByItem)
	if not GetMerchantNumItems then return end
	local count = GetMerchantNumItems() or 0
	for i = 1, count do
		local link = GetMerchantItemLink and GetMerchantItemLink(i)
		local itemID = CSU:ItemIDFromLink(link)
		if itemID then
			local stack = 1
			if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
				local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
				if ok and info and info.stackCount and info.stackCount > 0 then
					stack = info.stackCount
				end
			elseif GetMerchantItemInfo then
				local _, _, _, q = GetMerchantItemInfo(i)
				if q and q > 0 then stack = q end
			end
			local maxStack = (GetMerchantItemMaxStack and GetMerchantItemMaxStack(i)) or 20
			Buyer.merchantIndexByItem[itemID] = {
				index = i,
				stack = stack,
				maxStack = maxStack,
			}
		end
	end
	CSU:Fire("BUYER_STATE_CHANGED")
end

function Buyer:CanBuyFromMerchant(itemID)
	return self.merchantOpen and self.merchantIndexByItem[itemID] ~= nil
end

function Buyer:BuyFromMerchant(itemID, qty)
	local info = self.merchantIndexByItem[itemID]
	if not (self.merchantOpen and info and BuyMerchantItem) then return false end
	qty = math.max(1, math.floor(tonumber(qty) or 1))
	-- Convert desired unit count to merchant purchase stacks
	local purchases = math.ceil(qty / (info.stack or 1))
	local maxPerCall = math.max(1, math.floor((info.maxStack or 20) / (info.stack or 1)))
	while purchases > 0 do
		local batch = math.min(purchases, maxPerCall)
		pcall(BuyMerchantItem, info.index, batch)
		purchases = purchases - batch
	end
	CSU:Print("Bought %dx %s from vendor.", qty, CSU:GetItemName(itemID))
	return true
end

---------------------------------------------------------------------------
-- Auction House search & commodity purchase
---------------------------------------------------------------------------

function Buyer:SearchOnAH(itemID)
	local ah = _G.AuctionHouseFrame
	if not (ah and ah:IsShown()) then
		CSU:Print("Open the Auction House first to search for items.")
		return false
	end
	local name = CSU:GetItemName(itemID)
	local bar = ah.SearchBar
	local box = bar and bar.SearchBox
	if not (name and box and type(box.SetText) == "function" and type(bar.StartSearch) == "function") then
		return false
	end
	local modes = _G.AuctionHouseFrameDisplayMode
	if modes and modes.Buy and ah.displayMode ~= modes.Buy and type(ah.SetDisplayMode) == "function" then
		pcall(ah.SetDisplayMode, ah, modes.Buy)
	end
	box:SetText(name)
	pcall(bar.StartSearch, bar)
	return true
end

---------------------------------------------------------------------------
-- Auction House: [Scan AH] -> [Buy N] (exact cost of the cheapest N) -> bought, or back to [Scan AH]
-- StartCommoditiesPurchase and PlaceBid only work from a real click, so they are only called
-- from ClickBuy. Searching and confirming have no such limit.
---------------------------------------------------------------------------

local token = 0
local function Now() return GetTime and GetTime() or 0 end
local function NewToken() token = token + 1 return token end

local function Fire() CSU:Fire("BUYER_STATE_CHANGED") end

function Buyer:ClearScan(itemID)
	if itemID then
		self.scans[itemID] = nil
		self.scanning[itemID] = nil
	end
end

-- Kept for the window: changing the craft count needs no new scan, the cost is worked out again.
function Buyer:ClearQuote()
	local b = self.buying
	if b and b.confirm then
		if b.kind == "commodity" and C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then
			pcall(C_AuctionHouse.CancelCommoditiesPurchase)
		end
		self.buying = nil
	end
end

-- Cost of buying `qty` from the last scan, cheapest listings first.
-- Returns total, unitsYouGet (nil when there's no fresh scan).
function Buyer:GetScanCost(itemID, qty)
	local sc = self.scans[itemID]
	if not sc or (Now() - sc.at) > self.SCAN_TTL then return nil end
	local left, total, got = qty, 0, 0
	for _, l in ipairs(sc.listings) do
		if left <= 0 then break end
		if sc.kind == "item" then
			-- a normal auction is bought whole
			total = total + l.buyout
			got = got + l.qty
			left = left - l.qty
		else
			local take = math.min(left, l.qty)
			total = total + l.unit * take
			got = got + take
			left = left - take
		end
	end
	return total, got
end

-- "scan" | "scanning" | "none" | "buy" (+ total, units) | "buying" | "confirm" (+ total)
function Buyer:GetState(itemID, qty)
	local b = self.buying
	if b and b.itemID == itemID then
		if b.confirm then return "confirm", b.total, b.qty end
		return "buying"
	end
	if self.scanning[itemID] then return "scanning" end
	local total, got = self:GetScanCost(itemID, qty)
	if not total then return "scan" end
	if got <= 0 then return "none" end
	return "buy", total, got
end

function Buyer:Scan(itemID)
	local A = C_AuctionHouse
	if not (A and A.SendSearchQuery and A.MakeItemKey) then return false end
	if A.IsThrottledMessageSystemReady and not A.IsThrottledMessageSystemReady() then
		CSU:Print("The Auction House is busy. Try again in a second.")
		return false
	end
	local my = NewToken()
	self.scans[itemID] = nil
	self.scanning[itemID] = { at = Now(), token = my }
	local okKey, key = pcall(A.MakeItemKey, itemID)
	local sortPrice = (Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price) or 0
	local ok = okKey and pcall(A.SendSearchQuery, key, { { sortOrder = sortPrice, reverseSort = false } }, true)
	if not ok then
		self.scanning[itemID] = nil
		Fire()
		return false
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(self.TIMEOUT, function()
			local sc = Buyer.scanning[itemID]
			if sc and sc.token == my then
				Buyer.scanning[itemID] = nil
				CSU:Print("No answer from the Auction House for %s. Click Scan AH again.", CSU:GetItemName(itemID))
				Fire()
			end
		end)
	end
	Fire()
	return true
end

local function StoreCommodityResults(itemID)
	local A = C_AuctionHouse
	local n = (A.GetNumCommoditySearchResults and A.GetNumCommoditySearchResults(itemID)) or 0
	local listings = {}
	for i = 1, n do
		local ok, r = pcall(A.GetCommoditySearchResultInfo, itemID, i)
		if ok and r and r.unitPrice and r.quantity then
			local q = r.quantity - (r.numOwnerItems or 0) -- your own auctions can't be bought
			if q > 0 then
				table.insert(listings, { unit = r.unitPrice, qty = q, auctionID = r.auctionID })
			end
		end
	end
	table.sort(listings, function(x, y) return x.unit < y.unit end)
	Buyer.scans[itemID] = { at = Now(), kind = "commodity", listings = listings }
	Buyer.scanning[itemID] = nil
	Fire()
end

local function StoreItemResults(itemKey)
	local A = C_AuctionHouse
	local itemID = itemKey and itemKey.itemID
	if not itemID then return end
	local n = (A.GetNumItemSearchResults and A.GetNumItemSearchResults(itemKey)) or 0
	local listings = {}
	for i = 1, n do
		local ok, r = pcall(A.GetItemSearchResultInfo, itemKey, i)
		if ok and r and r.buyoutAmount and r.buyoutAmount > 0 and not r.containsOwnerItem then
			local q = math.max(1, r.quantity or 1)
			table.insert(listings, { unit = r.buyoutAmount / q, qty = q, buyout = r.buyoutAmount, auctionID = r.auctionID })
		end
	end
	table.sort(listings, function(x, y) return x.unit < y.unit end)
	Buyer.scans[itemID] = { at = Now(), kind = "item", listings = listings, itemKey = itemKey }
	Buyer.scanning[itemID] = nil
	Fire()
end

local function PurchaseFailed(reason)
	local b = Buyer.buying
	if not b then return end
	Buyer.buying = nil
	Buyer:ClearScan(b.itemID)
	CSU:Print("%s Click Scan AH to get fresh prices.", reason or ("Couldn't buy " .. CSU:GetItemName(b.itemID) .. "."))
	Fire()
end

-- Starts the purchase of what the last scan priced. Must run from a click.
function Buyer:BuyScanned(itemID, qty)
	local sc = self.scans[itemID]
	local total, got = self:GetScanCost(itemID, qty)
	if not (sc and total and got > 0) then return self:Scan(itemID) end
	local A = C_AuctionHouse
	local my = NewToken()

	if sc.kind == "commodity" then
		local buyQty = math.min(qty, got)
		local expected = self:GetScanCost(itemID, buyQty)
		self.buying = { itemID = itemID, qty = buyQty, expected = expected, at = Now(), token = my, kind = "commodity" }
		local ok, err = pcall(A.StartCommoditiesPurchase, itemID, buyQty)
		if not ok then
			self.buying = nil
			CSU:Print("Couldn't start buying %s (%s).", CSU:GetItemName(itemID), tostring(err))
			Fire()
			return false
		end
	else
		-- normal auctions: one auction per click, cheapest first
		local l = sc.listings[1]
		self.buying = { itemID = itemID, qty = l.qty, expected = l.buyout, total = l.buyout, at = Now(), token = my, kind = "item", auctionID = l.auctionID }
		local ok, err = pcall(A.PlaceBid, l.auctionID, l.buyout)
		if not ok then
			self.buying = nil
			CSU:Print("Couldn't buy %s (%s).", CSU:GetItemName(itemID), tostring(err))
			Fire()
			return false
		end
		table.remove(sc.listings, 1)
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(self.TIMEOUT, function()
			local b = Buyer.buying
			if b and b.token == my and not b.confirm then
				if b.kind == "commodity" and A.CancelCommoditiesPurchase then pcall(A.CancelCommoditiesPurchase) end
				PurchaseFailed("No answer from the Auction House.")
			end
		end)
	end
	Fire()
	return true
end

-- Called from a button click.
-- Vendor open and sells it -> buys. AH open: Scan AH -> Buy N -> (Confirm N if the auto-confirm was refused).
function Buyer:ClickBuy(itemID, qty)
	qty = math.max(1, math.floor(tonumber(qty) or 1))

	if self:CanBuyFromMerchant(itemID) then
		return self:BuyFromMerchant(itemID, qty)
	end

	if not (CSU.Prices and CSU.Prices.ahOpen) then
		CSU:Print("Open the Auction House (or a Vendor for vendor mats) to buy %dx %s.", qty, CSU:GetItemName(itemID))
		return false
	end

	if CSU.Prices.running then
		CSU:Print("Wait for the Auction House scan to finish before buying.")
		return false
	end

	local b = self.buying
	if b and b.confirm and b.itemID == itemID then
		local ok, err = pcall(C_AuctionHouse.ConfirmCommoditiesPurchase, b.itemID, b.qty)
		if ok then
			b.confirm = nil
			b.at = Now()
		else
			PurchaseFailed("Purchase failed (" .. tostring(err) .. ").")
		end
		Fire()
		return ok
	end
	if b and (Now() - b.at) < self.TIMEOUT then
		return false -- still waiting for the last purchase
	end

	local state = self:GetState(itemID, qty)
	if state == "scan" or state == "none" then
		return self:Scan(itemID)
	elseif state == "buy" then
		return self:BuyScanned(itemID, qty)
	end
	return false
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

function Buyer:Init()
	CSU:RegisterEvent("MERCHANT_SHOW", function()
		Buyer.merchantOpen = true
		ScanMerchantInventory()
	end)

	CSU:RegisterEvent("MERCHANT_CLOSED", function()
		Buyer.merchantOpen = false
		wipe(Buyer.merchantIndexByItem)
		Fire()
	end)

	CSU:RegisterEvent("AUCTION_HOUSE_CLOSED", function()
		Buyer.buying = nil
		wipe(Buyer.scans)
		wipe(Buyer.scanning)
		Fire()
	end)

	-- Search results (ours, or from Blizzard's / Auctionator's search: prices are prices)
	CSU:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED", function(_, itemID)
		if itemID then StoreCommodityResults(itemID) end
	end)
	CSU:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED", function(_, itemKey)
		if type(itemKey) == "table" then StoreItemResults(itemKey) end
	end)

	-- The AH tells us the real price for the quantity: confirm if it's what the scan said
	CSU:RegisterEvent("COMMODITY_PRICE_UPDATED", function(_, unitPrice, totalPrice)
		local b = Buyer.buying
		if not (b and b.kind == "commodity") or b.confirm then return end
		b.total = totalPrice
		local limit = (b.expected or 0) * (1 + Buyer.PRICE_SLACK) + 1
		if b.expected and totalPrice > limit then
			if C_AuctionHouse.CancelCommoditiesPurchase then pcall(C_AuctionHouse.CancelCommoditiesPurchase) end
			PurchaseFailed(string.format("Someone bought the cheap %s first: %d now costs %s, not %s.",
				CSU:GetItemName(b.itemID), b.qty, CSU:FormatMoney(totalPrice), CSU:FormatMoney(b.expected)))
			return
		end
		local ok = pcall(C_AuctionHouse.ConfirmCommoditiesPurchase, b.itemID, b.qty)
		if ok then
			b.at = Now()
		else
			b.confirm = true -- needs one more click on "Confirm"
		end
		Fire()
	end)

	CSU:RegisterEvent("COMMODITY_PRICE_UNAVAILABLE", function()
		if Buyer.buying and Buyer.buying.kind == "commodity" then
			PurchaseFailed("Not enough " .. CSU:GetItemName(Buyer.buying.itemID) .. " left on the AH.")
		end
	end)

	CSU:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED", function()
		local b = Buyer.buying
		if b and b.kind == "commodity" then
			CSU:AddIncoming(b.itemID, b.qty)
			CSU:Print("Bought %dx %s for %s. It's in your mailbox and already counted as yours.", b.qty, CSU:GetItemName(b.itemID), CSU:FormatMoney(b.total or b.expected))
			Buyer.buying = nil
			Buyer:ClearScan(b.itemID) -- listings changed; you may need more later
			Fire()
		end
	end)

	CSU:RegisterEvent("COMMODITY_PURCHASE_FAILED", function()
		if Buyer.buying and Buyer.buying.kind == "commodity" then
			PurchaseFailed("Purchase of " .. CSU:GetItemName(Buyer.buying.itemID) .. " failed (someone may have bought them first).")
		end
	end)

	CSU:RegisterEvent("AUCTION_HOUSE_PURCHASE_COMPLETED", function(_, auctionID)
		local b = Buyer.buying
		if b and b.kind == "item" and b.auctionID == auctionID then
			CSU:AddIncoming(b.itemID, b.qty)
			CSU:Print("Bought %dx %s for %s. It's in your mailbox and already counted as yours.", b.qty, CSU:GetItemName(b.itemID), CSU:FormatMoney(b.total))
			Buyer.buying = nil
			Fire()
		end
	end)

	-- Bought mats on the way: they come off when they reach your bags; the mailbox shows what's left
	CSU:RegisterEvent("BAG_UPDATE_DELAYED", function()
		if CSU:UpdateIncomingFromBags() then Fire() end
	end)
	CSU:RegisterEvent("MAIL_SHOW", function() CSU.mailOpen = true end)
	CSU:RegisterEvent("MAIL_CLOSED", function()
		CSU.mailOpen = false
		CSU:UpdateIncomingFromBags() -- new baseline after taking the mail
	end)
	CSU:RegisterEvent("MAIL_INBOX_UPDATE", function()
		if CSU:UpdateIncomingFromMail() then Fire() end
	end)

	CSU:RegisterEvent("AUCTION_HOUSE_SHOW_ERROR", function()
		if Buyer.buying then
			PurchaseFailed("The Auction House refused the purchase (someone may have bought it first).")
		end
	end)
end
