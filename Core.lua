-- CheapSkillUp :: Core
-- Namespace, saved variables, event hub, money formatting, and slash commands.

local ADDON_NAME, CSU = ...
_G.CheapSkillUp = CSU

CSU.name = ADDON_NAME
CSU.CALLER_ID = ADDON_NAME
CSU.version = "1.5.0"

CSU.DEFAULTS = {
	showOptimal = true,          -- Red/Orange (guaranteed skill-up)
	showMedium = true,           -- Yellow (high chance skill-up)
	showEasy = false,            -- Green (low chance skill-up)
	mode = "cheap",              -- normal (all, A-Z) | cheap | earnback (level + sell back) | profit (best earnings)
	craftWindow = "csu",         -- csu = craft from CheapSkillUp (Blizzard window hidden) | blizzard = normal window
	bagOnly = false,             -- only use the ticked items in your bags
	minLevel = 0,                -- hide crafted gear whose required level is below this (0 = off)
	groupByType = true,          -- group the list by Chest, Legs, Potion, Elixir...
	windowSize = nil,            -- saved { width, height }
	bagVendor = true,            -- in bag mode, still allow mats any vendor sells (thread, salt, flux...)
	priceSource = "auto",        -- auto | scan | auctionator | craftprofit | tsm
	useVendorWhenCheaper = true, -- use vendor price when cheaper than AH
	subtractBags = false,        -- sort by "to buy" (minus mats in bags) vs total craft cost
	showProfButton = true,       -- show button on ProfessionsFrame
	showScanButton = true,       -- show scan button on AuctionHouseFrame
	showLauncherButton = true,   -- show floating draggable icon button on screen
	launcherPoint = nil,         -- saved position for floating icon button
	windowPoint = nil,
	layout = "classic",          -- classic | A | B | C | D (Options > Layout)
	scale = 1,                   -- size of the whole addon (0.6 - 1.5)
	queueShown = nil,            -- queue window open (back after login/reload); false = you closed it
	includeBank = false,         -- count bank items as yours (Craft Queue / Options)
	ahHours = 8,                 -- auction length used for the AH deposit: 2, 8 or 24 hours
	arrow = true,                -- show our own arrow to the pinned trainer / next route stop
	arrowPoint = nil,            -- saved position for the arrow
	theme = "graphite",          -- graphite | dark (Midnight) | blizzard | royal | parchment | emerald | crimson | arcane
}

CSU.COLORS = {
	title   = "ffd100",
	optimal = "ff8040", -- Red/Orange skill-up
	medium  = "ffff00", -- Yellow skill-up
	easy    = "40bf40", -- Green skill-up
	trivial = "808080",
	body    = "e8dcc8",
	muted   = "9d9d9d",
	good    = "4cd137",
	warn    = "ff9933",
	bad     = "ff5b4b",
	vendor  = "66ccff",
}

---------------------------------------------------------------------------
-- Print & color helpers
---------------------------------------------------------------------------

function CSU:Color(hex, text)
	return "|cff" .. hex .. tostring(text) .. "|r"
end

function CSU:Print(msg, ...)
	if select("#", ...) > 0 then
		msg = string.format(msg, ...)
	end
	local frame = DEFAULT_CHAT_FRAME or ChatFrame1
	if frame then
		frame:AddMessage("|cffffd100SkillUp & Profit:|r " .. tostring(msg))
	end
end

function CSU:ItemIDFromLink(link)
	if type(link) ~= "string" then return nil end
	local id = link:match("item:(%d+)")
	return id and tonumber(id) or nil
end

function CSU:GetItemInfoSafe(itemID)
	if not itemID then return nil end
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if not fn then return nil end
	local ok, name, link, quality, _, _, _, _, _, _, icon, sellPrice = pcall(fn, itemID)
	if not ok then return nil end
	return name, link, quality, icon, sellPrice
end

function CSU:GetItemName(itemID)
	if not itemID then return "Unknown Item" end
	local name = self:GetItemInfoSafe(itemID)
	if name then return name end
	if C_Item and C_Item.RequestLoadItemDataByID then
		pcall(C_Item.RequestLoadItemDataByID, itemID)
	end
	return "Item #" .. tostring(itemID)
end

