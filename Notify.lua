-- SkillUp & Profit :: Notify
-- 1) "What's new" window after an update (OK closes it; shown once per version).
-- 2) Tells you when someone in your guild or group has a newer version of the addon.

local _, CSU = ...
local N = {}
CSU.Notify = N

-- What changed, newest first. Short lines a player understands.
N.CHANGES = {
	["1.6.2"] = {
		"Craft all: the recipe card's gold button crafts everything your bags have mats for (Craft x1 sits on its left). The Craft Queue button is Craft all too.",
		"Crafting from the queue or the Simple view no longer pops up Blizzard's window or the big addon window.",
		"Blizzard's window or this one: only one is on screen. A SkillUp & Profit button on Blizzard's window and a Blizzard Window button here switch between them.",
		"Mats From Bank: a new button next to Mats From Bags. Your bank counts as yours too.",
		"Sell crafted: a coin icon on the Auction House posts what you crafted, 1 silver under the cheapest seller (one click checks the price, the next posts).",
		"The Auction House buttons are now small icons on the top border. Hover them to see what they do.",
		"Errors only show in the red box above the crafting bar, fade out after 4 seconds, and make no sound.",
		"The crafting bar shows the item you're making instead of the WoW logo.",
	},
	["1.6.1"] = {
		"Simple view: filters (Can make, the four colours) and a search box.",
		"Simple view: click a recipe to see its mats, how many you have, and tick or untick each one. A mat you untick counts as off: recipes that need it show 0.",
		"Simple view: sorted like Blizzard's list, highest level first.",
		"Switching to the Blizzard profession window no longer leaves it squashed.",
	},
	["1.6.0"] = {
		"Make your own mats: when a recipe needs something you can make yourself (Bolt of Silk Cloth, cured hides, Bronze Tubes, bars from Mining), each mat has a Buy / Make switch. Make shows the raw mats under it with their own Buy buttons, and Craft makes them first.",
		"Making those mats counts toward your skill points in the cost per point.",
		"Enchanting: an Enchant button puts the enchant on gear with no enchant (bags or worn) or your own gear, one click per skill-up.",
		"Craft Queue puts the mats you make yourself in front of the recipe that needs them.",
		"Simple view: a small window with just your recipes, how many you can make, and a Craft / Enchant button on each. Switch with the Simple / Full buttons.",
		"Crafting bar: icon, seconds and crafts left. Drag it anywhere; turn it on or off and size it in Options.",
		"Clear errors on screen: missing materials, no anvil, no cooking fire, and so on.",
		"Graphite theme: dark grey instead of black. Mats bought on the AH show In Mail until you take them out.",
	},
}

local PREFIX = "SUPF"

