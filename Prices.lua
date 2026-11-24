-- CheapSkillUp :: Prices
-- Built-in Auction House browse scanner (C_AuctionHouse) + Auctionator / CraftProfit / TSM fallbacks + vendor prices.

local _, CSU = ...
local Prices = {}
CSU.Prices = Prices

local scanFrame = CreateFrame("Frame")
local SCAN_EVENTS = {
	"AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
	"AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
	"AUCTION_HOUSE_THROTTLED_SYSTEM_READY",
}
local STALL_TIMEOUT = 20

Prices.ahOpen = false
Prices.running = false
Prices.pages = 0
Prices.waitingThrottle = false

---------------------------------------------------------------------------
-- Built-in vendor prices (unlimited-stock trade goods) + merchant learning
---------------------------------------------------------------------------

local VENDOR_SEED = {
	-- Thread
	[2320]  = 10,     -- Coarse Thread
	[2321]  = 100,    -- Fine Thread
	[4291]  = 500,    -- Silken Thread
	[8343]  = 2000,   -- Heavy Silken Thread
	[14341] = 5000,   -- Rune Thread
	-- Dyes & bleach
	[2324]  = 25,     -- Bleach
	[2604]  = 50,     -- Red Dye
	[6260]  = 50,     -- Blue Dye
	[2605]  = 100,    -- Green Dye
	[4340]  = 100,    -- Gray Dye
	[6261]  = 250,    -- Orange Dye
	[4341]  = 500,    -- Yellow Dye
	[4342]  = 2500,   -- Purple Dye
	-- Blacksmithing / Engineering
	[2880]  = 100,    -- Weak Flux
	[3466]  = 2000,   -- Strong Flux
	[3857]  = 500,    -- Coal
	[4470]  = 38,     -- Simple Wood
	-- Alchemy
	[3371]  = 4,      -- Empty Vial
	[3372]  = 200,    -- Leaded Vial
	[8925]  = 2000,   -- Crystal Vial
	-- Enchanting
	[6217]  = 124,    -- Copper Rod
	-- Cooking
	[2678]  = 10,     -- Mild Spices
	[2692]  = 20,     -- Hot Spices
	[3713]  = 40,     -- Soothing Spices
	[159]   = 25,     -- Refreshing Spring Water
	[1179]  = 125,    -- Ice Cold Milk
	-- Leatherworking
	[4289]  = 50,     -- Salt
}

function Prices:GetVendorPrice(itemID)
	if not itemID then return nil end
	local learned = CSU.db and CSU.db.vendor and CSU.db.vendor[itemID]
	if type(learned) == "number" and learned > 0 then
		return learned
	end
	return VENDOR_SEED[itemID]
end

local function LearnMerchantPrices()
	if not CSU.db or not GetMerchantNumItems then return end
	local count = GetMerchantNumItems() or 0
	local updated = 0
	for i = 1, count do
		local link = GetMerchantItemLink and GetMerchantItemLink(i)
		local itemID = CSU:ItemIDFromLink(link)
		if itemID then
			local price, stack, numAvailable, extended
			if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
				local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
				if ok and info then
					price = info.price
					stack = info.stackCount or info.quantity
					numAvailable = info.numAvailable
					extended = info.hasExtendedCost
				end
			elseif GetMerchantItemInfo then
				local _, _, p, q, na, _, _, ext = GetMerchantItemInfo(i)
				price, stack, numAvailable, extended = p, q, na, ext
			end
			if GetMerchantItemCostInfo then
				local costCount = GetMerchantItemCostInfo(i)
				if costCount and costCount > 0 then extended = true end
			end
			-- Unlimited stock only (numAvailable == -1 or nil)
			if price and price > 0 and not extended and (not numAvailable or numAvailable < 0) then
				stack = (stack and stack > 0) and stack or 1
				local unit = price / stack
				if CSU.db.vendor[itemID] ~= unit then
					CSU.db.vendor[itemID] = unit
					updated = updated + 1
				end
			end
		end
	end
	if updated > 0 then
		CSU:Fire("PRICES_UPDATED", "vendor")
	end
end