-- Count in the bags you carry (not the bank: you can't craft from the bank)
---------------------------------------------------------------------------
-- Bought on the AH but not in your bags yet (it goes to the mailbox).
-- Counted as yours, so Buy asks only for what's still missing. Drops off as the items
-- reach your bags; opening the mailbox sets it to what is really waiting there.
---------------------------------------------------------------------------
local INCOMING_DAYS = 30 -- AH mail is kept 30 days

local function Incoming()
	local char = CSU:GetCharDB()
	char.incoming = char.incoming or {}
	return char.incoming
end

function CSU:GetIncoming(itemID)
	if not (itemID and self.db) then return 0 end
	local e = Incoming()[itemID]
	if not e then return 0 end
	if e.at and time and (time() - e.at) > INCOMING_DAYS * 86400 then
		Incoming()[itemID] = nil
		return 0
	end
	return e.qty or 0
end

function CSU:AddIncoming(itemID, qty)
	if not (itemID and qty and qty > 0 and self.db) then return end
	local inc = Incoming()
	local e = inc[itemID] or { qty = 0 }
	e.qty = e.qty + qty
	e.at = time and time() or 0
	inc[itemID] = e
	self.lastBag = self.lastBag or {}
	self.lastBag[itemID] = self:GetBagCount(itemID)
end

-- Bags changed: whatever arrived comes off the "on the way" count
function CSU:UpdateIncomingFromBags()
	if not self.db then return false end
	local inc = Incoming()
	self.lastBag = self.lastBag or {}
	local changed = false
	for itemID, e in pairs(inc) do
		local now = self:GetBagCount(itemID)
		local before = self.lastBag[itemID]
		-- mailbox open: the mailbox count is the truth (taking mail out would count twice)
		if before and now > before and not self.mailOpen then
			e.qty = math.max(0, (e.qty or 0) - (now - before))
			changed = true
		end
		self.lastBag[itemID] = now
		if (e.qty or 0) <= 0 then inc[itemID] = nil end
	end
	return changed
end

-- Mailbox open: what's really waiting there for the items we track
function CSU:UpdateIncomingFromMail()
	if not (self.db and GetInboxNumItems and GetInboxItem) then return false end
	local inMail = {}
	local maxAtt = ATTACHMENTS_MAX_RECEIVE or 16
	for i = 1, (GetInboxNumItems() or 0) do
		for a = 1, maxAtt do
			local ok, name, itemID, _, count = pcall(GetInboxItem, i, a)
			if ok and name and itemID then
				inMail[itemID] = (inMail[itemID] or 0) + (count or 1)
			end
		end
	end
	local inc = Incoming()
	local changed = false
	for itemID, e in pairs(inc) do
		local m = inMail[itemID] or 0
		if m ~= e.qty then
			e.qty = m
			changed = true
		end
		if m <= 0 then inc[itemID] = nil end
	end
	return changed
end

-- Bags + bought and on the way (+ bank when Count bank is on)
function CSU:GetOwnedCount(itemID)
	local bank = self.GetBankIncluded and self:GetBankIncluded(itemID) or 0
	return self:GetBagCount(itemID) + self:GetIncoming(itemID) + bank
end

function CSU:GetBagCount(itemID)
	if not itemID then return 0 end
	if C_Item and C_Item.GetItemCount then
		local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false)
		if ok and type(count) == "number" then return count end
	end
	if GetItemCount then
		local ok, count = pcall(GetItemCount, itemID, false)
		if ok and type(count) == "number" then return count end
	end
	return 0
end

function CSU:FormatMoney(copper)
	if type(copper) ~= "number" then return self:Color(self.COLORS.muted, "N/A") end
	local neg = copper < 0
	local absCopper = math.floor(math.abs(copper) + 0.5)
	local g = math.floor(absCopper / 10000)
	local s = math.floor((absCopper % 10000) / 100)
	local c = absCopper % 100

	local parts = {}
	if g > 0 then
		table.insert(parts, string.format("%d|cffffd100g|r", g))
	end
	if s > 0 or g > 0 then
		table.insert(parts, string.format("%d|cffc0c0c0s|r", s))
	end
	if c > 0 or #parts == 0 then
		table.insert(parts, string.format("%d|cffeda55fc|r", c))
	end
	return (neg and "-" or "") .. table.concat(parts, " ")
end

function CSU:FormatAge(seconds)
	if type(seconds) ~= "number" or seconds < 0 then return "never" end
	if seconds < 60 then return string.format("%ds ago", math.floor(seconds)) end
	if seconds < 3600 then return string.format("%dm ago", math.floor(seconds / 60)) end
	if seconds < 86400 then return string.format("%dh ago", math.floor(seconds / 3600)) end
	return string.format("%dd ago", math.floor(seconds / 86400))
end

---------------------------------------------------------------------------
-- Keys & SavedVariables
---------------------------------------------------------------------------

function CSU:GetRealmKey()
	local realm = GetRealmName and GetRealmName() or "UnknownRealm"
	local faction = UnitFactionGroup and UnitFactionGroup("player") or "Neutral"
	return realm .. "-" .. faction
end