-- "1.6.0" > "1.5.10"?
local function Parts(v)
	local t = {}
	for n in tostring(v or ""):gmatch("%d+") do t[#t + 1] = tonumber(n) end
	return t
end
function N.Newer(a, b)
	local x, y = Parts(a), Parts(b)
	for i = 1, math.max(#x, #y) do
		local p, q = x[i] or 0, y[i] or 0
		if p ~= q then return p > q end
	end
	return false
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local frame

local function Create()
	if frame then return frame end
	local tpl = BackdropTemplateMixin and "BackdropTemplate" or nil
	frame = CreateFrame("Frame", "SkillUpProfitNews", UIParent, tpl)
	frame:SetSize(460, 300)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(950)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	if frame.SetBackdrop then
		frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		frame:SetBackdropColor(0.135, 0.138, 0.146, 0.98)
		frame:SetBackdropBorderColor(0.72, 0.56, 0.22, 1)
	end

	local icon = frame:CreateTexture(nil, "ARTWORK")
	icon:SetSize(36, 36)
	icon:SetPoint("TOPLEFT", 14, -12)
	icon:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Icon")

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("LEFT", icon, "RIGHT", 10, 6)
	frame.title:SetJustifyH("LEFT")
	frame.sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.sub:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -3)
	frame.sub:SetJustifyH("LEFT")
	frame.sub:SetTextColor(0.7, 0.72, 0.76)

	frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.body:SetPoint("TOPLEFT", 16, -60)
	frame.body:SetPoint("TOPRIGHT", -16, -60)
	frame.body:SetJustifyH("LEFT")
	frame.body:SetJustifyV("TOP")
	frame.body:SetSpacing(3)

	local ok = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	ok:SetSize(110, 26)
	ok:SetPoint("BOTTOM", 0, 12)
	ok:SetText(OKAY or "OK")
	ok:SetScript("OnClick", function()
		if frame.onOK then frame.onOK() end
		frame:Hide()
	end)
	frame.ok = ok
	frame:Hide()
	return frame
end

local function Show(title, sub, lines, onOK)
	local f = Create()
	f.title:SetText(CSU:Color(CSU.COLORS.title, title))
	f.sub:SetText(sub or "")
	local text = {}
	for _, l in ipairs(lines) do table.insert(text, CSU:Color(CSU.COLORS.title, "- ") .. l) end
	f.body:SetText(table.concat(text, "\n"))
	local h = tonumber(f.body.GetStringHeight and f.body:GetStringHeight()) or (#lines * 30)
	f:SetHeight(math.max(160, 60 + h + 56))
	f.onOK = onOK
	f:Show()
	f:Raise()
end

-- What's new: once per version
function N:ShowWhatsNew(force)
	local s = CSU.settings
	if not s then return end
	local seen = s.seenVersion
	if not force and seen == CSU.version then return end
	local lines = self.CHANGES[CSU.version]
	if not lines then
		s.seenVersion = CSU.version
		return
	end
	Show("SkillUp & Profit Forever " .. CSU.version, "What's new in this version", lines, function()
		s.seenVersion = CSU.version
	end)
end

---------------------------------------------------------------------------
-- Newer version out there?
---------------------------------------------------------------------------
local told, lastSend, replied = false, 0, {}

local function Send(channel, target)
	if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
	pcall(C_ChatInfo.SendAddonMessage, PREFIX, "V:" .. CSU.version, channel, target)
end

function N:Broadcast()
	local now = GetTime and GetTime() or 0
	if now - lastSend < 30 then return end
	lastSend = now
	if IsInGuild and IsInGuild() then Send("GUILD") end
	if IsInRaid and IsInRaid() then
		Send("RAID")
	elseif IsInGroup and IsInGroup() then
		Send("PARTY")
	end
end

local function OnAddonMessage(_, prefix, msg, channel, sender)
	if prefix ~= PREFIX or type(msg) ~= "string" then return end
	local v = msg:match("^V:(.+)$")
	if not v then return end
	if N.Newer(v, CSU.version) then
		if not told then
			told = true
			Show("New version: " .. v, "You have " .. CSU.version, {
				"A newer version of SkillUp & Profit Forever is out (" .. v .. ").",
				"Update it in the CurseForge app, or download it from the CurseForge page.",
			})
			CSU:Print("A newer version (%s) is out. Update it on CurseForge.", v)
		end
	elseif N.Newer(CSU.version, v) and sender and channel ~= "WHISPER" then
		-- they have an older one: tell them (once a minute per player at most)
		local now = GetTime and GetTime() or 0
		if not replied[sender] or now - replied[sender] > 60 then
			replied[sender] = now
			Send("WHISPER", sender)
		end
	end
end

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
	pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
end
CSU:RegisterEvent("CHAT_MSG_ADDON", OnAddonMessage)
CSU:RegisterEvent("GROUP_ROSTER_UPDATE", function() N:Broadcast() end)
CSU:RegisterEvent("PLAYER_LOGIN", function()
	if C_Timer and C_Timer.After then
		C_Timer.After(4, function() N:ShowWhatsNew() end)
		C_Timer.After(15, function() N:Broadcast() end)
	end
end)