---------------------------------------------------------------------------
-- Price Providers (Own Scan, Auctionator, CraftProfit, TSM)
---------------------------------------------------------------------------

local function GetOwnScanPrice(itemID)
	local realm = CSU:GetRealmDB()
	local rec = realm.prices[itemID]
	if rec and type(rec[1]) == "number" and rec[1] > 0 then
		return rec[1], rec[2] -- minPrice, totalQty
	end
	return nil
end

local function GetAuctionatorPrice(itemID)
	local a = _G.Auctionator
	local api = a and a.API and a.API.v1
	if not (api and type(api.GetAuctionPriceByItemID) == "function") then return nil end
	local ok, price = pcall(api.GetAuctionPriceByItemID, CSU.CALLER_ID, itemID)
	if ok and type(price) == "number" and price > 0 then
		return price
	end
	return nil
end

local function GetCraftProfitPrice(itemID)
	local cp = _G.CraftProfit
	if not (cp and cp.Scanner and type(cp.Scanner.GetMin) == "function") then return nil end
	local ok, price = pcall(cp.Scanner.GetMin, cp.Scanner, itemID)
	if ok and type(price) == "number" and price > 0 then
		return price
	end
	return nil
end

local function GetTSMPrice(itemID)
	local api = _G.TSM_API
	if not (api and type(api.GetCustomPriceValue) == "function") then return nil end
	local ok, price = pcall(api.GetCustomPriceValue, "min(DBMinBuyout, DBMarket)", "i:" .. itemID)
	if ok and type(price) == "number" and price > 0 then
		return price
	end
	return nil
end

function Prices:GetOwnScanCount()
	local realm = CSU:GetRealmDB()
	local n = 0
	for _ in pairs(realm.prices) do n = n + 1 end
	return n
end

function Prices:GetOwnScanAge()
	local realm = CSU:GetRealmDB()
	if realm.lastScan and realm.lastScan > 0 then
		return time() - realm.lastScan
	end
	return nil
end

function Prices:GetActiveSourceLabel()
	local pref = CSU.settings and CSU.settings.priceSource or "auto"
	if pref == "scan" then return "Own AH Scan" end
	if pref == "auctionator" then return "Auctionator" end
	if pref == "craftprofit" then return "CraftProfit" end
	if pref == "tsm" then return "TSM" end

	-- Auto mode: prefer own scan if populated, else Auctionator, CraftProfit, TSM
	if self:GetOwnScanCount() > 0 then
		return "Auto (Own Scan)"
	end
	if _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1 then
		return "Auto (Auctionator)"
	end
	if _G.CraftProfit and _G.CraftProfit.Scanner then
		return "Auto (CraftProfit)"
	end
	if _G.TSM_API then
		return "Auto (TSM)"
	end
	return "No AH Scan Yet"
end

-- Returns: unitCopper, sourceTag ("ah" | "vendor"), listedQty (or nil)
function Prices:GetUnitCost(itemID)
	if not itemID then return nil end
	local pref = CSU.settings and CSU.settings.priceSource or "auto"
	local ahPrice, qty

	if pref == "scan" then
		ahPrice, qty = GetOwnScanPrice(itemID)
	elseif pref == "auctionator" then
		ahPrice = GetAuctionatorPrice(itemID)
	elseif pref == "craftprofit" then
		ahPrice = GetCraftProfitPrice(itemID)
	elseif pref == "tsm" then
		ahPrice = GetTSMPrice(itemID)
	else
		-- Auto: try own scan first, then Auctionator, CraftProfit, TSM
		ahPrice, qty = GetOwnScanPrice(itemID)
		if not ahPrice then ahPrice = GetAuctionatorPrice(itemID) end
		if not ahPrice then ahPrice = GetCraftProfitPrice(itemID) end
		if not ahPrice then ahPrice = GetTSMPrice(itemID) end
	end

	local vendor = self:GetVendorPrice(itemID)
	if vendor and (not ahPrice or (CSU.settings.useVendorWhenCheaper and vendor < ahPrice)) then
		return vendor, "vendor", nil
	end
	if ahPrice then
		return ahPrice, "ah", qty
	end
	return nil
end