function CSU:GetCharKey()
	local name = UnitName and UnitName("player") or "Player"
	local realm = GetRealmName and GetRealmName() or "UnknownRealm"
	return name .. "-" .. realm
end

function CSU:GetRealmDB()
	local key = self:GetRealmKey()
	self.db.realms[key] = self.db.realms[key] or { prices = {}, lastScan = 0 }
	return self.db.realms[key]
end

function CSU:GetCharDB()
	local key = self:GetCharKey()
	self.db.chars[key] = self.db.chars[key] or { professions = {} }
	return self.db.chars[key]
end

local function InitDB()
	if type(CheapSkillUpDB) ~= "table" then
		CheapSkillUpDB = {}
	end
	CSU.db = CheapSkillUpDB
	CSU.db.settings = CSU.db.settings or {}
	for k, v in pairs(CSU.DEFAULTS) do
		if CSU.db.settings[k] == nil then
			CSU.db.settings[k] = v
		end
	end
	CSU.settings = CSU.db.settings
	-- once: the near-black Midnight default becomes the dark grey Graphite (Midnight stays pickable)
	if not CSU.settings.graphiteDefault then
		if CSU.settings.theme == "dark" then CSU.settings.theme = "graphite" end
		CSU.settings.graphiteDefault = true
	end
	CSU.db.realms = CSU.db.realms or {}
	CSU.db.vendor = CSU.db.vendor or {}
	CSU.db.chars = CSU.db.chars or {}
end

---------------------------------------------------------------------------
-- Pub/Sub & Game Events
---------------------------------------------------------------------------

local callbacks = {}

function CSU:On(event, fn)
	callbacks[event] = callbacks[event] or {}
	table.insert(callbacks[event], fn)
end

function CSU:Fire(event, ...)
	local list = callbacks[event]
	if not list then return end
	for _, fn in ipairs(list) do
		local ok, err = pcall(fn, ...)
		if not ok and geterrorhandler then
			geterrorhandler()(err)
		end
	end
end

local eventFrame = CreateFrame("Frame")
local handlers = {}

function CSU:RegisterEvent(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		pcall(eventFrame.RegisterEvent, eventFrame, event)
	end
	table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if not list then return end
	for _, fn in ipairs(list) do
		local ok, err = pcall(fn, event, ...)
		if not ok and geterrorhandler then
			geterrorhandler()(err)
		end
	end
end)

CSU:RegisterEvent("ADDON_LOADED", function(_, addonName)
	if addonName ~= ADDON_NAME then return end
	InitDB()
	CSU:Fire("DB_READY")
end)

