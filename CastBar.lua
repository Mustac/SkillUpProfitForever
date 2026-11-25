-- SkillUp & Profit :: CastBar
-- Crafting bar: recipe icon on the left, the bar with the name and how many are left, seconds on
-- the right. Drag it anywhere; on/off and size in Options. Errors (no materials, no anvil, no
-- cooking fire...) show in red right above it, so you see them even with the window closed.

local _, CSU = ...
local B = {}
CSU.CastBar = B

local W, H, ICON = 240, 20, 26
local bar, errFrame
local cast -- { start, finish, name, icon, guid }
local remaining, expect
local hideAt, failed

local function Settings() return CSU.settings or {} end

function B:IsEnabled() return Settings().castBar ~= false end

function B:GetScale()
	local s = tonumber(Settings().castBarScale) or 1
	return math.max(0.6, math.min(2, s))
end

local function SavePoint(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint(1)
	CSU.settings.castBarPoint = { point, relPoint, x, y }
end

local function Create()
	if bar then return bar end
	local tpl = BackdropTemplateMixin and "BackdropTemplate" or nil
	bar = CreateFrame("Frame", "SkillUpProfitCastBar", UIParent, tpl)
	bar:SetSize(W + ICON + 6, ICON)
	bar:SetFrameStrata("HIGH")
	bar:SetClampedToScreen(true)
	bar:SetMovable(true)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", bar.StartMoving)
	bar:SetScript("OnDragStop", SavePoint)
	local pt = Settings().castBarPoint
	if type(pt) == "table" then
		bar:SetPoint(pt[1] or "BOTTOM", UIParent, pt[2] or "BOTTOM", pt[3] or 0, pt[4] or 200)
	else
		bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
	end

	local iconBg = bar:CreateTexture(nil, "BACKGROUND")
	iconBg:SetSize(ICON, ICON)
	iconBg:SetPoint("LEFT", 0, 0)
	iconBg:SetColorTexture(0, 0, 0, 0.8)
	bar.icon = bar:CreateTexture(nil, "ARTWORK")
	bar.icon:SetPoint("TOPLEFT", iconBg, "TOPLEFT", 1, -1)
	bar.icon:SetPoint("BOTTOMRIGHT", iconBg, "BOTTOMRIGHT", -1, 1)
	bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local sb = CreateFrame("StatusBar", nil, bar, tpl)
	sb:SetSize(W, H)
	sb:SetPoint("LEFT", iconBg, "RIGHT", 6, 0)
	sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	sb:SetStatusBarColor(0.95, 0.76, 0.25)
	sb:SetMinMaxValues(0, 1)
	sb:SetValue(0)
	if sb.SetBackdrop then
		sb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		sb:SetBackdropColor(0.10, 0.10, 0.11, 0.85)
		sb:SetBackdropBorderColor(0, 0, 0, 1)
	end
	bar.sb = sb
	bar.text = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bar.text:SetPoint("LEFT", 6, 0)
	bar.text:SetPoint("RIGHT", -44, 0)
	bar.text:SetJustifyH("LEFT")
	if bar.text.SetWordWrap then bar.text:SetWordWrap(false) end
	bar.time = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bar.time:SetPoint("RIGHT", -6, 0)
	bar.time:SetJustifyH("RIGHT")

	bar:SetScript("OnUpdate", function(self)
		local now = GetTime()
		if cast and not failed then
			local total = math.max(0.01, cast.finish - cast.start)
			local p = math.min(1, math.max(0, (now - cast.start) / total))
			self.sb:SetValue(p)
			self.time:SetText(string.format("%.1fs", math.max(0, cast.finish - now)))
		end
		if hideAt and now >= hideAt then
			hideAt = nil
			if not self.preview then self:Hide() end
		end
	end)
	bar:SetScale(B:GetScale())
	bar:Hide()
	return bar
end

local function Label(name)
	local left = remaining and remaining > 1 and string.format("  (%d left)", remaining) or ""
	return (name or "") .. left
end

function B:Start(name, icon, startMS, endMS)
	if not self:IsEnabled() then return end
	Create()
	failed = false
	hideAt = nil
	cast = { start = startMS / 1000, finish = endMS / 1000, name = name, icon = icon }
	bar.preview = nil
	bar.icon:SetTexture(icon or 134400)
	bar.sb:SetStatusBarColor(0.95, 0.76, 0.25)
	bar.text:SetText(Label(name))
	bar:Show()
end

function B:Done()
	if not bar or not cast then return end
	bar.sb:SetValue(1)
	bar.sb:SetStatusBarColor(0.30, 0.85, 0.35)
	bar.time:SetText("")
	if remaining then remaining = remaining - 1 end
	if not remaining or remaining <= 0 then
		remaining = nil
		cast = nil
		hideAt = GetTime() + 0.6
	end
end

function B:Fail(reason)
	if not bar or not cast then return end
	failed = true
	bar.sb:SetStatusBarColor(0.85, 0.20, 0.18)
	bar.sb:SetValue(1)
	bar.text:SetText(reason or "Interrupted")
	bar.time:SetText("")
	cast, remaining = nil, nil
	hideAt = GetTime() + 1.5
end

-- we asked to craft n: the bar counts them down
local expectIcon, expectIconAt
function B:Expect(n, recipeID)
	expect = (n and n > 1) and n or nil
	expectIcon = recipeID and B.IconForRecipe(recipeID) or nil
	expectIconAt = GetTime and GetTime() or 0
end

-- The game gives crafts a WoW-logo icon on Forever: use the made item's icon instead
local function IconOfRec(rec)
	if not rec then return nil end
	if rec.outputItemID then
		local _, _, _, ic = CSU:GetItemInfoSafe(rec.outputItemID)
		if ic then return ic end
	end
	return rec.icon
end
function B.IconForRecipe(recipeID)
	local char = CSU.db and CSU:GetCharDB()
	for _, prof in pairs(char and char.professions or {}) do
		local rec = prof.recipes and prof.recipes[recipeID]
		if rec then return IconOfRec(rec) end
		for _, r in pairs(prof.recipes or {}) do
			if r.recipeID == recipeID then return IconOfRec(r) end
		end
	end
	return nil
end
function B.IconForName(name)
	local char = CSU.db and CSU:GetCharDB()
	if not name then return nil end
	for _, prof in pairs(char and char.professions or {}) do
		for _, r in pairs(prof.recipes or {}) do
			if r.name == name then return IconOfRec(r) end
		end
	end
	return nil
end

-- shows the bar for a while so you can drag it or see its size
function B:Preview(seconds)
	Create()
	bar.preview = true
	failed = false
	bar.icon:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Icon")
	bar.sb:SetStatusBarColor(0.95, 0.76, 0.25)
	bar.sb:SetValue(0.6)
	bar.text:SetText("Crafting bar: drag me")
	bar.time:SetText("1.8s")
	bar:Show()
	cast = nil
	if C_Timer and C_Timer.After then
		C_Timer.After(seconds or 15, function()
			if bar.preview then bar.preview = nil if not cast then bar:Hide() end end
		end)
	end
end

function B:ApplyScale()
	if bar then bar:SetScale(self:GetScale()) end
	if errFrame then errFrame:SetScale(self:GetScale()) end
end

function B:SetEnabled(on)
	CSU.settings.castBar = on and true or false
	if not on and bar then bar:Hide() end
	if on then self:Preview(6) end
end

function B:SetScale(s)
	s = math.floor((tonumber(s) or 1) * 20 + 0.5) / 20
	CSU.settings.castBarScale = math.max(0.6, math.min(2, s))
	self:ApplyScale()
	self:Preview(4)
end

function B:ResetPosition()
	CSU.settings.castBarPoint = nil
	if bar then
		bar:ClearAllPoints()
		bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
	end
end

---------------------------------------------------------------------------
-- Errors, big and red above the bar's spot (also when the bar is off)
---------------------------------------------------------------------------
local function CreateErr()
	if errFrame then return errFrame end
	Create()
	local tpl = BackdropTemplateMixin and "BackdropTemplate" or nil
	errFrame = CreateFrame("Frame", "SkillUpProfitError", UIParent, tpl)
	errFrame:SetSize(W + ICON + 60, 30)
	errFrame:SetPoint("BOTTOM", bar, "TOP", 0, 8)
	errFrame:SetFrameStrata("DIALOG")
	if errFrame.SetBackdrop then
		errFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		errFrame:SetBackdropColor(0.30, 0.05, 0.05, 0.92)
		errFrame:SetBackdropBorderColor(1, 0.35, 0.30, 1)
	end
	errFrame.text = errFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	errFrame.text:SetPoint("LEFT", 10, 0)
	errFrame.text:SetPoint("RIGHT", -10, 0)
	errFrame.text:SetTextColor(1, 0.85, 0.80)
	errFrame:SetScale(B:GetScale())
	errFrame:EnableMouse(true)
	errFrame:SetScript("OnMouseDown", function(self) self.until_ = nil self:Hide() end)
	-- fades out on its own
	errFrame:SetScript("OnUpdate", function(self)
		if not self.until_ then return end
		local left = self.until_ - GetTime()
		if left <= 0 then
			self.until_ = nil
			self:Hide()
		elseif left < 1 then
			self:SetAlpha(left)
		end
	end)
	errFrame:Hide()
	return errFrame
end

function B:ShowError(msg)
	local e = CreateErr()
	e.text:SetText(msg)
	local w = tonumber(e.text.GetStringWidth and e.text:GetStringWidth()) or 300
	e:SetWidth(math.max(W + ICON + 60, w + 24))
	e:SetAlpha(1)
	e:Show()
	e.until_ = GetTime() + 4
end

-- one place for every crafting error: red box above the bar, red line on the window, and chat
function CSU:ShowError(msg, ...)
	if select("#", ...) > 0 then msg = string.format(msg, ...) end
	B:ShowError(msg)
	CSU:Print(CSU:Color(CSU.COLORS.bad, msg))
end

-- after we start a craft, the game's own error text (Requires Anvil, Missing reagents...) shows here too
local watchUntil = 0
function B:WatchErrors(seconds)
	watchUntil = GetTime() + (seconds or 3)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
CSU:RegisterEvent("UNIT_SPELLCAST_START", function(_, unit)
	if unit ~= "player" then return end
	local name, _, texture, startMS, endMS, isTradeSkill = UnitCastingInfo("player")
	if not (name and isTradeSkill) then return end
	if expect then remaining, expect = expect, nil
	elseif C_TradeSkillUI and C_TradeSkillUI.GetRemainingRecasts then
		local ok, n = pcall(C_TradeSkillUI.GetRemainingRecasts)
		if ok and type(n) == "number" and n > 0 then remaining = n + 1 end
	end
	local icon = B.IconForName(name)
	if not icon and expectIcon and expectIconAt and (GetTime() - expectIconAt) < 3 then icon = expectIcon end
	if not icon and cast and cast.name == name then icon = cast.icon end
	expectIcon = nil
	B:Start(name, icon or texture, startMS, endMS)
end)
CSU:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit)
	if unit == "player" and cast then B:Done() end
end)
CSU:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(_, unit)
	if unit == "player" and cast then B:Fail("Interrupted") end
end)
CSU:RegisterEvent("UNIT_SPELLCAST_FAILED", function(_, unit)
	if unit == "player" and cast then B:Fail("Failed") end
end)
CSU:RegisterEvent("UI_ERROR_MESSAGE", function(_, _, message)
	if type(message) ~= "string" or message == "" then return end
	if GetTime() <= watchUntil or cast then
		watchUntil = 0
		CSU:ShowError(message)
	end
end)