-- Auction price of an item from the chosen source, with no vendor fallback.
function Prices:GetAHPrice(itemID)
	if not itemID then return nil end
	local pref = CSU.settings and CSU.settings.priceSource or "auto"
	if pref == "scan" then return (GetOwnScanPrice(itemID)) end
	if pref == "auctionator" then return GetAuctionatorPrice(itemID) end
	if pref == "craftprofit" then return GetCraftProfitPrice(itemID) end
	if pref == "tsm" then return GetTSMPrice(itemID) end
	return (GetOwnScanPrice(itemID)) or GetAuctionatorPrice(itemID) or GetCraftProfitPrice(itemID) or GetTSMPrice(itemID)
end

Prices.AH_CUT = 0.05 -- the auction house keeps 5% of the sale

-- Deposit to list an auction: a part of the vendor price, more for longer auctions,
-- at least 1 silver per auction (WoW Forever). You get it back when the item sells,
-- you lose it when the auction runs out or you cancel it.
Prices.DEPOSIT_RATE = { [2] = 0.05, [8] = 0.20, [24] = 0.60 }
Prices.MIN_DEPOSIT = 100 -- copper, per auction

function Prices:GetAHHours()
	local h = CSU.settings and CSU.settings.ahHours
	if h == 2 or h == 24 then return h end
	return 8
end

-- Deposit for listing `qty` of this item for the chosen time. Stackable items go up as full
-- stacks (one auction per stack), gear one auction each.
function Prices:GetDeposit(itemID, qty)
	qty = math.max(1, math.floor((qty or 1) + 0.5))
	local vendor, stack = 0, 1
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if fn and itemID then
		local ok, name, _, _, _, _, _, _, stackCount, _, _, sellPrice = pcall(fn, itemID)
		if ok and name then
			if type(sellPrice) == "number" then vendor = sellPrice end
			if type(stackCount) == "number" and stackCount > 1 then stack = stackCount end
		end
	end
	local rate = self.DEPOSIT_RATE[self:GetAHHours()]
	local total, left = 0, qty
	while left > 0 do
		local n = math.min(left, stack)
		total = total + math.max(self.MIN_DEPOSIT, math.floor(rate * vendor * n))
		left = left - n
	end
	return total
end

-- What one of this item brings in when sold, through the better of vendor or auction house.
-- Returns: valuePerUnit, channel ("ah" | "vendor"), ahNetPerUnit (after the 5% cut, or nil), vendorPerUnit (or nil)
function Prices:GetSellValue(itemID)
	if not itemID then return nil end
	local vendorPrice, bindType
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if fn then
		local ok, name, _, _, _, _, _, _, _, _, _, sellPrice, _, _, bind = pcall(fn, itemID)
		if ok and name then
			if type(sellPrice) == "number" and sellPrice > 0 then vendorPrice = sellPrice end
			bindType = bind
		elseif C_Item and C_Item.RequestLoadItemDataByID then
			pcall(C_Item.RequestLoadItemDataByID, itemID)
		end
	end

	local ahNet
	if bindType ~= 1 and bindType ~= 4 then -- soulbound and quest items can't go on the AH
		local ah = self:GetAHPrice(itemID)
		if ah and ah > 0 then
			ahNet = math.floor(ah * (1 - self.AH_CUT))
		end
	end

	if ahNet and (not vendorPrice or ahNet > vendorPrice) then
		return ahNet, "ah", ahNet, vendorPrice
	end
	if vendorPrice then
		return vendorPrice, "vendor", ahNet, vendorPrice
	end
	return nil
end

---------------------------------------------------------------------------
-- Built-in AH Full Browse Scanner (C_AuctionHouse)
---------------------------------------------------------------------------

local function UpdateScanButton()
	local b = Prices.scanButton
	if not b then return end
	if Prices.running then
		b:SetText(string.format("Stop (%d)", Prices.pages or 0))
	else
		b:SetText("SkillUp Scan")
	end
end