CSU:RegisterEvent("PLAYER_LOGIN", function()
	if not CSU.db then InitDB() end
	if CSU.Prices and CSU.Prices.Init then CSU.Prices:Init() end
	if CSU.Calc and CSU.Calc.Init then CSU.Calc:Init() end
	if CSU.Buyer and CSU.Buyer.Init then CSU.Buyer:Init() end
	if CSU.UI and CSU.UI.Init then CSU.UI:Init() end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

SLASH_CHEAPSKILLUP1 = "/csu"
SLASH_CHEAPSKILLUP2 = "/cheapskillup"
SLASH_CHEAPSKILLUP3 = "/skillup"

SlashCmdList["CHEAPSKILLUP"] = function(msg)
	local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
	if cmd == "scan" then
		if CSU.Prices then CSU.Prices:StartScan() end
	elseif cmd == "best" then
		if CSU.Calc then CSU.Calc:PrintBestToChat() end
	elseif cmd == "red" or cmd == "orange" then
		CSU.settings.showOptimal = true
		CSU.settings.showMedium = false
		CSU.settings.showEasy = false
		CSU:Print("Filter set to: Red/Orange (Optimal) only.")
		CSU:Fire("FILTER_CHANGED")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "yellow" then
		CSU.settings.showOptimal = false
		CSU.settings.showMedium = true
		CSU.settings.showEasy = false
		CSU:Print("Filter set to: Yellow (Medium) only.")
		CSU:Fire("FILTER_CHANGED")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "both" then
		CSU.settings.showOptimal = true
		CSU.settings.showMedium = true
		CSU.settings.showEasy = false
		CSU:Print("Filter set to: Red/Orange + Yellow.")
		CSU:Fire("FILTER_CHANGED")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "normal" or cmd == "all" then
		CSU.Calc:SetMode("normal")
		CSU:Print("Mode: Normal (all recipes, A to Z).")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "cheap" or cmd == "cheapest" then
		CSU.Calc:SetMode("cheap")
		CSU:Print("Mode: Cheapest skill-up.")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "earn" or cmd == "earnback" or cmd == "level" then
		CSU.Calc:SetMode("earnback")
		CSU:Print("Mode: Level + Earn (skill up, then sell what you make at vendor or AH).")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "profit" or cmd == "money" then
		CSU.Calc:SetMode("profit")
		CSU:Print("Mode: Best Profit (all recipes, most gold per craft).")
		if CSU.UI then CSU.UI:Show() end
	elseif cmd == "window" then
		if CSU.UI then
			CSU.UI:SetWindowMode(CSU.UI.UseOwnWindow() and "blizzard" or "csu")
		end
	elseif cmd == "layout" then
		local arg = (msg or ""):match("^%s*%S+%s+(%S+)")
		if CSU.UI then
			if not CSU.UI.frame then CSU.UI:CreateMainFrame() end
			if arg then
				local a = arg:lower()
				CSU.UI:SetLayout((a == "a" or a == "b" or a == "c" or a == "d") and a:upper() or "classic")
			else
				CSU.UI:CycleLayout()
			end
		end
	elseif cmd == "scale" then
		local n = tonumber((msg or ""):match("^%s*%S+%s+(%d+)"))
		if CSU.UI then
			if n then
				CSU.UI:SetScale(n / 100)
			end
			CSU:Print("Scale: %d%% (60 to 150). Example: /csu scale 90", math.floor(CSU.UI:GetScale() * 100 + 0.5))
		end
	elseif cmd == "queue" then
		if CSU.UI and CSU.UI.ToggleQueue then CSU.UI:ToggleQueue() end
	elseif cmd == "bank" then
		CSU.settings.includeBank = not CSU.settings.includeBank
		CSU:Print("Count bank items: %s.", CSU.settings.includeBank and "ON" or "OFF")
		CSU:Fire("QUEUE_CHANGED")
	elseif cmd == "ah" then
		local h = tonumber((msg or ""):match("^%s*%S+%s+(%d+)"))
		if h ~= 2 and h ~= 8 and h ~= 24 then
			local cur = CSU.Prices:GetAHHours()
			h = (cur == 2 and 8) or (cur == 8 and 24) or 2
		end
		CSU.settings.ahHours = h
		CSU:Print("Profit now counts a %dh auction (deposit %d%% of the vendor price, at least 1s).", h, CSU.Prices.DEPOSIT_RATE[h] * 100)
		if CSU.UI and CSU.UI.Refresh then CSU.UI:Refresh() end
	elseif cmd == "arrow" then
		if CSU.Arrow then CSU.Arrow:Toggle() end
	elseif cmd == "reset" then
		if CSU.Arrow then CSU.Arrow:ResetPosition() end
		CSU.settings.launcherPoint = nil
		CSU.settings.windowPoint = nil
		CSU.settings.routeBoxPoint = nil
		if CSU.UI and CSU.UI.ResetPositions then CSU.UI:ResetPositions() end
		if CSU.UI and CSU.UI.RenderRouteBox then CSU.UI:RenderRouteBox() end
		CSU:Print("Reset icon, window and arrow positions.")
	elseif cmd == "help" then
		CSU:Print("Commands:")
		CSU:Print("  /csu          - Open / toggle the SkillUp & Profit window")
		CSU:Print("  /csu scan     - Run a full Auction House scan")
		CSU:Print("  /csu best     - Print cheapest skill-up & shopping list in chat")
		CSU:Print("  /csu red      - Filter to Red/Orange (Optimal) skill-ups")
		CSU:Print("  /csu yellow   - Filter to Yellow (Medium) skill-ups")
		CSU:Print("  /csu both     - Filter to Red/Orange + Yellow skill-ups")
		CSU:Print("  /csu normal   - Mode: all recipes, A to Z")
		CSU:Print("  /csu cheap    - Mode: cheapest skill-up")
		CSU:Print("  /csu earn     - Mode: skill up and earn back the most (vendor or AH)")
		CSU:Print("  /csu profit   - Mode: best earnings per craft")
		CSU:Print("  /csu window   - Switch between this window and Blizzard's profession window")
		CSU:Print("  /csu ah 2|8|24 - Auction length for the AH deposit in profit (now %dh)", CSU.Prices:GetAHHours())
		CSU:Print("  /csu layout [classic|a|b|c|d] - Window layout (also in Options)")
		CSU:Print("  /csu scale 90  - Size of the whole addon in % (also in Options)")
		CSU:Print("  /csu queue    - Open the craft queue")
		CSU:Print("  /csu bank     - Count bank items as yours: on / off")
		CSU:Print("  /csu arrow    - Show / hide the arrow to the trainer or next route stop")
		CSU:Print("  /csu reset    - Reset icon, window and arrow positions")
	else
		if CSU.UI then CSU.UI:Toggle() end
	end
end