function Prices:StoreBrowseResults(results)
	if type(results) ~= "table" or #results == 0 then return 0 end
	local realm = CSU:GetRealmDB()
	local now = time()
	local agg = {}

	for _, r in ipairs(results) do
		local key = r.itemKey
		local itemID = key and key.itemID
		local price = r.minPrice
		if itemID and type(price) == "number" and price > 0 then
			local qty = r.totalQuantity or 0
			local cur = agg[itemID]
			if not cur then
				agg[itemID] = { p = price, q = qty }
			else
				if price < cur.p then cur.p = price end
				cur.q = cur.q + qty
			end
		end
	end

	local count = 0
	for itemID, data in pairs(agg) do
		realm.prices[itemID] = { data.p, data.q, now }
		count = count + 1
	end
	realm.lastScan = now
	return count
end

function Prices:StartScan()
	if not self.ahOpen then
		CSU:Print("Open the Auction House first to run a scan.")
		return false
	end
	if not (C_AuctionHouse and C_AuctionHouse.SendBrowseQuery) then
		CSU:Print("This client does not expose C_AuctionHouse.SendBrowseQuery.")
		return false
	end
	if self.running then
		CSU:Print("An Auction House scan is already running.")
		return false
	end
	if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then
		CSU:Print("Auction House is busy, try again in a second.")
		return false
	end

	self.running = true
	self.startTime = GetTime()
	self.lastProgress = GetTime()
	self.pages = 0
	self.waitingThrottle = false

	for _, ev in ipairs(SCAN_EVENTS) do
		pcall(scanFrame.RegisterEvent, scanFrame, ev)
	end

	local query = {
		searchString = "",
		minLevel = 0,
		maxLevel = 0,
		filters = {},
		itemClassFilters = {},
		sorts = {
			{ sortOrder = (Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price) or 0, reverseSort = false },
		},
	}

	local ok, err = pcall(C_AuctionHouse.SendBrowseQuery, query)
	if not ok then
		CSU:Print("AH scan failed to start: %s", tostring(err))
		self:FinishScan(true)
		return false
	end

	if self.ticker then self.ticker:Cancel() end
	self.ticker = C_Timer.NewTicker(1, function()
		if not Prices.running then return end
		if GetTime() - (Prices.lastProgress or 0) > STALL_TIMEOUT then
			CSU:Print("AH scan timed out after %ds; saving partial results.", STALL_TIMEOUT)
			Prices:FinishScan(true)
		end
	end)

	CSU:Print("Scanning the Auction House...")
	UpdateScanButton()
	CSU:Fire("SCAN_STATE_CHANGED", true)
	return true
end

function Prices:ContinueScan()
	if not self.running then return end
	if C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults() then
		self:FinishScan(false)
		return
	end
	if C_AuctionHouse.IsThrottledMessageSystemReady and C_AuctionHouse.IsThrottledMessageSystemReady() then
		C_AuctionHouse.RequestMoreBrowseResults()
	else
		self.waitingThrottle = true
	end
end

function Prices:FinishScan(partial)
	if not self.running then return end
	self.running = false
	for _, ev in ipairs(SCAN_EVENTS) do
		pcall(scanFrame.UnregisterEvent, scanFrame, ev)
	end
	if self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end

	local results = {}
	if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
		local ok, res = pcall(C_AuctionHouse.GetBrowseResults)
		if ok and type(res) == "table" then results = res end
	end

	local count = self:StoreBrowseResults(results)
	local elapsed = GetTime() - (self.startTime or GetTime())
	CSU:Print("AH scan %s: priced %d items in %.1fs.", partial and "stopped early" or "complete", count, elapsed)

	UpdateScanButton()
	CSU:Fire("SCAN_STATE_CHANGED", false)
	CSU:Fire("PRICES_UPDATED", "scan")
end

scanFrame:SetScript("OnEvent", function(_, event)
	if not Prices.running then return end
	if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
		Prices.lastProgress = GetTime()
		Prices.pages = (Prices.pages or 0) + 1
		UpdateScanButton()
		Prices:ContinueScan()
	elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
		if Prices.waitingThrottle then
			Prices.waitingThrottle = false
			Prices:ContinueScan()
		end
	end
end)

---------------------------------------------------------------------------
-- Auction House button placement (avoids colliding with other addons)
---------------------------------------------------------------------------

local function StartsRightOf(child, anchor)
	local ok, hit = pcall(function()
		if child.IsForbidden and child:IsForbidden() then return false end
		if not child:IsShown() or child:GetNumPoints() < 1 then return false end
		local point, rel, relPoint = child:GetPoint(1)
		return point == "LEFT" and rel == anchor and relPoint == "RIGHT"
	end)
	return ok and hit or false
end

function Prices:PlaceScanButton()
	local b, house = self.scanButton, _G.AuctionHouseFrame
	if not (b and house) then return end
	local anchor = house.MoneyFrameBorder
	b:ClearAllPoints()
	if not anchor then
		b:SetPoint("BOTTOMLEFT", house, "BOTTOMLEFT", 200, 4)
		return
	end
	local ok, children = pcall(function() return { house:GetChildren() } end)
	if ok then
		for _ = 1, 6 do
			local nextAnchor
			for _, child in ipairs(children) do
				if child ~= b and child ~= anchor and StartsRightOf(child, anchor) then
					nextAnchor = child
					break
				end
			end
			if not nextAnchor then break end
			anchor = nextAnchor
		end
	end
	b:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
	if self.openButton then
		self.openButton:ClearAllPoints()
		self.openButton:SetPoint("LEFT", b, "RIGHT", 4, 0)
	end
end

local function CreateScanButton()
	if Prices.scanButton or not _G.AuctionHouseFrame then return end
	if CSU.settings and not CSU.settings.showScanButton then return end

	local b = CreateFrame("Button", "CheapSkillUpScanButton", _G.AuctionHouseFrame, "UIPanelButtonTemplate")
	b:SetSize(130, 22)
	b:SetText("SkillUp Scan")
	b:SetScript("OnClick", function()
		if Prices.running then
			Prices:FinishScan(true)
		else
			Prices:StartScan()
		end
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("SkillUp & Profit AH Scan", 1, 0.82, 0)
		local age = Prices:GetOwnScanAge()
		GameTooltip:AddLine("Last scan: " .. (age and CSU:FormatAge(age) or "Never"), 1, 1, 1)
		GameTooltip:AddLine("Items priced: " .. Prices:GetOwnScanCount(), 1, 1, 1)
		GameTooltip:AddLine("Click to run a full AH browse scan for leveling prices.", 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	Prices.scanButton = b

	local openBtn = CreateFrame("Button", "CheapSkillUpOpenAHButton", _G.AuctionHouseFrame, "UIPanelButtonTemplate")
	openBtn:SetSize(100, 22)
	openBtn:SetText("SkillUp & Profit")
	openBtn:SetScript("OnClick", function()
		if CSU.UI then CSU.UI:Toggle() end
	end)
	openBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Open SkillUp & Profit", 1, 0.82, 0)
		GameTooltip:AddLine("View cheapest skill-ups and buy materials in one click.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	openBtn:SetScript("OnLeave", GameTooltip_Hide)
	Prices.openButton = openBtn

	Prices:PlaceScanButton()
end

---------------------------------------------------------------------------
-- Init & Events
---------------------------------------------------------------------------

function Prices:Init()
	-- Hook Auctionator DB updates if installed
	local a = _G.Auctionator
	local api = a and a.API and a.API.v1
	if api and type(api.RegisterForDBUpdate) == "function" then
		pcall(api.RegisterForDBUpdate, CSU.CALLER_ID, function()
			CSU:Fire("PRICES_UPDATED", "auctionator")
		end)
	end
end

CSU:RegisterEvent("MERCHANT_SHOW", LearnMerchantPrices)

CSU:RegisterEvent("AUCTION_HOUSE_SHOW", function()
	Prices.ahOpen = true
	CreateScanButton()
	Prices:PlaceScanButton()
	if C_Timer and C_Timer.After then
		C_Timer.After(0.1, function() Prices:PlaceScanButton() end)
	end
end)

CSU:RegisterEvent("AUCTION_HOUSE_CLOSED", function()
	Prices.ahOpen = false
	if Prices.running then
		Prices:FinishScan(true)
	end
end)

CSU:RegisterEvent("ADDON_LOADED", function(_, name)
	if name == "Blizzard_AuctionHouseUI" then
		CreateScanButton()
	end
end)
