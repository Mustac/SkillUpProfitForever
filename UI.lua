-- CheapSkillUp :: UI
-- Modern dark flat UI with a Left Profession Sidebar, difficulty filter pills,
-- To Yellow / To Green batch calculator, one-click AH/Vendor buy buttons, and ranked recipe list.

local _, CSU = ...
local UI = {}
CSU.UI = UI

local FRAME_WIDTH = 1080
local FRAME_HEIGHT = 620
local MIN_W, MIN_H = 1000, 540
local BAGCOL_W = 236
local HEADER_HEIGHT = 38
local SIDEBAR_WIDTH = 178
local MAX_SIDEBAR_PROFS = 8
local SIDEBAR_ITEM_HEIGHT = 44

local ROW_HEIGHT = 24
local VISIBLE_ROWS = 40 -- rows made; how many show depends on the window height
local MAX_BUY_ROWS = 10 -- mat rows on the card (mats + the raw mats of what you make yourself)
local MIN_RESERVE_ROWS = 5
local BUY_ROW_HEIGHT = 24
local CALC_LINES = 4
local CALC_LINE_H = 15
local CALC_H = 6 + 16 + CALC_LINES * CALC_LINE_H + 6

-- Layouts (Options > Layout). Classic = recipe card on top, list below.
local LAYOUTS = { "classic", "A", "B", "C", "D" }
local LAYOUT_LABELS = {
	classic = "Classic: recipe on top",
	A = "A: List | Recipe",
	B = "B: List | Recipe + bag tab",
	C = "C: List on top",
	D = "D: Profession tabs",
}
local LAYOUT_TIPS = {
	classic = "The recipe card on top, the list under it, bag items on the right.",
	A = "The list on the left, the recipe card on the right, bag items on the far right.",
	B = "The list on the left, the recipe card on the right. Bag items are a tab inside the card, so the list keeps all its columns.",
	C = "The list on top. Materials and the money boxes side by side at the bottom.",
	D = "Professions as tabs along the top (no sidebar): list, recipe card and bag items in three columns.",
}
local SIDE_CARD_W = { A = 380, B = 420, D = 400 }
local BAGCOL_SLIM = 200
local PROFBAR_H = 34
local C_CALC_W = 300
local C_CARD_H = 70 + 3 * CALC_H + 12 + 8
local NARROW_MATS_TOP = 130
local MIN_SCALE, MAX_SCALE = 0.6, 1.5

local SOURCE_CYCLE = { "auto", "scan", "auctionator", "craftprofit", "tsm" }

local FLAT_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local FLAT2_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 2,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local BLIZZ_DIALOG_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	edgeSize = 24,
	insets = { left = 6, right = 6, top = 6, bottom = 6 },
}

local BLIZZ_GOLD_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	edgeSize = 24,
	insets = { left = 6, right = 6, top = 6, bottom = 6 },
}

local BLIZZ_PANEL_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local CARVED_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border",
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local THEME_CYCLE = { "graphite", "dark", "blizzard", "royal", "parchment", "emerald", "crimson", "arcane" }

local THEMES = {
	-- Dark grey (not black): neutral graphite panels, gold accents
	graphite = {
		label = "Graphite",
		desc = "Dark grey panels (not black) with gold accents.",
		mainBackdrop = FLAT_BACKDROP,
		cardBackdrop = FLAT_BACKDROP,
		inset = 1,
		bg = { 0.135, 0.138, 0.146, 1.00 },
		header = { 0.165, 0.168, 0.178, 1.00 },
		headerLine = { 0.720, 0.560, 0.220, 0.75 },
		sidebar = { 0.150, 0.153, 0.162, 1.00 },
		card = { 0.180, 0.183, 0.194, 1.00 },
		cardBorder = { 0.300, 0.520, 0.350, 1.00 },
		calcBg = { 0.145, 0.148, 0.157, 1.00 },
		calcBorder = { 0.280, 0.288, 0.305, 1.00 },
		border = { 0.300, 0.308, 0.328, 1.00 },
		borderGold = { 0.720, 0.560, 0.220, 1.00 },
		btnBg = { 0.225, 0.230, 0.244, 1.00 },
		btnHover = { 0.290, 0.297, 0.315, 1.00 },
		btnDisabled = { 0.170, 0.173, 0.183, 1.00 },
		profActiveBg = { 0.245, 0.240, 0.215, 1.00 },
		profActiveBorder = { 0.720, 0.560, 0.220, 1.00 },
		profIdleBg = { 0.175, 0.178, 0.188, 1.00 },
		profIdleBorder = { 0.285, 0.292, 0.310, 1.00 },
		profHoverBg = { 0.215, 0.220, 0.233, 1.00 },
		barBg = { 0.100, 0.102, 0.108, 1.00 },
		barFillActive = { 0.950, 0.760, 0.250, 1.00 },
		barFillIdle = { 0.460, 0.490, 0.550, 1.00 },
		accent = { 0.950, 0.760, 0.250, 1.00 },
		thumb = { 0.580, 0.480, 0.250, 1.00 },
	},
	dark = {
		label = "Midnight",
		desc = "Sleek 1px flat dark slate with gold accents.",
		mainBackdrop = FLAT_BACKDROP,
		cardBackdrop = FLAT_BACKDROP,
		inset = 1,
		bg = { 0.055, 0.065, 0.085, 1.00 },
		header = { 0.080, 0.092, 0.120, 1.00 },
		headerLine = { 0.720, 0.560, 0.220, 0.75 },
		sidebar = { 0.068, 0.078, 0.102, 1.00 },
		card = { 0.085, 0.100, 0.125, 1.00 },
		cardBorder = { 0.240, 0.450, 0.300, 1.00 },
		calcBg = { 0.060, 0.070, 0.090, 1.00 },
		calcBorder = { 0.180, 0.210, 0.260, 1.00 },
		border = { 0.220, 0.245, 0.300, 1.00 },
		borderGold = { 0.720, 0.560, 0.220, 1.00 },
		btnBg = { 0.125, 0.145, 0.185, 1.00 },
		btnHover = { 0.180, 0.210, 0.270, 1.00 },
		btnDisabled = { 0.085, 0.095, 0.115, 1.00 },
		profActiveBg = { 0.140, 0.160, 0.220, 1.00 },
		profActiveBorder = { 0.720, 0.560, 0.220, 1.00 },
		profIdleBg = { 0.080, 0.090, 0.120, 1.00 },
		profIdleBorder = { 0.160, 0.180, 0.230, 1.00 },
		profHoverBg = { 0.120, 0.140, 0.190, 1.00 },
		barBg = { 0.032, 0.038, 0.055, 1.00 },
		barFillActive = { 0.950, 0.760, 0.250, 1.00 },
		barFillIdle = { 0.350, 0.420, 0.540, 1.00 },
		accent = { 0.950, 0.760, 0.250, 1.00 },
		thumb = { 0.550, 0.460, 0.240, 1.00 },
	},
	blizzard = {
		label = "Blizzard",
		desc = "Classic WoW beveled dialog border, solid stone panels, and blue skill bars.",
		mainBackdrop = BLIZZ_DIALOG_BACKDROP,
		cardBackdrop = BLIZZ_PANEL_BACKDROP,
		inset = 6,
		bg = { 0.075, 0.070, 0.062, 1.00 },
		header = { 0.135, 0.105, 0.070, 1.00 },
		headerLine = { 0.800, 0.640, 0.280, 1.00 },
		sidebar = { 0.095, 0.086, 0.074, 1.00 },
		card = { 0.105, 0.096, 0.082, 1.00 },
		cardBorder = { 0.850, 0.720, 0.380, 1.00 },
		calcBg = { 0.075, 0.068, 0.058, 1.00 },
		calcBorder = { 0.480, 0.400, 0.260, 1.00 },
		border = { 0.620, 0.500, 0.280, 1.00 },
		borderGold = { 1.000, 1.000, 1.000, 1.00 },
		btnBg = { 0.220, 0.140, 0.080, 1.00 },
		btnHover = { 0.340, 0.220, 0.120, 1.00 },
		btnDisabled = { 0.110, 0.090, 0.075, 1.00 },
		profActiveBg = { 0.250, 0.185, 0.095, 1.00 },
		profActiveBorder = { 0.920, 0.760, 0.320, 1.00 },
		profIdleBg = { 0.115, 0.102, 0.088, 1.00 },
		profIdleBorder = { 0.420, 0.360, 0.260, 1.00 },
		profHoverBg = { 0.185, 0.150, 0.105, 1.00 },
		barBg = { 0.035, 0.030, 0.025, 1.00 },
		barFillActive = { 0.180, 0.560, 0.950, 1.00 },
		barFillIdle = { 0.220, 0.400, 0.640, 1.00 },
		accent = { 1.000, 0.820, 0.000, 1.00 },
		thumb = { 0.780, 0.620, 0.260, 1.00 },
	},
	royal = {
		label = "Royal Gold",
		desc = "Ornate Blizzard gold frame with deep Stormwind navy panels.",
		mainBackdrop = BLIZZ_GOLD_BACKDROP,
		cardBackdrop = BLIZZ_PANEL_BACKDROP,
		inset = 6,
		bg = { 0.055, 0.075, 0.125, 1.00 },
		header = { 0.082, 0.115, 0.190, 1.00 },
		headerLine = { 0.950, 0.760, 0.250, 1.00 },
		sidebar = { 0.068, 0.092, 0.150, 1.00 },
		card = { 0.080, 0.108, 0.175, 1.00 },
		cardBorder = { 0.920, 0.740, 0.260, 1.00 },
		calcBg = { 0.055, 0.075, 0.125, 1.00 },
		calcBorder = { 0.420, 0.360, 0.200, 1.00 },
		border = { 0.460, 0.400, 0.240, 1.00 },
		borderGold = { 1.000, 1.000, 1.000, 1.00 },
		btnBg = { 0.110, 0.160, 0.260, 1.00 },
		btnHover = { 0.160, 0.230, 0.360, 1.00 },
		btnDisabled = { 0.075, 0.098, 0.145, 1.00 },
		profActiveBg = { 0.135, 0.195, 0.310, 1.00 },
		profActiveBorder = { 0.960, 0.780, 0.280, 1.00 },
		profIdleBg = { 0.078, 0.108, 0.175, 1.00 },
		profIdleBorder = { 0.200, 0.260, 0.380, 1.00 },
		profHoverBg = { 0.110, 0.155, 0.245, 1.00 },
		barBg = { 0.030, 0.042, 0.072, 1.00 },
		barFillActive = { 0.980, 0.800, 0.240, 1.00 },
		barFillIdle = { 0.340, 0.480, 0.720, 1.00 },
		accent = { 0.980, 0.800, 0.240, 1.00 },
		thumb = { 0.880, 0.700, 0.240, 1.00 },
	},
	parchment = {
		label = "Leather",
		desc = "Carved tavern border with warm dark leather & copper tones.",
		mainBackdrop = CARVED_BACKDROP,
		cardBackdrop = BLIZZ_PANEL_BACKDROP,
		inset = 4,
		bg = { 0.105, 0.080, 0.060, 1.00 },
		header = { 0.145, 0.108, 0.078, 1.00 },
		headerLine = { 0.840, 0.580, 0.240, 0.85 },
		sidebar = { 0.120, 0.090, 0.066, 1.00 },
		card = { 0.142, 0.108, 0.078, 1.00 },
		cardBorder = { 0.780, 0.540, 0.240, 1.00 },
		calcBg = { 0.098, 0.074, 0.055, 1.00 },
		calcBorder = { 0.360, 0.260, 0.160, 1.00 },
		border = { 0.480, 0.350, 0.210, 1.00 },
		borderGold = { 0.860, 0.640, 0.340, 1.00 },
		btnBg = { 0.185, 0.140, 0.100, 1.00 },
		btnHover = { 0.265, 0.200, 0.140, 1.00 },
		btnDisabled = { 0.115, 0.092, 0.072, 1.00 },
		profActiveBg = { 0.235, 0.172, 0.112, 1.00 },
		profActiveBorder = { 0.900, 0.660, 0.280, 1.00 },
		profIdleBg = { 0.132, 0.100, 0.074, 1.00 },
		profIdleBorder = { 0.280, 0.210, 0.150, 1.00 },
		profHoverBg = { 0.185, 0.140, 0.102, 1.00 },
		barBg = { 0.055, 0.042, 0.030, 1.00 },
		barFillActive = { 0.960, 0.680, 0.220, 1.00 },
		barFillIdle = { 0.560, 0.400, 0.240, 1.00 },
		accent = { 0.960, 0.680, 0.220, 1.00 },
		thumb = { 0.760, 0.520, 0.220, 1.00 },
	},
	emerald = {
		label = "Emerald",
		desc = "Rounded jade tooltip border with deep forest emerald panels.",
		mainBackdrop = BLIZZ_PANEL_BACKDROP,
		cardBackdrop = FLAT_BACKDROP,
		inset = 3,
		bg = { 0.042, 0.076, 0.064, 1.00 },
		header = { 0.058, 0.105, 0.086, 1.00 },
		headerLine = { 0.240, 0.780, 0.460, 0.80 },
		sidebar = { 0.050, 0.090, 0.074, 1.00 },
		card = { 0.064, 0.115, 0.094, 1.00 },
		cardBorder = { 0.240, 0.720, 0.440, 1.00 },
		calcBg = { 0.042, 0.078, 0.064, 1.00 },
		calcBorder = { 0.150, 0.300, 0.220, 1.00 },
		border = { 0.190, 0.380, 0.280, 1.00 },
		borderGold = { 0.300, 0.850, 0.520, 1.00 },
		btnBg = { 0.085, 0.155, 0.125, 1.00 },
		btnHover = { 0.125, 0.230, 0.180, 1.00 },
		btnDisabled = { 0.055, 0.095, 0.078, 1.00 },
		profActiveBg = { 0.100, 0.205, 0.155, 1.00 },
		profActiveBorder = { 0.300, 0.860, 0.500, 1.00 },
		profIdleBg = { 0.055, 0.100, 0.080, 1.00 },
		profIdleBorder = { 0.140, 0.260, 0.200, 1.00 },
		profHoverBg = { 0.085, 0.155, 0.120, 1.00 },
		barBg = { 0.022, 0.045, 0.035, 1.00 },
		barFillActive = { 0.280, 0.920, 0.520, 1.00 },
		barFillIdle = { 0.240, 0.480, 0.360, 1.00 },
		accent = { 0.280, 0.920, 0.520, 1.00 },
		thumb = { 0.240, 0.720, 0.440, 1.00 },
	},
	crimson = {
		label = "Crimson",
		desc = "Bold 2px iron & crimson border with charcoal Horde panels.",
		mainBackdrop = FLAT2_BACKDROP,
		cardBackdrop = FLAT_BACKDROP,
		inset = 2,
		bg = { 0.075, 0.045, 0.048, 1.00 },
		header = { 0.120, 0.055, 0.058, 1.00 },
		headerLine = { 0.820, 0.240, 0.220, 0.90 },
		sidebar = { 0.090, 0.052, 0.054, 1.00 },
		card = { 0.112, 0.062, 0.065, 1.00 },
		cardBorder = { 0.760, 0.240, 0.220, 1.00 },
		calcBg = { 0.078, 0.046, 0.048, 1.00 },
		calcBorder = { 0.340, 0.160, 0.160, 1.00 },
		border = { 0.420, 0.180, 0.180, 1.00 },
		borderGold = { 0.820, 0.240, 0.220, 1.00 },
		btnBg = { 0.175, 0.088, 0.090, 1.00 },
		btnHover = { 0.260, 0.125, 0.125, 1.00 },
		btnDisabled = { 0.095, 0.062, 0.064, 1.00 },
		profActiveBg = { 0.230, 0.095, 0.098, 1.00 },
		profActiveBorder = { 0.900, 0.300, 0.260, 1.00 },
		profIdleBg = { 0.105, 0.062, 0.064, 1.00 },
		profIdleBorder = { 0.260, 0.140, 0.140, 1.00 },
		profHoverBg = { 0.165, 0.082, 0.084, 1.00 },
		barBg = { 0.042, 0.024, 0.026, 1.00 },
		barFillActive = { 0.940, 0.320, 0.240, 1.00 },
		barFillIdle = { 0.540, 0.240, 0.240, 1.00 },
		accent = { 0.940, 0.320, 0.240, 1.00 },
		thumb = { 0.780, 0.260, 0.240, 1.00 },
	},
	arcane = {
		label = "Arcane",
		desc = "Carved violet-tinted frame with twilight indigo & frost highlights.",
		mainBackdrop = CARVED_BACKDROP,
		cardBackdrop = FLAT_BACKDROP,
		inset = 4,
		bg = { 0.062, 0.052, 0.105, 1.00 },
		header = { 0.090, 0.072, 0.155, 1.00 },
		headerLine = { 0.560, 0.420, 0.960, 0.85 },
		sidebar = { 0.074, 0.060, 0.125, 1.00 },
		card = { 0.092, 0.076, 0.155, 1.00 },
		cardBorder = { 0.520, 0.400, 0.900, 1.00 },
		calcBg = { 0.064, 0.052, 0.110, 1.00 },
		calcBorder = { 0.260, 0.210, 0.440, 1.00 },
		border = { 0.340, 0.280, 0.560, 1.00 },
		borderGold = { 0.620, 0.480, 1.000, 1.00 },
		btnBg = { 0.130, 0.108, 0.220, 1.00 },
		btnHover = { 0.195, 0.160, 0.320, 1.00 },
		btnDisabled = { 0.080, 0.070, 0.125, 1.00 },
		profActiveBg = { 0.165, 0.130, 0.280, 1.00 },
		profActiveBorder = { 0.620, 0.480, 1.000, 1.00 },
		profIdleBg = { 0.084, 0.070, 0.142, 1.00 },
		profIdleBorder = { 0.210, 0.175, 0.340, 1.00 },
		profHoverBg = { 0.125, 0.102, 0.210, 1.00 },
		barBg = { 0.034, 0.028, 0.060, 1.00 },
		barFillActive = { 0.420, 0.780, 1.000, 1.00 },
		barFillIdle = { 0.380, 0.340, 0.620, 1.00 },
		accent = { 0.480, 0.800, 1.000, 1.00 },
		thumb = { 0.540, 0.420, 0.920, 1.00 },
	},
}

local function GetTheme()
	local key = CSU.settings and CSU.settings.theme or "graphite"
	return THEMES[key] or THEMES.graphite, THEMES[key] and key or "graphite"
end

-- Palette (updated dynamically by UI:ApplyTheme)
local PAL = {
	bg          = { 0.055, 0.065, 0.085, 0.98 },
	header      = { 0.080, 0.092, 0.120, 1.00 },
	sidebar     = { 0.068, 0.078, 0.102, 1.00 },
	card        = { 0.085, 0.100, 0.125, 1.00 },
	border      = { 0.220, 0.245, 0.300, 1.00 },
	borderGold  = { 0.720, 0.560, 0.220, 0.95 },
	btnBg       = { 0.125, 0.145, 0.185, 1.00 },
	btnHover    = { 0.180, 0.210, 0.270, 1.00 },
	btnDisabled = { 0.085, 0.095, 0.115, 0.85 },
	buyBg       = { 0.110, 0.270, 0.150, 1.00 },
	buyHover    = { 0.150, 0.360, 0.200, 1.00 },
	buyBorder   = { 0.280, 0.720, 0.350, 1.00 },
	goldBg      = { 0.250, 0.195, 0.080, 1.00 },
	goldHover   = { 0.340, 0.265, 0.110, 1.00 },
	goldBorder  = { 0.820, 0.650, 0.240, 1.00 },
	vendorBg    = { 0.090, 0.200, 0.300, 1.00 },
	vendorHover = { 0.130, 0.280, 0.410, 1.00 },
	vendorBorder= { 0.320, 0.680, 0.950, 1.00 },
}

local allFlatButtons = {}

UI.selectedRecipeID = nil
UI.craftCount = 1
UI.scrollOffset = 0
UI.currentList = {}

---------------------------------------------------------------------------
-- UI Primitives
---------------------------------------------------------------------------

local function MakeFrame(frameType, name, parent, template)
	local tpl = template
	if BackdropTemplateMixin then
		tpl = tpl and (tpl .. ",BackdropTemplate") or "BackdropTemplate"
	end
	return CreateFrame(frameType, name, parent, tpl)
end

local function HexToRGB(hex)
	local r = tonumber(hex:sub(1, 2), 16) or 255
	local g = tonumber(hex:sub(3, 4), 16) or 255
	local b = tonumber(hex:sub(5, 6), 16) or 255
	return r / 255, g / 255, b / 255
end

local function ApplyFlatStyle(btn, styleName)
	btn._style = styleName or "default"
	if not btn:IsEnabled() then
		btn:SetBackdropColor(unpack(PAL.btnDisabled))
		btn:SetBackdropBorderColor(0.18, 0.20, 0.24, 0.8)
		if btn.label then btn.label:SetTextColor(0.45, 0.48, 0.52) end
		return
	end
	if styleName == "buy" then
		btn:SetBackdropColor(unpack(btn._hovered and PAL.buyHover or PAL.buyBg))
		btn:SetBackdropBorderColor(unpack(PAL.buyBorder))
		if btn.label then btn.label:SetTextColor(0.88, 1.0, 0.90) end
	elseif styleName == "gold" then
		btn:SetBackdropColor(unpack(btn._hovered and PAL.goldHover or PAL.goldBg))
		btn:SetBackdropBorderColor(unpack(PAL.goldBorder))
		if btn.label then btn.label:SetTextColor(1.0, 0.90, 0.55) end
	elseif styleName == "vendor" then
		btn:SetBackdropColor(unpack(btn._hovered and PAL.vendorHover or PAL.vendorBg))
		btn:SetBackdropBorderColor(unpack(PAL.vendorBorder))
		if btn.label then btn.label:SetTextColor(0.75, 0.92, 1.0) end
	else
		btn:SetBackdropColor(unpack(btn._hovered and PAL.btnHover or PAL.btnBg))
		btn:SetBackdropBorderColor(unpack(PAL.border))
		if btn.label then btn.label:SetTextColor(0.90, 0.92, 0.95) end
	end
end

local function MakeFlatButton(parent, width, height, text, styleName)
	local btn = MakeFrame("Button", nil, parent)
	btn:SetSize(width, height)
	btn:SetBackdrop(FLAT_BACKDROP)

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("CENTER", 0, 0)
	if label.SetWordWrap then label:SetWordWrap(false) end
	btn.label = label

	function btn:SetLabel(t)
		self.label:SetText(t or "")
	end
	function btn:SetStyle(s)
		ApplyFlatStyle(self, s)
	end
	function btn:SetEnabledStyled(enabled, style)
		if enabled then self:Enable() else self:Disable() end
		ApplyFlatStyle(self, style or self._style)
	end

	btn:SetScript("OnEnter", function(self)
		self._hovered = true
		ApplyFlatStyle(self, self._style)
		if self._onEnter then self._onEnter(self) end
	end)
	btn:SetScript("OnLeave", function(self)
		self._hovered = false
		ApplyFlatStyle(self, self._style)
		if self._onLeave then self._onLeave(self) else GameTooltip_Hide() end
	end)

	btn:SetLabel(text)
	ApplyFlatStyle(btn, styleName)
	table.insert(allFlatButtons, btn)
	return btn
end

local function CreateDiffPill(parent, text, hexColor, settingKey)
	local btn = MakeFrame("Button", nil, parent)
	btn:SetSize(96, 24)
	btn:SetBackdrop(FLAT_BACKDROP)

	local dot = btn:CreateTexture(nil, "OVERLAY")
	dot:SetSize(7, 7)
	dot:SetPoint("LEFT", 8, 0)
	local r, g, b = HexToRGB(hexColor)
	dot:SetColorTexture(r, g, b, 1)
	btn.dot = dot

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
	label:SetText(text)
	btn.label = label
	btn.hexColor = hexColor
	btn.settingKey = settingKey

	function btn:UpdateVisual()
		local active = CSU.settings and CSU.settings[self.settingKey]
		local cr, cg, cb = HexToRGB(self.hexColor)
		if active then
			self:SetBackdropColor(cr * 0.22, cg * 0.22, cb * 0.22, 1)
			self:SetBackdropBorderColor(cr, cg, cb, 0.95)
			self.label:SetTextColor(cr, cg, cb)
			self.dot:SetAlpha(1)
		else
			self:SetBackdropColor(unpack(PAL.btnDisabled))
			self:SetBackdropBorderColor(unpack(PAL.border))
			self.label:SetTextColor(0.50, 0.53, 0.58)
			self.dot:SetAlpha(0.35)
		end
	end

	btn:SetScript("OnClick", function(self)
		CSU.settings[self.settingKey] = not CSU.settings[self.settingKey]
		self:UpdateVisual()
		CSU:Fire("FILTER_CHANGED")
	end)

	return btn
end

local function OpenRecipeInProfessionFrame(recipeID)
	if not recipeID then return end
	if C_TradeSkillUI and C_TradeSkillUI.OpenRecipe then
		pcall(C_TradeSkillUI.OpenRecipe, recipeID)
	end
end

-- Can this be crafted right now? Checks tools / where you stand (anvil, forge, cooking fire,
-- Blacksmith Hammer...) and the mats in your bags. Returns ok, message.
function UI.CheckCraft(recipeID, count)
	count = math.max(1, count or 1)
	local T = C_TradeSkillUI
	if not (T and recipeID) then return true end
	if T.GetRecipeRequirements then
		local ok, reqs = pcall(T.GetRecipeRequirements, recipeID)
		if ok and type(reqs) == "table" then
			local missing = {}
			for _, r in ipairs(reqs) do
				if r.met == false and r.name then table.insert(missing, r.name) end
			end
			if #missing > 0 then
				return false, "Needs " .. table.concat(missing, ", ") .. ": stand next to it, or have it in your bags."
			end
		end
	end
	if T.GetRecipeSchematic then
		local basic = Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
		local ok, sch = pcall(T.GetRecipeSchematic, recipeID, false)
		if ok and type(sch) == "table" then
			local miss = {}
			for _, slot in ipairs(sch.reagentSlotSchematics or {}) do
				if slot.required ~= false and (basic == nil or slot.reagentType == nil or slot.reagentType == basic) then
					local have, firstID = 0, nil
					for _, rg in ipairs(slot.reagents or {}) do
						if rg.itemID then
							firstID = firstID or rg.itemID
							have = have + CSU:GetBagCount(rg.itemID)
						end
					end
					local need = (slot.quantityRequired or 1) * count
					if firstID and have < need then
						table.insert(miss, string.format("%dx %s", need - have, CSU:GetItemName(firstID)))
					end
				end
			end
			if #miss > 0 then
				return false, "Not enough materials in your bags: missing " .. table.concat(miss, ", ")
			end
		end
	end
	return true
end

local function CraftRecipeFromWindow(recipeID, count)
	if not recipeID then return false end
	count = math.max(1, math.floor(tonumber(count) or 1))
	local T = C_TradeSkillUI
	if not T then return false end

	-- Check if the matching profession is currently loaded in C_TradeSkillUI
	local ready = T.IsTradeSkillReady and T.IsTradeSkillReady()
	local liveInfo = ready and T.GetRecipeInfo and select(2, pcall(T.GetRecipeInfo, recipeID)) or nil
	local isCurrentProf = ready and liveInfo and liveInfo.learned

	if not isCurrentProf then
		-- Open the profession to this exact recipe first so CraftRecipe can execute
		if T.OpenRecipe then
			pcall(T.OpenRecipe, recipeID)
		end
		-- Try crafting right away in case the client loads synchronously
		if T.CraftRecipe then
			local ok = pcall(T.CraftRecipe, recipeID, count)
			if ok then return true end
		end
		CSU:ShowError("Getting %s ready: click again to craft.", (liveInfo and liveInfo.name) or "the profession")
		return false
	end

	local can, why = UI.CheckCraft(recipeID, count)
	if not can then
		CSU:ShowError(why)
		return false
	end
	if CSU.CastBar then
		CSU.CastBar:Expect(count, recipeID)
		CSU.CastBar:WatchErrors(3)
	end
	if T.CraftRecipe then
		local ok, err = pcall(T.CraftRecipe, recipeID, count)
		if ok then
			return true
		else
			CSU:Print("Craft failed (%s). Opening recipe in Blizzard profession window.", tostring(err))
			OpenRecipeInProfessionFrame(recipeID)
			return false
		end
	end

	OpenRecipeInProfessionFrame(recipeID)
	return false
end

-- Green "+1g 2s" for money made, red "-1g 2s" for money lost
local function SignedMoney(copper)
	if type(copper) ~= "number" then return CSU:Color(CSU.COLORS.muted, "—") end
	if copper >= 0 then
		return CSU:Color(CSU.COLORS.good, "+") .. CSU:FormatMoney(copper)
	end
	return CSU:Color(CSU.COLORS.bad, "-") .. CSU:FormatMoney(-copper)
end

-- "12s 40c AH" / "3s V" / "no sale"
local function SellText(entry)
	if not entry.sellUnit then return CSU:Color(CSU.COLORS.muted, "no sale") end
	local tag = entry.sellChannel == "ah" and CSU:Color(CSU.COLORS.good, " AH") or CSU:Color(CSU.COLORS.vendor, " V")
	return CSU:FormatMoney(entry.sellTotal) .. tag
end

local function ShowRecipeTooltip(anchor, entry)
	if not entry then return end
	local label, hex = CSU.Calc:GetDifficultyMeta(entry.difficulty)
	GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(entry.name, HexToRGB(hex))
	local skillText = label
	if entry.numSkillUps > 1 then
		skillText = skillText .. string.format(" (+%d skill-ups)", entry.numSkillUps)
	end
	GameTooltip:AddLine("Difficulty: " .. skillText, 0.85, 0.85, 0.85)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Reagents (per 1 craft):", 1, 0.82, 0)

	for _, r in ipairs(entry.reagents or {}) do
		local _, _, _, icon = CSU:GetItemInfoSafe(r.itemID)
		local icTag = icon and ("|T" .. tostring(icon) .. ":14:14:0:0:64:64:4:60:4:60|t ") or ""
		local left = string.format("%s%dx %s", icTag, r.qty, r.name)
		if r.have > 0 then
			left = left .. string.format(" |cff4cd137(have %d)|r", r.have)
		end
		local right
		if r.unitPrice then
			local src = r.source == "vendor" and " |cff66ccff[Vendor]|r" or ""
			right = string.format("%s (%s ea)%s", CSU:FormatMoney(r.lineTotal), CSU:FormatMoney(r.unitPrice), src)
		else
			right = "|cffff5b4bNo AH price|r"
		end
		GameTooltip:AddDoubleLine(left, right, 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:AddLine(" ")
	if entry.complete then
		GameTooltip:AddDoubleLine("Total Craft Cost:", CSU:FormatMoney(entry.totalCost), 1, 0.82, 0, 1, 1, 1)
		if entry.numSkillUps > 1 then
			GameTooltip:AddDoubleLine("Cost per Skill-Up:", CSU:FormatMoney(entry.costPerSkillUp), 1, 0.82, 0, 1, 1, 1)
		end
		GameTooltip:AddDoubleLine("Remaining to Buy:", CSU:FormatMoney(entry.buyCost), 0.3, 0.82, 0.22, 1, 1, 1)
		if entry.outputItemID then
			local qtyTxt = (entry.outputQty and entry.outputQty ~= 1) and string.format(" (x%s)", tostring(entry.outputQty)) or ""
			GameTooltip:AddDoubleLine("Vendor buys it for" .. qtyTxt .. ":",
				entry.sellVendor and CSU:FormatMoney(entry.sellVendor * (entry.outputQty or 1)) or "|cff9d9d9dcan't sell|r", 0.4, 0.8, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("AH, after 5% cut" .. qtyTxt .. ":",
				entry.sellAH and CSU:FormatMoney(entry.sellAH * (entry.outputQty or 1)) or "|cff9d9d9dno AH price|r", 0.3, 0.85, 0.35, 1, 1, 1)
			if entry.sellAH then
				local h = CSU.Prices:GetAHHours()
				GameTooltip:AddDoubleLine(string.format("AH deposit %dh (back if it sells):", h),
					CSU:FormatMoney(CSU.Prices:GetDeposit(entry.outputItemID, entry.outputQty or 1)), 0.6, 0.6, 0.6, 0.8, 0.8, 0.8)
			end
			if entry.sellUnit then
				GameTooltip:AddDoubleLine("Real profit: sell at " .. (entry.sellChannel == "ah" and "Auction House" or "Vendor"),
					SignedMoney(entry.profit) .. " per craft", 1, 0.82, 0, 1, 1, 1)
				if entry.numSkillUps and entry.netCostPerSkillUp then
					GameTooltip:AddDoubleLine("Cost per skill-up after selling:", SignedMoney(-entry.netCostPerSkillUp), 1, 0.82, 0, 1, 1, 1)
				end
			end
		end
		if entry.craftsToYellow and entry.craftsToYellow > 0 then
			local prefix = entry.thresholdEstimated and "~" or ""
			GameTooltip:AddDoubleLine(
				string.format("Until Yellow (%s%d crafts -> %d):", prefix, entry.craftsToYellow, entry.yellowSkill or 0),
				CSU:FormatMoney(entry.totalCost * entry.craftsToYellow), 1, 1, 0, 1, 1, 1)
		end
		if entry.craftsToGreen and entry.craftsToGreen > 0 then
			local prefix = entry.thresholdEstimated and "~" or ""
			GameTooltip:AddDoubleLine(
				string.format("Until Green (%s%d crafts -> %d):", prefix, entry.craftsToGreen, entry.greenSkill or 0),
				CSU:FormatMoney(entry.totalCost * entry.craftsToGreen), 0.25, 0.85, 0.25, 1, 1, 1)
		end
	else
		GameTooltip:AddLine(string.format("Missing prices for %d reagent(s). Run an AH scan.", entry.missingPrices), 1, 0.36, 0.29, true)
	end
	GameTooltip:AddLine("Click to select for buying. Shift-click to open in profession window.", 0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Main Window Construction
---------------------------------------------------------------------------

function UI:CreateMainFrame()
	if self.frame then return self.frame end

	local f = MakeFrame("Frame", "CheapSkillUpFrame", UIParent)
	f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	local ws = CSU.settings and CSU.settings.windowSize
	if type(ws) == "table" and ws[1] and ws[2] then
		f:SetSize(math.max(MIN_W, ws[1]), math.max(MIN_H, ws[2]))
	end
	f:SetResizable(true)
	if f.SetResizeBounds then
		f:SetResizeBounds(MIN_W, MIN_H, 2600, 1500)
	elseif f.SetMinResize then
		f:SetMinResize(MIN_W, MIN_H)
	end
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
	-- Drawn over every addon and game window (only tooltips are higher)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(800)
	if f.SetToplevel then f:SetToplevel(true) end
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(true)
	f:SetBackdrop(FLAT_BACKDROP)
	f:SetBackdropColor(unpack(PAL.bg))
	f:SetBackdropBorderColor(unpack(PAL.borderGold))
	f:Hide()

	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint(1)
		if CSU.settings then
			CSU.settings.windowPoint = { point, relPoint, x, y }
		end
	end)

	if UISpecialFrames then
		table.insert(UISpecialFrames, "CheapSkillUpFrame")
	end
	f:HookScript("OnHide", function() UI:OnMainHidden() end)

	if CSU.settings and type(CSU.settings.windowPoint) == "table" then
		local p = CSU.settings.windowPoint
		f:ClearAllPoints()
		f:SetPoint(p[1] or "CENTER", UIParent, p[2] or "CENTER", p[3] or 0, p[4] or 30)
	end

	-----------------------------------------------------------------------
	-- Top Header Bar
	-----------------------------------------------------------------------
	local header = MakeFrame("Frame", nil, f)
	header:SetPoint("TOPLEFT", 1, -1)
	header:SetPoint("TOPRIGHT", -1, -1)
	header:SetHeight(HEADER_HEIGHT)
	header:SetBackdrop(FLAT_BACKDROP)
	header:SetBackdropColor(unpack(PAL.header))
	header:SetBackdropBorderColor(0, 0, 0, 0)
	f.header = header

	local headerLine = header:CreateTexture(nil, "OVERLAY")
	headerLine:SetColorTexture(0.72, 0.56, 0.22, 0.55)
	headerLine:SetPoint("BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(1)
	f.headerLine = headerLine

	local headerIcon = header:CreateTexture(nil, "ARTWORK")
	headerIcon:SetSize(22, 22)
	headerIcon:SetPoint("LEFT", 10, 0)
	headerIcon:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Icon")

	local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", headerIcon, "RIGHT", 7, 0)
	title:SetText(CSU:Color(CSU.COLORS.title, "SkillUp & Profit") .. CSU:Color("8a93a6", " Forever"))
	f.title = title

	local headerSub = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	headerSub:SetPoint("LEFT", title, "RIGHT", 12, 0)
	headerSub:SetTextColor(0.65, 0.70, 0.78)
	f.headerSub = headerSub

	local closeBtn = MakeFlatButton(header, 24, 24, "X", "default")
	closeBtn:SetPoint("RIGHT", -8, 0)
	closeBtn:SetScript("OnClick", function() UI:Minimize() end)
	closeBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Hide to the icon", 1, 0.82, 0)
		GameTooltip:AddLine("Everything stays open. Click the SkillUp & Profit icon to bring it back. Escape closes it fully.", 1, 1, 1, true)
		GameTooltip:Show()
	end

	local scanBtn = MakeFlatButton(header, 88, 24, "Scan AH", "gold")
	scanBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
	scanBtn:SetScript("OnClick", function()
		if CSU.Prices.running then
			CSU.Prices:FinishScan(true)
		else
			CSU.Prices:StartScan()
		end
	end)
	f.scanBtn = scanBtn

	local srcBtn = MakeFlatButton(header, 140, 24, "Auto", "default")
	srcBtn:SetPoint("RIGHT", scanBtn, "LEFT", -6, 0)
	srcBtn:SetScript("OnClick", function()
		local cur = CSU.settings.priceSource or "auto"
		local nextSrc = "auto"
		for i, k in ipairs(SOURCE_CYCLE) do
			if k == cur then
				nextSrc = SOURCE_CYCLE[(i % #SOURCE_CYCLE) + 1]
				break
			end
		end
		CSU.settings.priceSource = nextSrc
		CSU:Fire("FILTER_CHANGED")
	end)
	srcBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Price Source", 1, 0.82, 0)
		GameTooltip:AddLine("Click to cycle: Auto -> Own AH Scan -> Auctionator -> CraftProfit -> TSM", 1, 1, 1, true)
		local age = CSU.Prices:GetOwnScanAge()
		GameTooltip:AddLine("Own AH scan: " .. CSU.Prices:GetOwnScanCount() .. " items (" .. (age and CSU:FormatAge(age) or "never") .. ")", 0.75, 0.75, 0.75)
		GameTooltip:Show()
	end
	f.srcBtn = srcBtn

	local winBtn = MakeFlatButton(header, 168, 24, "Window: SkillUp & Profit", "default")
	winBtn:SetPoint("RIGHT", srcBtn, "LEFT", -6, 0)
	winBtn:SetScript("OnClick", function()
		UI:SetWindowMode(UI.UseOwnWindow() and "blizzard" or "csu")
	end)
	winBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Switch to Blizzard's window", 1, 0.82, 0)
		GameTooltip:AddLine("Only one of the two is on screen. This window goes to its icon and Blizzard's profession window opens.", 1, 1, 1, true)
		GameTooltip:AddLine("The SkillUp & Profit button on Blizzard's window switches back.", 0.6, 0.6, 0.6, true)
		GameTooltip:Show()
	end
	f.winBtn = winBtn

	local themeBtn = MakeFlatButton(header, 118, 24, "Theme: Midnight", "default")
	themeBtn:SetPoint("RIGHT", winBtn, "LEFT", -6, 0)
	themeBtn:SetScript("OnClick", function()
		local _, cur = GetTheme()
		local nextKey = THEME_CYCLE[1]
		for i, k in ipairs(THEME_CYCLE) do
			if k == cur then
				nextKey = THEME_CYCLE[(i % #THEME_CYCLE) + 1]
				break
			end
		end
		CSU.settings.theme = nextKey
		UI:ApplyTheme()
	end)
	themeBtn._onEnter = function(self)
		local _, cur = GetTheme()
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Layout Theme", 1, 0.82, 0)
		for _, k in ipairs(THEME_CYCLE) do
			local t = THEMES[k]
			local mark = (k == cur) and "> " or "   "
			GameTooltip:AddLine(mark .. t.label .. " — " .. t.desc, k == cur and 1 or 0.78, k == cur and 0.9 or 0.78, k == cur and 0.4 or 0.78, true)
		end
		GameTooltip:AddLine("Click to cycle themes.", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end
	f.themeBtn = themeBtn
	-- Options: layout and scale
	local optsBtn = MakeFlatButton(header, 76, 24, "Options", "default")
	optsBtn:SetPoint("RIGHT", themeBtn, "LEFT", -6, 0)
	f.optsBtn = optsBtn
	local queueHdr = MakeFlatButton(header, 82, 24, "Queue", "default")
	queueHdr:SetPoint("RIGHT", optsBtn, "LEFT", -6, 0)
	queueHdr:SetScript("OnClick", function() UI:ToggleQueue() end)
	queueHdr._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Craft queue", 1, 0.82, 0)
		GameTooltip:AddLine("What you queued to craft, all the mats it needs, and what's left to buy. Add recipes with the Queue button on the recipe card.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	f.queueHdr = queueHdr
	local simpleBtn = MakeFlatButton(header, 64, 24, "Simple", "default")
	simpleBtn:SetPoint("RIGHT", queueHdr, "LEFT", -6, 0)
	simpleBtn:SetScript("OnClick", function() UI:SetViewMode("simple") end)
	simpleBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Simple view", 1, 0.82, 0)
		GameTooltip:AddLine("A small window with just your recipes, how many you can make, and a Craft / Enchant button on each. Full brings this window back.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	f.simpleBtn = simpleBtn
	headerSub:SetPoint("RIGHT", simpleBtn, "LEFT", -8, 0)

	local op = MakeFrame("Frame", nil, f)
	op:SetWidth(250)
	op:SetPoint("TOPRIGHT", optsBtn, "BOTTOMRIGHT", 0, -4)
	op:SetFrameLevel((f:GetFrameLevel() or 1) + 60)
	op:SetBackdrop(FLAT_BACKDROP)
	op:SetBackdropColor(PAL.bg[1], PAL.bg[2], PAL.bg[3], 0.98)
	op:SetBackdropBorderColor(unpack(PAL.borderGold))
	op:EnableMouse(true)
	op:Hide()
	local opT = op:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	opT:SetPoint("TOPLEFT", 10, -10)
	opT:SetText(CSU:Color("8a93a6", "LAYOUT"))
	op.layoutBtns = {}
	for i, key in ipairs(LAYOUTS) do
		local b = MakeFlatButton(op, 230, 22, LAYOUT_LABELS[key], "default")
		b:SetPoint("TOPLEFT", 10, -28 - (i - 1) * 26)
		b:SetScript("OnClick", function() UI:SetLayout(key) end)
		b._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:AddLine(LAYOUT_LABELS[key], 1, 0.82, 0)
			GameTooltip:AddLine(LAYOUT_TIPS[key], 1, 1, 1, true)
			GameTooltip:Show()
		end
		op.layoutBtns[key] = b
	end
	local sy = -28 - #LAYOUTS * 26 - 8
	local opS = op:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	opS:SetPoint("TOPLEFT", 10, sy)
	opS:SetText(CSU:Color("8a93a6", "SCALE (whole addon)"))
	local sMinus = MakeFlatButton(op, 26, 22, "-", "default")
	sMinus:SetPoint("TOPLEFT", 10, sy - 18)
	sMinus:SetScript("OnClick", function() UI:SetScale(UI:GetScale() - 0.05) end)
	local sText = op:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	sText:SetPoint("LEFT", sMinus, "RIGHT", 4, 0)
	sText:SetWidth(52)
	sText:SetJustifyH("CENTER")
	op.scaleText = sText
	local sPlus = MakeFlatButton(op, 26, 22, "+", "default")
	sPlus:SetPoint("LEFT", sText, "RIGHT", 4, 0)
	sPlus:SetScript("OnClick", function() UI:SetScale(UI:GetScale() + 0.05) end)
	local sReset = MakeFlatButton(op, 60, 22, "100%", "default")
	sReset:SetPoint("LEFT", sPlus, "RIGHT", 10, 0)
	sReset:SetScript("OnClick", function() UI:SetScale(1) end)
	local bankBtn = MakeFlatButton(op, 230, 22, "Count bank items: OFF", "default")
	bankBtn:SetPoint("TOPLEFT", 10, sy - 18 - 22 - 10)
	bankBtn:SetScript("OnClick", function()
		CSU:SetIncludeBank(not CSU.settings.includeBank)
	end)
	bankBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Count bank items", 1, 0.82, 0)
		GameTooltip:AddLine("ON: mats in your bank count as yours, so Buy asks only for what you don't have anywhere. The bank is remembered from your last visit.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	op.bankBtn = bankBtn

	local by = sy - 18 - 22 - 10 - 22 - 10
	local cbOpt = MakeFlatButton(op, 230, 22, "Crafting bar: ON", "default")
	cbOpt:SetPoint("TOPLEFT", 10, by)
	cbOpt:SetScript("OnClick", function()
		CSU.CastBar:SetEnabled(not CSU.CastBar:IsEnabled())
		UI:UpdateOptions()
	end)
	cbOpt._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Crafting bar", 1, 0.82, 0)
		GameTooltip:AddLine("A bar while you craft: the recipe icon, how many are left, and the seconds. Drag it anywhere. Errors (no materials, no anvil...) show above it.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	op.cbOpt = cbOpt
	local cbMinus = MakeFlatButton(op, 26, 22, "-", "default")
	cbMinus:SetPoint("TOPLEFT", 10, by - 28)
	cbMinus:SetScript("OnClick", function() CSU.CastBar:SetScale(CSU.CastBar:GetScale() - 0.1) UI:UpdateOptions() end)
	local cbText = op:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	cbText:SetPoint("LEFT", cbMinus, "RIGHT", 4, 0)
	cbText:SetWidth(70)
	cbText:SetJustifyH("CENTER")
	op.cbText = cbText
	local cbPlus = MakeFlatButton(op, 26, 22, "+", "default")
	cbPlus:SetPoint("LEFT", cbText, "RIGHT", 4, 0)
	cbPlus:SetScript("OnClick", function() CSU.CastBar:SetScale(CSU.CastBar:GetScale() + 0.1) UI:UpdateOptions() end)
	local cbMove = MakeFlatButton(op, 84, 22, "Move bar", "default")
	cbMove:SetPoint("LEFT", cbPlus, "RIGHT", 10, 0)
	cbMove:SetScript("OnClick", function() CSU.CastBar:Preview(20) end)
	cbMove._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Move the crafting bar", 1, 0.82, 0)
		GameTooltip:AddLine("Shows the bar for 20 seconds: drag it where you want it.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	op:SetHeight(-by + 28 + 22 + 12)
	f.optsPanel = op
	optsBtn:SetScript("OnClick", function()
		op:SetShown(not op:IsShown())
		UI:UpdateOptions()
	end)
	optsBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Options", 1, 0.82, 0)
		GameTooltip:AddLine("Layout of the window and the size of the whole addon.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	headerSub:SetJustifyH("LEFT")
	if headerSub.SetWordWrap then headerSub:SetWordWrap(false) end

	-----------------------------------------------------------------------
	-- Left Profession Sidebar
	-----------------------------------------------------------------------
	local sidebar = MakeFrame("Frame", nil, f)
	sidebar:SetPoint("TOPLEFT", 1, -(HEADER_HEIGHT + 1))
	sidebar:SetPoint("BOTTOMLEFT", 1, 1)
	sidebar:SetWidth(SIDEBAR_WIDTH)
	sidebar:SetBackdrop(FLAT_BACKDROP)
	sidebar:SetBackdropColor(unpack(PAL.sidebar))
	sidebar:SetBackdropBorderColor(0, 0, 0, 0)
	f.sidebar = sidebar

	local sideBorder = sidebar:CreateTexture(nil, "OVERLAY")
	sideBorder:SetColorTexture(0.22, 0.245, 0.30, 0.85)
	sideBorder:SetPoint("TOPRIGHT", 0, 0)
	sideBorder:SetPoint("BOTTOMRIGHT", 0, 0)
	sideBorder:SetWidth(1)
	f.sideBorder = sideBorder

	local sideTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sideTitle:SetPoint("TOPLEFT", 12, -12)
	sideTitle:SetText(CSU:Color("8a93a6", "PROFESSIONS"))

	self.sidebarButtons = {}
	for i = 1, MAX_SIDEBAR_PROFS do
		local pBtn = MakeFrame("Button", nil, sidebar)
		pBtn:SetHeight(SIDEBAR_ITEM_HEIGHT)
		pBtn:SetPoint("TOPLEFT", 6, -30 - (i - 1) * (SIDEBAR_ITEM_HEIGHT + 4))
		pBtn:SetPoint("TOPRIGHT", -7, -30 - (i - 1) * (SIDEBAR_ITEM_HEIGHT + 4))
		pBtn:SetBackdrop(FLAT_BACKDROP)
		pBtn:SetBackdropColor(0.08, 0.09, 0.12, 1)
		pBtn:SetBackdropBorderColor(0.16, 0.18, 0.23, 0.8)

		local accent = pBtn:CreateTexture(nil, "OVERLAY")
		accent:SetWidth(3)
		accent:SetPoint("TOPLEFT", 0, 0)
		accent:SetPoint("BOTTOMLEFT", 0, 0)
		accent:SetColorTexture(0.95, 0.76, 0.25, 1)
		accent:Hide()
		pBtn.accent = accent

		local icon = pBtn:CreateTexture(nil, "ARTWORK")
		icon:SetSize(26, 26)
		icon:SetPoint("LEFT", 9, 0)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		pBtn.icon = icon

		local nameFS = pBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		nameFS:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 1)
		nameFS:SetPoint("RIGHT", -6, 0)
		nameFS:SetJustifyH("LEFT")
		if nameFS.SetWordWrap then nameFS:SetWordWrap(false) end
		pBtn.nameFS = nameFS

		local skillFS = pBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		skillFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 0, -2)
		skillFS:SetJustifyH("LEFT")
		skillFS:SetTextColor(0.62, 0.67, 0.75)
		pBtn.skillFS = skillFS

		-- Thin skill progress bar at bottom of sidebar card
		local barBg = pBtn:CreateTexture(nil, "ARTWORK")
		barBg:SetHeight(4)
		barBg:SetPoint("BOTTOMLEFT", 9, 4)
		barBg:SetPoint("BOTTOMRIGHT", -8, 4)
		barBg:SetColorTexture(0.032, 0.038, 0.055, 1)
		pBtn.barBg = barBg

		local barFill = pBtn:CreateTexture(nil, "OVERLAY")
		barFill:SetHeight(4)
		barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
		barFill:SetWidth(1)
		barFill:SetColorTexture(0.85, 0.68, 0.22, 0.9)
		pBtn.barFill = barFill

		pBtn:SetScript("OnEnter", function(self)
			if not self._active then
				local th = GetTheme()
				self:SetBackdropColor(unpack(th.profHoverBg))
			end
			if self.profData then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(self.profData.name, 1, 0.82, 0)
				GameTooltip:AddLine(string.format("Skill: %d / %d", self.profData.skillLevel or 0, self.profData.maxSkillLevel or 0), 1, 1, 1)
				if self.profData.scanned then
					GameTooltip:AddLine(string.format("%d skill-up recipes cached.", self.profData.recipeCount or 0), 0.3, 0.85, 0.35)
				else
					GameTooltip:AddLine("Not scanned yet — open this profession window once to load its recipes.", 1, 0.6, 0.2, true)
				end
				if self.advice then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(self.advice.text, 1, 0.6, 0.2, true)
				end
				GameTooltip:Show()
			end
		end)
		pBtn:SetScript("OnLeave", function(self)
			if not self._active then
				local th = GetTheme()
				self:SetBackdropColor(unpack(th.profIdleBg))
			end
			GameTooltip_Hide()
		end)
		pBtn:SetScript("OnClick", function(self)
			if not self.profData then return end
			local own = UI.UseOwnWindow()
			if self.profData.scanned then
				UI.selectedRecipeID = nil
				UI.craftCount = 1
				CSU.Buyer:ClearQuote()
				CSU.Calc:SetActiveProfession(self.profData.name)
			end
			if own then
				-- Open it in the background: fresh recipes, and Craft works right away
				CSU.Calc.activeProfession = self.profData.name
				if not UI:OpenProfession(self.profData.name) and not self.profData.scanned then
					CSU:Print("Couldn't open %s from here. Open it once from your spellbook.", self.profData.name)
				end
			elseif not self.profData.scanned then
				CSU:Print("Open your %s profession window once so SkillUp & Profit can read its recipes.", self.profData.name)
			end
		end)

		pBtn:Hide()
		self.sidebarButtons[i] = pBtn
	end

	-- Sidebar footer (AH scan info)
	local sideFooter = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sideFooter:SetPoint("BOTTOMLEFT", 10, 10)
	sideFooter:SetPoint("BOTTOMRIGHT", -10, 10)
	sideFooter:SetJustifyH("LEFT")
	sideFooter:SetTextColor(0.55, 0.60, 0.68)
	f.sideFooter = sideFooter

	-- Layout D: professions as tabs along the top instead of the sidebar
	local profBar = MakeFrame("Frame", nil, f)
	profBar:SetPoint("TOPLEFT", 1, -(HEADER_HEIGHT + 1))
	profBar:SetPoint("TOPRIGHT", -1, -(HEADER_HEIGHT + 1))
	profBar:SetHeight(PROFBAR_H)
	profBar:SetBackdrop(FLAT_BACKDROP)
	profBar:SetBackdropColor(unpack(PAL.sidebar))
	profBar:SetBackdropBorderColor(0, 0, 0, 0)
	profBar:Hide()
	f.profBar = profBar
	f.profTabs = {}
	for i = 1, MAX_SIDEBAR_PROFS do
		local t = MakeFlatButton(profBar, 156, 24, "", "default")
		t:SetPoint("LEFT", 8 + (i - 1) * 162, 0)
		t:SetScript("OnClick", function()
			local sb = UI.sidebarButtons and UI.sidebarButtons[i]
			local fn = sb and sb:GetScript("OnClick")
			if fn then fn(sb) end
		end)
		t._onEnter = function(self)
			local sb = UI.sidebarButtons and UI.sidebarButtons[i]
			local pd = sb and sb.profData
			if not pd then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:AddLine(pd.name, 1, 0.82, 0)
			GameTooltip:AddLine(string.format("Skill: %d / %d", pd.skillLevel or 0, pd.maxSkillLevel or 0), 1, 1, 1)
			if not pd.scanned then
				GameTooltip:AddLine("Not scanned yet: open this profession window once to load its recipes.", 1, 0.6, 0.2, true)
			end
			if sb.advice then GameTooltip:AddLine(sb.advice.text, 1, 0.6, 0.2, true) end
			GameTooltip:Show()
		end
		t:Hide()
		f.profTabs[i] = t
	end

	-----------------------------------------------------------------------
	-- Right Main Content Area
	-----------------------------------------------------------------------
	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
	content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(BAGCOL_W + 1), 1)
	f.content = content

	-- Filter Bar
	local btnRed = CreateDiffPill(content, "Red / Orange", CSU.COLORS.optimal, "showOptimal")
	btnRed:SetPoint("TOPLEFT", 12, -10)
	f.btnRed = btnRed

	local btnYellow = CreateDiffPill(content, "Yellow", CSU.COLORS.medium, "showMedium")
	btnYellow:SetWidth(78)
	btnYellow:SetPoint("LEFT", btnRed, "RIGHT", 6, 0)
	f.btnYellow = btnYellow

	local btnGreen = CreateDiffPill(content, "Green", CSU.COLORS.easy, "showEasy")
	btnGreen:SetWidth(74)
	btnGreen:SetPoint("LEFT", btnYellow, "RIGHT", 6, 0)
	f.btnGreen = btnGreen

	-- Row 2 (under Mode): Mats From Bags: OFF -> ON -> Only Bag Items
	local bagPill = MakeFlatButton(content, 170, 24, "Mats From Bags: OFF", "default")
	bagPill:SetPoint("TOPRIGHT", -12, -40)
	bagPill:SetScript("OnClick", function()
		local st = UI.GetBagState()
		if st == "off" then
			CSU.settings.subtractBags, CSU.settings.bagOnly = true, false
		elseif st == "on" then
			CSU.settings.subtractBags, CSU.settings.bagOnly = true, true
		else
			CSU.settings.subtractBags, CSU.settings.bagOnly = false, false
		end
		UI.selectedRecipeID = nil
		CSU:Fire("FILTER_CHANGED")
	end)
	bagPill._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Mats From Bags (click to switch)", 1, 0.82, 0)
		GameTooltip:AddLine("OFF: every mat counts at its price.", 1, 1, 1, true)
		GameTooltip:AddLine("ON: mats in your bags count as free.", 1, 1, 1, true)
		GameTooltip:AddLine("Only Bag Items: only what you can make from the ticked items on the right.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	f.bagPill = bagPill

	-- Mats From Bank: what's in your bank counts too (same switch as Count bank items)
	local bankPill = MakeFlatButton(content, 160, 24, "Mats From Bank: OFF", "default")
	bankPill:SetPoint("RIGHT", bagPill, "LEFT", -6, 0)
	bankPill:SetScript("OnClick", function()
		CSU:SetIncludeBank(not CSU.settings.includeBank)
		UI.selectedRecipeID = nil
	end)
	bankPill._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Mats From Bank (click to switch)", 1, 0.82, 0)
		GameTooltip:AddLine("ON: mats in your bank count as yours, like the ones in your bags. Buy only asks for what you don't have anywhere, and Only Bag Items can use them too.", 1, 1, 1, true)
		GameTooltip:AddLine("The bank is remembered from your last visit. When you open the bank, the Craft Queue takes what it needs into your bags.", 0.7, 0.7, 0.7, true)
		if not CSU:HasSeenBank() then
			GameTooltip:AddLine("Open your bank once so the addon can see it.", 1, 0.5, 0.4, true)
		end
		GameTooltip:Show()
	end
	f.bankPill = bankPill

	local modeBtn = MakeFlatButton(content, 170, 24, "Mode: Cheapest", "gold")
	modeBtn:SetPoint("TOPRIGHT", -12, -10)
	modeBtn:SetScript("OnClick", function()
		CSU.Calc:CycleMode()
		UI.selectedRecipeID = nil
		UI.scrollOffset = 0
		if UI.frame and UI.frame.scrollBar then UI.frame.scrollBar:SetValue(0) end
	end)
	modeBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Mode (click to switch)", 1, 0.82, 0)
		local m = CSU.Calc:GetMode()
		local function line(key, title, text)
			local on = (m == key)
			GameTooltip:AddLine((on and "> " or "  ") .. title, on and 0.3 or 0.8, on and 0.85 or 0.8, on and 0.35 or 0.8)
			GameTooltip:AddLine("     " .. text, 0.7, 0.7, 0.7, true)
		end
		line("normal", "Normal", "Every recipe you know, highest level on top (like Blizzard's window).")
		line("cheap", "Cheapest", "Cheapest mats per skill point.")
		line("earnback", "Level + Earn", "Skill up, and sell what you make. Ranked by mats minus what the item sells for (vendor, or AH after the 5% cut, whichever pays more). Green numbers mean you make money while levelling.")
		line("profit", "Best Profit", "Every recipe you know, grey too. Ranked by gold earned per craft. Skill-ups are ignored.")
		GameTooltip:Show()
	end
	f.modeBtn = modeBtn

	local modeHint = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	modeHint:SetPoint("LEFT", content, "TOPLEFT", 14, -22)
	modeHint:SetPoint("RIGHT", modeBtn, "LEFT", -8, 0)
	modeHint:SetJustifyH("LEFT")
	modeHint:SetTextColor(0.65, 0.70, 0.78)
	modeHint:SetText("All known recipes, most gold per craft first")
	modeHint:Hide()
	f.modeHint = modeHint

	local groupBtn = MakeFlatButton(content, 150, 24, "Group by type: ON", "default")
	groupBtn:SetPoint("TOPLEFT", 12, -40)
	groupBtn:SetScript("OnClick", function()
		CSU.settings.groupByType = not (CSU.settings.groupByType ~= false)
		CSU:Fire("FILTER_CHANGED")
	end)
	groupBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Group by type", 1, 0.82, 0)
		GameTooltip:AddLine("Groups the list into Chest, Legs, Potion, Elixir... Click a group to fold it.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	f.groupBtn = groupBtn

	local lvlLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	lvlLabel:SetPoint("LEFT", groupBtn, "RIGHT", 14, 0)
	lvlLabel:SetTextColor(0.75, 0.78, 0.84)
	lvlLabel:SetText("Hide gear below level")
	local lvlMinus = MakeFlatButton(content, 20, 22, "-", "default")
	lvlMinus:SetPoint("LEFT", lvlLabel, "RIGHT", 6, 0)
	local lvlText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	lvlText:SetPoint("LEFT", lvlMinus, "RIGHT", 2, 0)
	lvlText:SetWidth(34)
	lvlText:SetJustifyH("CENTER")
	f.lvlText = lvlText
	local lvlPlus = MakeFlatButton(content, 20, 22, "+", "default")
	lvlPlus:SetPoint("LEFT", lvlText, "RIGHT", 2, 0)
	local function stepLevel(dir)
		local step = (IsShiftKeyDown and IsShiftKeyDown()) and 1 or 5
		local v = (tonumber(CSU.settings.minLevel) or 0) + dir * step
		CSU.settings.minLevel = math.max(0, math.min(80, v))
		CSU:Fire("FILTER_CHANGED")
	end
	lvlMinus:SetScript("OnClick", function() stepLevel(-1) end)
	lvlPlus:SetScript("OnClick", function() stepLevel(1) end)
	local function lvlTip(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Hide gear below level", 1, 0.82, 0)
		GameTooltip:AddLine("Hides crafted items that need a lower level than this. Items with no level (mats, potions...) always show. 0 = off.", 1, 1, 1, true)
		GameTooltip:AddLine("Click: steps of 5. Shift-click: steps of 1.", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end
	lvlMinus._onEnter = lvlTip
	lvlPlus._onEnter = lvlTip

	-- Training banner: "Learn Expert Leatherworking: trainer Telonis, Darnassus" [Show on map]
	local banner = MakeFrame("Frame", nil, content)
	banner:SetPoint("TOPLEFT", 12, -70)
	banner:SetPoint("TOPRIGHT", -12, -70)
	banner:SetHeight(34)
	banner:SetBackdrop(FLAT_BACKDROP)
	banner:EnableMouse(true)
	local bIcon = banner:CreateTexture(nil, "ARTWORK")
	bIcon:SetSize(18, 18)
	bIcon:SetPoint("LEFT", 8, 0)
	bIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
	local mapBtn = MakeFlatButton(banner, 108, 22, "Show the way", "gold")
	mapBtn:SetPoint("RIGHT", -6, 0)
	mapBtn:SetScript("OnClick", function(self)
		if not self.place then return end
		if (IsShiftKeyDown and IsShiftKeyDown()) or not CSU.Route then
			UI:PinOnMap(self.place, self.title, false, self.track)
		else
			CSU.Route:Start(self.place, self.title, self.track)
		end
	end)
	mapBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("Show the way", 1, 0.82, 0)
		GameTooltip:AddLine("Plans the way there: walk, fly, boat or zeppelin. The map pin and TomTom arrow always point at the next stop and move on by themselves.", 1, 1, 1, true)
		GameTooltip:AddLine("Shift-click: just pin the trainer.", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end
	local bText = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bText:SetPoint("LEFT", bIcon, "RIGHT", 8, 0)
	bText:SetPoint("RIGHT", mapBtn, "LEFT", -8, 0)
	bText:SetJustifyH("LEFT")
	if bText.SetWordWrap then bText:SetWordWrap(true) end
	banner.text = bText
	banner.mapBtn = mapBtn
	banner:Hide()
	f.trainBanner = banner

	-----------------------------------------------------------------------
	-- Selected / Cheapest Recipe Buy Card (auto-sized height!)
	-----------------------------------------------------------------------
	local card = MakeFrame("Frame", nil, content)
	card:SetPoint("TOPLEFT", 12, -72)
	card:SetPoint("TOPRIGHT", -12, -72)
	card:SetHeight(140)
	card:SetBackdrop(FLAT_BACKDROP)
	card:SetBackdropColor(unpack(PAL.card))
	card:SetBackdropBorderColor(0.24, 0.45, 0.30, 0.95)

	local bestTag = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	bestTag:SetPoint("TOPLEFT", 10, -8)
	card.bestTag = bestTag

	-- Batch target buttons: [To Yel] [To Grn] [x1] [-] xN [+]
	local btnPlus = MakeFlatButton(card, 20, 20, "+", "default")
	btnPlus:SetPoint("TOPRIGHT", -8, -5)
	btnPlus:SetScript("OnClick", function()
		UI.craftCount = math.min(200, (UI.craftCount or 1) + 1)
		CSU.Buyer:ClearQuote()
		UI:Refresh()
	end)

	local countText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	countText:SetPoint("RIGHT", btnPlus, "LEFT", -3, 0)
	countText:SetWidth(30)
	countText:SetJustifyH("CENTER")
	card.countText = countText

	local btnMinus = MakeFlatButton(card, 20, 20, "-", "default")
	btnMinus:SetPoint("RIGHT", countText, "LEFT", -3, 0)
	btnMinus:SetScript("OnClick", function()
		UI.craftCount = math.max(1, (UI.craftCount or 1) - 1)
		CSU.Buyer:ClearQuote()
		UI:Refresh()
	end)

	card.btnPlus = btnPlus
	local queueBtn = MakeFlatButton(card, 50, 20, "Queue", "default")
	queueBtn:SetScript("OnClick", function()
		local e = card.itemHoverBtn.entry
		if not e then return end
		local n = math.max(1, UI.craftCount or 1)
		local _, preps = CSU.Queue:Add(e, n, CSU.Calc.activeProfession)
		if preps and preps > 0 then
			CSU:Print("Queued %dx %s, and the mats you make yourself for it go first.", n, e.name or "?")
		else
			CSU:Print("Queued %dx %s.", n, e.name or "?")
		end
		UI:ShowQueue()
	end)
	queueBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Add to the craft queue", 1, 0.82, 0)
		GameTooltip:AddLine("Adds this recipe (as many as the x number) to the queue. The queue adds up the mats of everything in it, counts your bags, bank and mailbox, and buys or fetches the rest.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	card.queueBtn = queueBtn
	card.btnMinus = btnMinus
	local btnX1 = MakeFlatButton(card, 26, 20, "x1", "default")
	btnX1:SetPoint("RIGHT", btnMinus, "LEFT", -4, 0)
	btnX1:SetScript("OnClick", function()
		UI.craftCount = 1
		CSU.Buyer:ClearQuote()
		UI:Refresh()
	end)

	local btnToGreen = MakeFlatButton(card, 116, 20, "To Green", "default")
	btnToGreen:SetPoint("RIGHT", btnX1, "LEFT", -4, 0)
	btnToGreen:SetScript("OnClick", function(self)
		if self.targetCrafts and self.targetCrafts > 0 then
			UI.craftCount = self.targetCrafts
			CSU.Buyer:ClearQuote()
			UI:Refresh()
		end
	end)
	btnToGreen._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Buy Materials Until Green", 0.25, 0.85, 0.25)
		if self.targetCrafts and self.targetCrafts > 0 then
			GameTooltip:AddLine(string.format("Sets craft count to %d (expected crafts to reach skill %d).",
				self.targetCrafts, self.targetSkill or 0), 1, 1, 1, true)
			if self.estimated then
				GameTooltip:AddLine("Threshold is estimated until observed in-game; tweak with - / + if needed.", 0.7, 0.7, 0.7, true)
			end
		else
			GameTooltip:AddLine("This recipe is already Green or higher.", 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end
	card.btnToGreen = btnToGreen

	local btnToYellow = MakeFlatButton(card, 116, 20, "To Yellow", "default")
	btnToYellow:SetPoint("RIGHT", btnToGreen, "LEFT", -4, 0)
	btnToYellow:SetScript("OnClick", function(self)
		if self.targetCrafts and self.targetCrafts > 0 then
			UI.craftCount = self.targetCrafts
			CSU.Buyer:ClearQuote()
			UI:Refresh()
		end
	end)
	btnToYellow._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Buy Materials Until Yellow", 1, 1, 0)
		if self.targetCrafts and self.targetCrafts > 0 then
			GameTooltip:AddLine(string.format("Sets craft count to %d (guaranteed Red/Orange crafts to reach skill %d).",
				self.targetCrafts, self.targetSkill or 0), 1, 1, 1, true)
			if self.estimated then
				GameTooltip:AddLine("Threshold is estimated until observed in-game; tweak with - / + if needed.", 0.7, 0.7, 0.7, true)
			end
		else
			GameTooltip:AddLine("This recipe is already Yellow or Green.", 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end
	card.btnToYellow = btnToYellow

	-- Recipe header inside card (interactive button so hovering icon/name shows the crafted item's full WoW tooltip!)
	local itemHoverBtn = CreateFrame("Button", nil, card)
	itemHoverBtn:SetPoint("TOPLEFT", 8, -26)
	itemHoverBtn:SetPoint("RIGHT", card, "RIGHT", -254, 0)
	itemHoverBtn:SetHeight(36)

	local bestIcon = itemHoverBtn:CreateTexture(nil, "ARTWORK")
	bestIcon:SetSize(32, 32)
	bestIcon:SetPoint("LEFT", 2, 0)
	bestIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	card.icon = bestIcon

	local bestIconHl = itemHoverBtn:CreateTexture(nil, "HIGHLIGHT")
	bestIconHl:SetAllPoints(bestIcon)
	bestIconHl:SetColorTexture(1, 0.88, 0.4, 0.22)

	local bestName = itemHoverBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	bestName:SetPoint("TOPLEFT", bestIcon, "TOPRIGHT", 8, 2)
	bestName:SetPoint("RIGHT", itemHoverBtn, "RIGHT", 0, 0)
	bestName:SetJustifyH("LEFT")
	if bestName.SetWordWrap then bestName:SetWordWrap(false) end
	card.name = bestName

	local bestSub = itemHoverBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bestSub:SetPoint("TOPLEFT", bestName, "BOTTOMLEFT", 0, -2)
	bestSub:SetPoint("RIGHT", itemHoverBtn, "RIGHT", 0, 0)
	bestSub:SetJustifyH("LEFT")
	if bestSub.SetWordWrap then bestSub:SetWordWrap(false) end
	card.sub = bestSub

	itemHoverBtn:SetScript("OnEnter", function(self)
		local e = self.entry
		if not e then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if e.outputItemID and GameTooltip.SetItemByID then
			GameTooltip:SetItemByID(e.outputItemID)
		elseif e.recipeID and GameTooltip.SetRecipeResultItem then
			pcall(GameTooltip.SetRecipeResultItem, GameTooltip, e.recipeID)
		elseif e.recipeID and GameTooltip.SetSpellByID then
			GameTooltip:SetSpellByID(e.recipeID)
		else
			ShowRecipeTooltip(self, e)
			return
		end
		GameTooltip:Show()
	end)
	itemHoverBtn:SetScript("OnLeave", GameTooltip_Hide)
	itemHoverBtn:SetScript("OnClick", function(self)
		local e = self.entry
		if not e then return end
		if IsModifiedClick and IsModifiedClick("CHATLINK") and e.outputItemID then
			local _, link = CSU:GetItemInfoSafe(e.outputItemID)
			if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
		else
			OpenRecipeInProfessionFrame(e.recipeID)
		end
	end)
	card.itemHoverBtn = itemHoverBtn

	-- One-click Craft button (crafts directly from CheapSkillUp!)
	local craftBtn = MakeFlatButton(card, 84, 26, "Craft", "gold")
	craftBtn:SetPoint("TOPRIGHT", -8, -31)
	craftBtn:SetScript("OnClick", function(self)
		if (self.craftQty or 0) <= 0 and not self.makeRecipeID then
			CSU:ShowError(self.missingText or "Not enough materials in your bags.")
			return
		end
		if self.enchantEntry then
			CSU.Enchant:Cast(self.enchantEntry, OpenRecipeInProfessionFrame)
			return
		end
		if self.makeRecipeID then
			CraftRecipeFromWindow(self.makeRecipeID, self.makeQty or 1)
			return
		end
		if self.recipeID and self.craftQty and self.craftQty > 0 then
			local n = self.craftQty
			local all = tonumber(self.craftAllQty) or 0
			if IsShiftKeyDown and IsShiftKeyDown() and all > n then n = all end
			CraftRecipeFromWindow(self.recipeID, n)
		end
	end)
	craftBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		if self.enchantEntry then
			local info = CSU.Enchant:SlotFor(self.enchantEntry)
			GameTooltip:AddLine("Enchant: " .. (info and info.label or "?"), 1, 0.82, 0)
			GameTooltip:AddLine("Puts this enchant on: " .. CSU.Enchant:Describe(info and CSU.Enchant:FindTarget(info)), 1, 1, 1, true)
			GameTooltip:AddLine("Gear with no enchant is used first (bags or worn), then your own worn gear (asks for a second click). Click again for every skill-up.", 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
			return
		end
		if self.makeRecipeID then
			GameTooltip:AddLine("Make the mats first", 1, 0.82, 0)
			GameTooltip:AddLine(string.format("Makes %dx %s from its own mats. Then Craft.", self.makeQty or 1, self.makeName or "?"), 1, 1, 1, true)
			GameTooltip:Show()
			return
		end
		GameTooltip:AddLine("Craft Directly", 1, 0.82, 0)
		if self.craftQty and self.craftQty > 0 then
			GameTooltip:AddLine(string.format("Crafts %dx using materials in your bags.", self.craftQty), 1, 1, 1, true)
			if (tonumber(self.craftAllQty) or 0) > self.craftQty then
				GameTooltip:AddLine(string.format("Shift-click: craft all %d your bags have mats for.", self.craftAllQty), 0.4, 0.85, 0.4, true)
			end
			GameTooltip:AddLine("If the profession window isn't open yet, the first click opens it and the second starts crafting.", 0.7, 0.7, 0.7, true)
		else
			GameTooltip:AddLine("Buy or gather the required materials first.", 0.75, 0.75, 0.75)
		end
		GameTooltip:Show()
	end
	card.craftBtn = craftBtn

	-- One-click Buy Next Mat button
	local buyNextBtn = MakeFlatButton(card, 152, 26, "Buy Next Mat", "buy")
	buyNextBtn:SetPoint("RIGHT", craftBtn, "LEFT", -6, 0)
	buyNextBtn:SetScript("OnClick", function(self)
		if tonumber(self.craftAllQty) and self.craftAllRecipe then
			CraftRecipeFromWindow(self.craftAllRecipe, self.craftAllQty)
			return
		end
		if self.targetItemID and self.targetQty and self.targetQty > 0 then
			CSU.Buyer:ClickBuy(self.targetItemID, self.targetQty)
			UI:Refresh()
		end
	end)
	card.buyNextBtn = buyNextBtn

	local cardDiv = card:CreateTexture(nil, "ARTWORK")
	cardDiv:SetColorTexture(0.22, 0.32, 0.26, 0.8)
	cardDiv:SetPoint("TOPLEFT", 8, -66)
	cardDiv:SetPoint("TOPRIGHT", -8, -66)
	cardDiv:SetHeight(1)
	card.div = cardDiv

	-- Per-reagent one-click buy rows
	self.buyRows = {}
	for i = 1, MAX_BUY_ROWS do
		local rRow = CreateFrame("Frame", nil, card)
		rRow:SetHeight(BUY_ROW_HEIGHT)
		rRow:SetPoint("TOPLEFT", 10, -70 - (i - 1) * (BUY_ROW_HEIGHT + 2))
		rRow:SetPoint("TOPRIGHT", -10, -70 - (i - 1) * (BUY_ROW_HEIGHT + 2))

		local rItemHover = CreateFrame("Button", nil, rRow)
		rItemHover:SetPoint("LEFT", 0, 0)
		rItemHover:SetSize(214, BUY_ROW_HEIGHT)

		local rIcon = rItemHover:CreateTexture(nil, "ARTWORK")
		rIcon:SetSize(18, 18)
		rIcon:SetPoint("LEFT", 0, 0)
		rIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		rRow.icon = rIcon

		local rName = rItemHover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rName:SetPoint("LEFT", rIcon, "RIGHT", 6, 0)
		rName:SetPoint("RIGHT", 0, 0)
		rName:SetJustifyH("LEFT")
		if rName.SetWordWrap then rName:SetWordWrap(false) end
		rRow.nameFS = rName

		rItemHover:SetScript("OnEnter", function(self)
			if self.itemID and GameTooltip.SetItemByID then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetItemByID(self.itemID)
				GameTooltip:Show()
			end
		end)
		rItemHover:SetScript("OnLeave", GameTooltip_Hide)
		rItemHover:SetScript("OnClick", function(self)
			if self.itemID and IsModifiedClick and IsModifiedClick("CHATLINK") then
				local _, link = CSU:GetItemInfoSafe(self.itemID)
				if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
			end
		end)
		rRow.itemHover = rItemHover

		-- Buy / Make toggle, only for mats one of your recipes makes (bolts, cured hides, bars...)
		local modeBtn = MakeFlatButton(rRow, 44, 20, "Make", "default")
		modeBtn:SetScript("OnClick", function(self)
			if self.itemID then
				CSU.Calc:SetMatChoice(self.itemID, self.how == "make" and "buy" or "make")
			end
		end)
		modeBtn._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(self.how == "make" and "You make this yourself" or "You buy this", 1, 0.82, 0)
			local M = function(c) return c and CSU:FormatMoney(c) or "no price" end
			GameTooltip:AddDoubleLine("Buy it:", M(self.buyUnit) .. " each", 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("Make it" .. (self.makerProf and (" (" .. self.makerProf .. ")") or "") .. ":", M(self.makeUnit) .. " each", 1, 1, 1, 1, 1, 1)
			GameTooltip:AddLine("Click to switch between buying it and making it from its own mats. Remembered for this mat.", 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
		end
		modeBtn:Hide()
		rRow.modeBtn = modeBtn

		local rCount = rRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rCount:SetPoint("LEFT", 218, 0)
		rCount:SetWidth(98)
		rCount:SetJustifyH("RIGHT")
		rRow.countFS = rCount

		local rCost = rRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rCost:SetPoint("LEFT", 320, 0)
		rCost:SetWidth(80)
		rCost:SetJustifyH("RIGHT")
		rRow.costFS = rCost

		local searchBtn = MakeFlatButton(rRow, 22, 20, "?", "default")
		searchBtn:SetPoint("RIGHT", 0, 0)
		searchBtn:SetScript("OnClick", function(self)
			if self.itemID then CSU.Buyer:SearchOnAH(self.itemID) end
		end)
		searchBtn._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("Search in AH Buy Tab", 1, 0.82, 0)
			GameTooltip:Show()
		end
		rRow.searchBtn = searchBtn

		local buyBtn = MakeFlatButton(rRow, 102, 20, "Buy", "buy")
		buyBtn:SetPoint("RIGHT", searchBtn, "LEFT", -4, 0)
		buyBtn:SetScript("OnClick", function(self)
			if self.makeRecipeID then
				if self.makeQty and self.makeQty > 0 then CraftRecipeFromWindow(self.makeRecipeID, self.makeQty) end
				return
			end
			if self.itemID and self.qty and self.qty > 0 then
				CSU.Buyer:ClickBuy(self.itemID, self.qty)
				UI:Refresh()
			end
		end)
		buyBtn._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("Buy", 1, 0.82, 0)
			GameTooltip:AddLine("Scan AH: gets the real listings. The cost then shows what the cheapest ones you need cost.", 1, 1, 1, true)
			GameTooltip:AddLine("Buy: buys them. If someone was faster or the price went up, it goes back to Scan AH.", 1, 1, 1, true)
			GameTooltip:AddLine("At a vendor: buys from the vendor.", 0.4, 0.8, 1, true)
			GameTooltip:Show()
		end
		rRow.buyBtn = buyBtn

		rRow:Hide()
		self.buyRows[i] = rRow
	end
	-- Numbers under the mats, in three boxes: MATERIALS | CRAFTED ITEM | PROFIT
	local calcBox = CreateFrame("Frame", nil, card)
	calcBox:SetHeight(CALC_H)
	card.calcBox = calcBox
	card.calcCols = {}
	for c = 1, 3 do
		local col = MakeFrame("Frame", nil, calcBox)
		col:SetBackdrop(FLAT_BACKDROP)
		col:SetBackdropColor(0.06, 0.07, 0.09, 1)
		col:SetBackdropBorderColor(0.18, 0.21, 0.26, 1)
		local t = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		t:SetPoint("TOPLEFT", 8, -6)
		t:SetPoint("TOPRIGHT", -8, -6)
		t:SetJustifyH("LEFT")
		if t.SetWordWrap then t:SetWordWrap(false) end
		col.title = t
		col.lines = {}
		for l = 1, CALC_LINES do
			local y = -6 - 16 - (l - 1) * CALC_LINE_H
			local val = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			val:SetPoint("TOPRIGHT", -8, y)
			val:SetJustifyH("RIGHT")
			if val.SetWordWrap then val:SetWordWrap(false) end
			local lab = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			lab:SetPoint("TOPLEFT", 8, y)
			lab:SetPoint("RIGHT", val, "LEFT", -6, 0)
			lab:SetJustifyH("LEFT")
			lab:SetTextColor(0.72, 0.75, 0.80)
			if lab.SetWordWrap then lab:SetWordWrap(false) end
			col.lines[l] = { label = lab, value = val }
		end
		card.calcCols[c] = col
	end
	-- Layout B: Materials | Bags tabs inside the card
	local tabMats = MakeFlatButton(card, 74, 22, "Materials", "gold")
	tabMats:SetPoint("TOPLEFT", 10, -98)
	tabMats:SetScript("OnClick", function() UI.cardTab = "mats"; UI:Refresh() end)
	local tabBags = MakeFlatButton(card, 74, 22, "Bags", "default")
	tabBags:SetPoint("LEFT", tabMats, "RIGHT", 4, 0)
	tabBags:SetScript("OnClick", function() UI.cardTab = "bags"; UI:Refresh() end)
	tabBags._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Bag items", 1, 0.82, 0)
		GameTooltip:AddLine("Mats in your bags for this profession. Ticked ones are used by Only Bag Items.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	tabMats:Hide()
	tabBags:Hide()
	card.tabMats, card.tabBags = tabMats, tabBags

	f.bestCard = card

	-----------------------------------------------------------------------
	-- Recipe List Section (anchored dynamically below card!)
	-----------------------------------------------------------------------
	local tableHeader = CreateFrame("Frame", nil, content)
	tableHeader:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -10)
	tableHeader:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0, -10)
	tableHeader:SetHeight(18)
	f.tableHeader = tableHeader

	local ARROW_DOWN = " |TInterface\\Buttons\\Arrow-Down-Up:11:11:0:-1|t"
	local ARROW_UP   = " |TInterface\\Buttons\\Arrow-Up-Up:11:11:0:1|t"

	local function MakeSortHeader(colKey, text, point, x, width, justify)
		local btn = CreateFrame("Button", nil, tableHeader)
		btn:SetPoint(point, x, 0)
		btn:SetSize(width, 18)
		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetAllPoints()
		fs:SetJustifyH(justify or "LEFT")
		btn.fs = fs
		btn._colKey = colKey
		btn._baseText = text
		function btn:UpdateLabel()
			local active = (UI.sortCol == self._colKey)
			local color = active and CSU.COLORS.title or (self._hovered and "c8d0e0" or "7d8699")
			local suffix = ""
			if active then
				suffix = (UI.sortDir == "asc") and ARROW_UP or ARROW_DOWN
			end
			self.fs:SetText(CSU:Color(color, self._baseText) .. suffix)
		end
		function btn:SetText(t)
			self._baseText = t
			self:UpdateLabel()
		end
		btn:SetScript("OnEnter", function(self)
			self._hovered = true
			self:UpdateLabel()
		end)
		btn:SetScript("OnLeave", function(self)
			self._hovered = false
			self:UpdateLabel()
		end)
		btn:SetScript("OnClick", function(self)
			if UI.sortCol ~= self._colKey then
				UI.sortCol = self._colKey
				UI.sortDir = "desc"
			elseif UI.sortDir == "desc" then
				UI.sortDir = "asc"
			else
				UI.sortCol = nil
				UI.sortDir = nil
			end
			UI.scrollOffset = 0
			UI:Refresh()
		end)
		btn:UpdateLabel()
		return btn
	end

	f.hdrRecipe = MakeSortHeader("name", "RECIPE", "LEFT", 4, 215, "LEFT")
	f.hdrType   = MakeSortHeader("type", "TYPE", "RIGHT", -304, 56, "LEFT")
	f.hdrCol3   = MakeSortHeader("col3", "MATS", "RIGHT", -4, 90, "RIGHT")
	f.hdrCol2   = MakeSortHeader("col2", "TO BUY", "RIGHT", -100, 96, "RIGHT")
	f.hdrCost   = MakeSortHeader("cost", "CRAFT COST", "RIGHT", -202, 96, "RIGHT")

	local divider = tableHeader:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(0.22, 0.245, 0.30, 0.85)
	divider:SetPoint("BOTTOMLEFT", 0, 0)
	divider:SetPoint("BOTTOMRIGHT", 0, 0)
	divider:SetHeight(1)
	f.divider = divider

	local listContainer = CreateFrame("Frame", nil, content)
	listContainer:SetPoint("TOPLEFT", tableHeader, "BOTTOMLEFT", 0, -2)
	listContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -24, 24)
	listContainer:EnableMouseWheel(true)
	f.listContainer = listContainer

	local scrollBar = CreateFrame("Slider", "CheapSkillUpScrollBar", content)
	scrollBar:SetPoint("TOPLEFT", listContainer, "TOPRIGHT", 4, -2)
	scrollBar:SetPoint("BOTTOMLEFT", listContainer, "BOTTOMRIGHT", 4, 2)
	scrollBar:SetWidth(8)
	scrollBar:SetOrientation("VERTICAL")
	scrollBar:SetMinMaxValues(0, 0)
	scrollBar:SetValueStep(1)
	scrollBar:SetValue(0)

	local sbBg = scrollBar:CreateTexture(nil, "BACKGROUND")
	sbBg:SetAllPoints()
	sbBg:SetColorTexture(0.10, 0.11, 0.15, 0.9)
	f.sbBg = sbBg

	local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(8, 28)
	thumb:SetColorTexture(0.55, 0.46, 0.24, 0.95)
	scrollBar:SetThumbTexture(thumb)
	f.thumb = thumb

	scrollBar:SetScript("OnValueChanged", function(_, value)
		UI.scrollOffset = math.floor(value + 0.5)
		UI:RenderRows()
	end)
	f.scrollBar = scrollBar

	listContainer:SetScript("OnMouseWheel", function(_, delta)
		local maxVal = select(2, scrollBar:GetMinMaxValues()) or 0
		local cur = scrollBar:GetValue() or 0
		local nextVal = math.max(0, math.min(maxVal, cur - delta * 2))
		scrollBar:SetValue(nextVal)
	end)

	self.rows = {}
	for i = 1, VISIBLE_ROWS do
		local row = CreateFrame("Button", nil, listContainer)
		row:SetHeight(ROW_HEIGHT)
		row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
		row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_HEIGHT)

		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.035 or 0.012)
		row.bg = bg

		local sel = row:CreateTexture(nil, "BORDER")
		sel:SetAllPoints()
		sel:SetColorTexture(0.22, 0.52, 0.28, 0.24)
		sel:Hide()
		row.sel = sel

		local selBar = row:CreateTexture(nil, "OVERLAY")
		selBar:SetWidth(2)
		selBar:SetPoint("TOPLEFT", 0, 0)
		selBar:SetPoint("BOTTOMLEFT", 0, 0)
		selBar:SetColorTexture(0.32, 0.82, 0.40, 1)
		selBar:Hide()
		row.selBar = selBar

		local hl = row:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(0.85, 0.72, 0.30, 0.12)

		local icon = row:CreateTexture(nil, "ARTWORK")
		icon:SetSize(18, 18)
		icon:SetPoint("LEFT", 4, 0)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.icon = icon

		local matsFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		matsFS:SetPoint("RIGHT", -4, 0)
		matsFS:SetWidth(90)
		matsFS:SetJustifyH("RIGHT")
		row.matsFS = matsFS

		local buyFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		buyFS:SetPoint("RIGHT", -100, 0)
		buyFS:SetWidth(96)
		buyFS:SetJustifyH("RIGHT")
		row.buyFS = buyFS

		local costFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		costFS:SetPoint("RIGHT", -202, 0)
		costFS:SetWidth(96)
		costFS:SetJustifyH("RIGHT")
		row.costFS = costFS

		local diffFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		diffFS:SetPoint("RIGHT", -304, 0)
		diffFS:SetWidth(56)
		diffFS:SetJustifyH("LEFT")
		row.diffFS = diffFS

		local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		nameFS:SetPoint("LEFT", 28, 0)
		nameFS:SetPoint("RIGHT", diffFS, "LEFT", -8, 0)
		nameFS:SetJustifyH("LEFT")
		if nameFS.SetWordWrap then nameFS:SetWordWrap(false) end
		row.nameFS = nameFS

		row:SetScript("OnEnter", function(self)
			if self.entry then ShowRecipeTooltip(self, self.entry) end
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		row:SetScript("OnClick", function(self)
			if self.group then
				CSU.settings.collapsed = CSU.settings.collapsed or {}
				CSU.settings.collapsed[self.group] = not CSU.settings.collapsed[self.group] or nil
				UI:Refresh()
				return
			end
			if not self.entry then return end
			UI.selectedRecipeID = self.entry.recipeID
			CSU.Buyer:ClearQuote()
			if IsShiftKeyDown and IsShiftKeyDown() then
				OpenRecipeInProfessionFrame(self.entry.recipeID)
			end
			UI:Refresh()
		end)

		self.rows[i] = row
	end

	-- Content footer
	local footer = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	footer:SetPoint("BOTTOMLEFT", 12, 7)
	footer:SetPoint("BOTTOMRIGHT", -12, 7)
	footer:SetJustifyH("LEFT")
	footer:SetTextColor(0.55, 0.60, 0.68)
	f.footer = footer

	local grip = CreateFrame("Button", nil, f)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)
	grip:SetFrameLevel((f:GetFrameLevel() or 1) + 20)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
	grip:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		CSU.settings.windowSize = { math.floor(f:GetWidth() + 0.5), math.floor(f:GetHeight() + 0.5) }
		UI:Refresh()
	end)
	f:SetScript("OnSizeChanged", function() UI:QueueRefresh() end)

	self.frame = f
	self:CreateBagPanel()
	self:ApplyTheme()
	self:ApplyScale()
	return f
end

---------------------------------------------------------------------------
-- Layouts and scale (Options menu)
---------------------------------------------------------------------------
function UI.GetLayout()
	local l = CSU.settings and CSU.settings.layout
	if l == "A" or l == "B" or l == "C" or l == "D" then return l end
	return "classic"
end
UI.LAYOUTS, UI.LAYOUT_LABELS = LAYOUTS, LAYOUT_LABELS

local function IsSide(l) return l == "A" or l == "B" or l == "D" end

-- One material row: name | have/need | cost | [Buy] [?], measured from the right so it fits any width
local function LayoutBuyRow(r, narrow)
	r.searchBtn:ClearAllPoints()
	r.searchBtn:SetPoint("RIGHT", 0, 0)
	r.buyBtn:ClearAllPoints()
	r.buyBtn:SetWidth(narrow and 92 or 102)
	r.buyBtn:SetPoint("RIGHT", r.searchBtn, "LEFT", -4, 0)
	r.costFS:ClearAllPoints()
	r.costFS:SetWidth(narrow and 62 or 80)
	r.costFS:SetPoint("RIGHT", r.buyBtn, "LEFT", -6, 0)
	r.countFS:ClearAllPoints()
	r.countFS:SetWidth(narrow and 40 or 98)
	r.countFS:SetPoint("RIGHT", r.costFS, "LEFT", -4, 0)
	r.modeBtn:ClearAllPoints()
	r.modeBtn:SetWidth(narrow and 40 or 44)
	r.modeBtn:SetPoint("RIGHT", r.countFS, "LEFT", -4, 0)
	r.itemHover:ClearAllPoints()
	r.itemHover:SetPoint("LEFT", 0, 0)
	r.itemHover:SetPoint("RIGHT", r.modeBtn, "LEFT", -6, 0)
	r.itemHover:SetHeight(BUY_ROW_HEIGHT)
end

-- Recipe list columns. Compact (narrow list): no TYPE column, slimmer money columns.
local function LayoutListColumns(f, rows, compact)
	local cols
	if compact then
		cols = { col3 = { -4, 64 }, col2 = { -74, 78 }, cost = { -158, 66 }, type = { -230, 1 } }
	else
		cols = { col3 = { -4, 90 }, col2 = { -100, 96 }, cost = { -202, 96 }, type = { -304, 56 } }
	end
	for _, row in ipairs(rows) do
		row.matsFS:ClearAllPoints()
		row.matsFS:SetPoint("RIGHT", cols.col3[1], 0)
		row.matsFS:SetWidth(cols.col3[2])
		row.buyFS:ClearAllPoints()
		row.buyFS:SetPoint("RIGHT", cols.col2[1], 0)
		row.buyFS:SetWidth(cols.col2[2])
		row.costFS:ClearAllPoints()
		row.costFS:SetPoint("RIGHT", cols.cost[1], 0)
		row.costFS:SetWidth(cols.cost[2])
		row.diffFS:ClearAllPoints()
		row.diffFS:SetPoint("RIGHT", cols.type[1], 0)
		row.diffFS:SetWidth(cols.type[2])
		row.diffFS:SetShown(not compact)
	end
	local hdr = { { f.hdrCol3, cols.col3 }, { f.hdrCol2, cols.col2 }, { f.hdrCost, cols.cost }, { f.hdrType, cols.type } }
	for _, h in ipairs(hdr) do
		h[1]:ClearAllPoints()
		h[1]:SetPoint("RIGHT", h[2][1], 0)
		h[1]:SetWidth(math.max(h[2][2], 1))
	end
	f.hdrType:SetShown(not compact)
end

function UI:ApplyLayout(bannerShown)
	local f = self.frame
	if not f then return end
	local L = UI.GetLayout()
	local side = IsSide(L)
	local card, content, p = f.bestCard, f.content, self.bagPanel
	local bagW = (L == "classic") and BAGCOL_W or BAGCOL_SLIM

	f.sidebar:SetShown(L ~= "D")
	f.profBar:SetShown(L == "D")
	content:ClearAllPoints()
	if L == "D" then
		content:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -(HEADER_HEIGHT + 1 + PROFBAR_H))
	else
		content:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 0, 0)
	end
	content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -((L == "B") and 1 or (bagW + 1)), 1)

	-- bag items: right column, or a tab inside the card (B)
	if p then
		p:ClearAllPoints()
		if L == "B" then
			p:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -(NARROW_MATS_TOP - 3))
			p:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
			if p.edge then p.edge:Hide() end
			p:SetShown(UI.cardTab == "bags")
		else
			p:SetWidth(bagW)
			p:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(HEADER_HEIGHT + 1))
			p:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
			if p.edge then p.edge:Show() end
			p:Show()
		end
	end
	card.tabMats:SetShown(L == "B")
	card.tabBags:SetShown(L == "B")
	card.tabMats:SetStyle(UI.cardTab ~= "bags" and "gold" or "default")
	card.tabBags:SetStyle(UI.cardTab == "bags" and "gold" or "default")

	-- training banner: over the list only when the card is a column
	local b = f.trainBanner
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT", content, "TOPLEFT", 12, -70)
	b:SetPoint("TOPRIGHT", content, "TOPRIGHT", side and -(12 + SIDE_CARD_W[L] + 8) or -12, -70)
	local y = bannerShown and -110 or -72

	local th, lc = f.tableHeader, f.listContainer
	card:ClearAllPoints()
	th:ClearAllPoints()
	lc:ClearAllPoints()
	if side then
		card:SetWidth(SIDE_CARD_W[L])
		card:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, -72)
		card:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -12, 24)
		th:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
		th:SetPoint("TOPRIGHT", card, "TOPLEFT", -8, y + 72)
		th:SetHeight(18)
		lc:SetPoint("TOPLEFT", th, "BOTTOMLEFT", 0, -2)
		lc:SetPoint("BOTTOMRIGHT", card, "BOTTOMLEFT", -20, 0)
	elseif L == "C" then
		card:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 12, 24)
		card:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -12, 24)
		card:SetHeight(C_CARD_H)
		th:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
		th:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, y)
		th:SetHeight(18)
		lc:SetPoint("TOPLEFT", th, "BOTTOMLEFT", 0, -2)
		lc:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", -12, 8)
	else
		card:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
		card:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, y)
		th:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -10)
		th:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0, -10)
		th:SetHeight(18)
		lc:SetPoint("TOPLEFT", th, "BOTTOMLEFT", 0, -2)
		lc:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -24, 24)
	end

	-- inside the card: a narrow card puts the batch buttons and Craft on their own rows
	local narrow = side
	self.narrowCard = narrow
	card.btnPlus:ClearAllPoints()
	card.queueBtn:ClearAllPoints()
	local tw = narrow and 92 or 116
	card.btnToYellow:SetWidth(tw)
	card.btnToGreen:SetWidth(tw)
	if narrow then
		card.btnPlus:SetPoint("TOPLEFT", card, "TOPLEFT", 10 + tw + 4 + tw + 4 + 26 + 4 + 20 + 3 + 30 + 3, -70)
		card.queueBtn:SetPoint("LEFT", card.btnPlus, "RIGHT", 6, 0)
	else
		card.btnPlus:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -5)
		card.queueBtn:SetPoint("RIGHT", card.btnToYellow, "LEFT", -6, 0)
	end
	card.itemHoverBtn:ClearAllPoints()
	card.itemHoverBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -26)
	card.itemHoverBtn:SetPoint("RIGHT", card, "RIGHT", narrow and -8 or -254, 0)
	card.craftBtn:ClearAllPoints()
	card.craftBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, narrow and -96 or -31)
	local divY = narrow and -(NARROW_MATS_TOP - 4) or -66
	card.div:ClearAllPoints()
	card.div:SetPoint("TOPLEFT", card, "TOPLEFT", 8, divY)
	card.div:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, divY)
	local matsTop = narrow and NARROW_MATS_TOP or 70
	local rightInset = (L == "C") and -(C_CALC_W + 18) or -10
	for i, r in ipairs(self.buyRows) do
		local ry = -(matsTop + (i - 1) * (BUY_ROW_HEIGHT + 2))
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", card, "TOPLEFT", 10, ry)
		r:SetPoint("TOPRIGHT", card, "TOPRIGHT", rightInset, ry)
		LayoutBuyRow(r, narrow)
	end

	-- list columns: compact when the list is narrow
	local fw = tonumber(f:GetWidth()) or FRAME_WIDTH
	local contentW = fw - 2 - ((L == "D") and 0 or SIDEBAR_WIDTH) - ((L == "B") and 0 or bagW)
	local listW = side and (contentW - 12 - SIDE_CARD_W[L] - 8 - 20) or (contentW - 36)
	local compact = listW < 560
	if compact ~= self.compactList or not self.columnsDone then
		self.compactList = compact
		self.columnsDone = true
		LayoutListColumns(f, self.rows, compact)
	end

	local minW, minH = MIN_W, MIN_H
	if side then minW, minH = 1140, 640 elseif L == "C" then minH = 640 end
	if f.SetResizeBounds then
		f:SetResizeBounds(minW, minH, 2600, 1500)
	elseif f.SetMinResize then
		f:SetMinResize(minW, minH)
	end
end

function UI:SetLayout(key)
	if not LAYOUT_LABELS[key] then key = "classic" end
	CSU.settings.layout = key
	local f = self.frame
	if f then
		-- the new layouts need a bigger window; grow it (never past the screen)
		local sc = tonumber(f:GetScale()) or 1
		if sc <= 0 then sc = 1 end
		local w, h = tonumber(f:GetWidth()) or FRAME_WIDTH, tonumber(f:GetHeight()) or FRAME_HEIGHT
		local needW = IsSide(key) and 1240 or (key == "C" and 1080 or w)
		local needH = (key == "D") and 720 or ((key == "classic") and h or 700)
		local maxW = (tonumber(UIParent:GetWidth()) or 1920) / sc - 20
		local maxH = (tonumber(UIParent:GetHeight()) or 1080) / sc - 20
		local nw = math.min(maxW, math.max(w, needW))
		local nh = math.min(maxH, math.max(h, needH))
		if math.abs(nw - w) > 1 or math.abs(nh - h) > 1 then
			f:SetSize(nw, nh)
			CSU.settings.windowSize = { math.floor(nw + 0.5), math.floor(nh + 0.5) }
		end
	end
	self:UpdateOptions()
	self:Refresh()
	C_Timer.After(0, function() UI:Refresh() end)
	CSU:Print("Layout: %s.", LAYOUT_LABELS[key])
end

function UI:CycleLayout()
	local cur = UI.GetLayout()
	for i, k in ipairs(LAYOUTS) do
		if k == cur then return self:SetLayout(LAYOUTS[i % #LAYOUTS + 1]) end
	end
end

-- Errors only show in the red box above the crafting bar (it fades out);
-- the old red line on the window covered its buttons, so it is gone.
function UI:ShowErrorBanner(msg)
	do
		local f = self.frame
		if f and type(f.errBanner) == "table" then f.errBanner:Hide() end
		return
	end
	local f = self.frame
	if not (f and f:IsShown()) then return end
	local b = f.errBanner
	if type(b) ~= "table" then
		b = MakeFrame("Frame", nil, f)
		b:SetPoint("TOPLEFT", f.content, "TOPLEFT", 8, -4)
		b:SetPoint("TOPRIGHT", f.content, "TOPRIGHT", -8, -4)
		b:SetHeight(28)
		b:SetFrameLevel((f:GetFrameLevel() or 1) + 70)
		b:SetBackdrop(FLAT_BACKDROP)
		b:SetBackdropColor(0.30, 0.05, 0.05, 0.95)
		b:SetBackdropBorderColor(1, 0.35, 0.30, 1)
		b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		b.text:SetPoint("LEFT", 10, 0)
		b.text:SetPoint("RIGHT", -10, 0)
		b.text:SetJustifyH("LEFT")
		b.text:SetTextColor(1, 0.85, 0.80)
		if b.text.SetWordWrap then b.text:SetWordWrap(false) end
		b:EnableMouse(true)
		b:SetScript("OnMouseDown", function(self) self:Hide() end)
		f.errBanner = b
	end
	b.text:SetText(msg)
	b:Show()
	b.until_ = GetTime() + 6
	C_Timer.After(6.1, function()
		if b.until_ and GetTime() >= b.until_ then b:Hide() end
	end)
end

function UI:GetScale()
	local s = tonumber(CSU.settings and CSU.settings.scale) or 1
	return math.max(MIN_SCALE, math.min(MAX_SCALE, s))
end

-- Scale of the whole addon: window, floating icon, arrow and route box
function UI:ApplyScale()
	local s = self:GetScale()
	if self.frame then self.frame:SetScale(s) end
	if self.launcherBtn then self.launcherBtn:SetScale(s) end
	if self.routeBox then self.routeBox:SetScale(s) end
	if self.queueFrame then self.queueFrame:SetScale(s) end
	if self.compact then self.compact:SetScale(s) end
	if CSU.Arrow and CSU.Arrow.GetFrame then
		local af = CSU.Arrow:GetFrame()
		if af then af:SetScale(s) end
	end
end

function UI:SetScale(s)
	s = math.floor((tonumber(s) or 1) * 20 + 0.5) / 20
	s = math.max(MIN_SCALE, math.min(MAX_SCALE, s))
	CSU.settings.scale = s
	self:ApplyScale()
	self:UpdateOptions()
end

function UI:UpdateOptions()
	local f = self.frame
	local op = f and f.optsPanel
	if not op then return end
	local cur = UI.GetLayout()
	for key, b in pairs(op.layoutBtns) do
		b:SetStyle(key == cur and "gold" or "default")
	end
	op.scaleText:SetText(string.format("%d%%", math.floor(self:GetScale() * 100 + 0.5)))
	local inc = CSU.settings.includeBank
	op.bankBtn:SetLabel(inc and CSU:Color(CSU.COLORS.good, "Count bank items: ON") or "Count bank items: OFF")
	op.bankBtn:SetStyle(inc and "buy" or "default")
	if CSU.CastBar then
		local on = CSU.CastBar:IsEnabled()
		op.cbOpt:SetLabel(on and CSU:Color(CSU.COLORS.good, "Crafting bar: ON") or "Crafting bar: OFF")
		op.cbOpt:SetStyle(on and "buy" or "default")
		op.cbText:SetText(string.format("Bar %d%%", math.floor(CSU.CastBar:GetScale() * 100 + 0.5)))
	end
end

function UI:ApplyTheme()
	local th = GetTheme()
	-- Sync shared PAL table so flat buttons & hover handlers use active theme
	PAL.bg = th.bg
	PAL.header = th.header
	PAL.sidebar = th.sidebar
	PAL.card = th.card
	PAL.border = th.border
	PAL.borderGold = th.borderGold
	PAL.btnBg = th.btnBg
	PAL.btnHover = th.btnHover
	PAL.btnDisabled = th.btnDisabled

	local f = self.frame
	if f then
		local ins = th.inset or 1
		f:SetBackdrop(th.mainBackdrop)
		f:SetBackdropColor(unpack(th.bg))
		f:SetBackdropBorderColor(unpack(th.borderGold))

		if f.header then
			f.header:ClearAllPoints()
			f.header:SetPoint("TOPLEFT", ins, -ins)
			f.header:SetPoint("TOPRIGHT", -ins, -ins)
			f.header:SetBackdropColor(unpack(th.header))
		end
		if f.headerLine then
			f.headerLine:SetColorTexture(unpack(th.headerLine))
		end
		if f.sidebar then
			f.sidebar:ClearAllPoints()
			f.sidebar:SetPoint("TOPLEFT", ins, -(HEADER_HEIGHT + ins))
			f.sidebar:SetPoint("BOTTOMLEFT", ins, ins)
			f.sidebar:SetBackdropColor(unpack(th.sidebar))
		end
		if f.sideBorder then
			f.sideBorder:SetColorTexture(unpack(th.border))
		end
		if f.content then
			f.content:ClearAllPoints()
			f.content:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 0, 0)
			f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(BAGCOL_W + ins), ins)
		end
		if f.bestCard then
			f.bestCard:SetBackdrop(th.cardBackdrop)
			f.bestCard:SetBackdropColor(unpack(th.card))
			f.bestCard:SetBackdropBorderColor(unpack(th.cardBorder))
			if f.bestCard.calcCols then
				for _, col in ipairs(f.bestCard.calcCols) do
					col:SetBackdropColor(unpack(th.calcBg))
					col:SetBackdropBorderColor(unpack(th.calcBorder))
				end
			end
		end
		if f.divider then
			f.divider:SetColorTexture(unpack(th.border))
		end
		if f.sbBg then
			f.sbBg:SetColorTexture(unpack(th.barBg))
		end
		if f.thumb then
			f.thumb:SetColorTexture(unpack(th.thumb))
		end
		if f.themeBtn then
			f.themeBtn:SetLabel("Theme: " .. th.label)
		end
	end

	if self.bagPanel and f then
		local ins = th.inset or 1
		self.bagPanel:ClearAllPoints()
		self.bagPanel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -ins, -(HEADER_HEIGHT + ins))
		self.bagPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -ins, ins)
		self.bagPanel:SetBackdropColor(unpack(th.sidebar))
		if self.bagPanel.edge then
			self.bagPanel.edge:SetColorTexture(unpack(th.border))
		end
	end

	if f and f.optsPanel then
		f.optsPanel:SetBackdropColor(th.bg[1], th.bg[2], th.bg[3], 0.98)
		f.optsPanel:SetBackdropBorderColor(unpack(th.borderGold))
	end
	if f and f.profBar then
		f.profBar:SetBackdropColor(unpack(th.sidebar))
	end
	if self.compact then
		self.compact:SetBackdropColor(unpack(th.bg))
		self.compact:SetBackdropBorderColor(unpack(th.borderGold))
	end
	local q = self.queueFrame
	if q then
		q:SetBackdropColor(unpack(th.bg))
		q:SetBackdropBorderColor(unpack(th.borderGold))
		for _, r in ipairs(q.craftRows or {}) do
			if r.countEdit then
				r.countEdit:SetBackdropColor(unpack(th.calcBg))
				r.countEdit:SetBackdropBorderColor(unpack(th.border))
			end
		end
	end

	if self.routeBox then
		self.routeBox:SetBackdrop(th.cardBackdrop)
		self.routeBox:SetBackdropColor(unpack(th.card))
		self.routeBox:SetBackdropBorderColor(unpack(th.cardBorder))
	end

	for _, btn in ipairs(allFlatButtons) do
		if btn and btn._style then
			ApplyFlatStyle(btn, btn._style)
		end
	end

	if self.sidebarButtons then
		for _, pBtn in ipairs(self.sidebarButtons) do
			if pBtn.barBg then pBtn.barBg:SetColorTexture(unpack(th.barBg)) end
			if pBtn.accent then pBtn.accent:SetColorTexture(unpack(th.accent)) end
		end
	end

	if f and f:IsShown() then
		self:Refresh()
	end
end

---------------------------------------------------------------------------
-- Data Rendering
---------------------------------------------------------------------------

local mapIdCache = {}

-- uiMapID for a zone name (checks the Classic map number first, then searches)
local function FindMapID(zone)
	if not zone then return nil end
	if mapIdCache[zone] ~= nil then return mapIdCache[zone] or nil end
	local id
	local fallback = CSU.Calc.TRAIN_MAPS and CSU.Calc.TRAIN_MAPS[zone]
	if C_Map and C_Map.GetMapInfo then
		if fallback then
			local ok, info = pcall(C_Map.GetMapInfo, fallback)
			if ok and info and info.name == zone then id = fallback end
		end
		if not id then
			local function scan(a, b)
				for i = a, b do
					local ok, info = pcall(C_Map.GetMapInfo, i)
					if ok and info and info.name == zone then return i end
				end
			end
			id = scan(1400, 1500) or scan(1, 2600)
		end
	end
	id = id or fallback
	mapIdCache[zone] = id or false
	return id
end

function UI:ClearPin()
	if self.tomtomUid and _G.TomTom and _G.TomTom.RemoveWaypoint then
		pcall(_G.TomTom.RemoveWaypoint, _G.TomTom, self.tomtomUid)
	end
	self.tomtomUid = nil
	self.pinTrack = nil
	if CSU.Route and not CSU.Route.steps and CSU.Route.SaveActive then
		CSU.Route:SaveActive(nil)
	end
	if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
	if CSU.Arrow then CSU.Arrow:Clear() end
end

function UI:PinOnMap(place, title, quiet, track)
	if not (place and place.x and place.y) then
		CSU:Print("%s is %s, %s. No map pin for that spot.", place and place.npc or "?", place and place.town or "?", place and place.zone or "?")
		return
	end
	local m = place.map or FindMapID(place.zone)
	if not m then
		CSU:Print("Couldn't find %s on the map. %s is at %.1f, %.1f.", place.zone, place.npc, place.x, place.y)
		return
	end
	local x, y = place.x / 100, place.y / 100
	local tomtom = false
	if self.tomtomUid and _G.TomTom and _G.TomTom.RemoveWaypoint then
		pcall(_G.TomTom.RemoveWaypoint, _G.TomTom, self.tomtomUid)
		self.tomtomUid = nil
	end
	if not (CSU.Route and CSU.Route.steps) then
		self.pinTrack = track
		if CSU.Route and CSU.Route.SaveActive then
			CSU.Route:SaveActive("pin", place, title, track)
		end
	end
	-- our own arrow; TomTom (if installed) only adds its map/minimap pins, so you don't get two arrows
	local ownArrow = CSU.Arrow and CSU.Arrow:IsEnabled() and CSU.Arrow:SetTarget(m, x, y, title or place.npc)
	if _G.TomTom and _G.TomTom.AddWaypoint then
		local ok, uid = pcall(_G.TomTom.AddWaypoint, _G.TomTom, m, x, y, { title = title, persistent = false, minimap = true, world = true, crazy = not ownArrow })
		tomtom = ok
		if ok then self.tomtomUid = uid end
	end
	if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
		pcall(function()
			C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(m, x, y))
			if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
				C_SuperTrack.SetSuperTrackedUserWaypoint(true)
			end
		end)
	end
	if not quiet then
		CSU:Print("Marked on your map%s: %s, %s, %s (%.1f, %.1f).", ownArrow and ", follow the arrow" or (tomtom and " and TomTom" or ""), place.npc, place.town or "", place.zone or "", place.x, place.y)
	end
end

---------------------------------------------------------------------------
-- Route box: "Way to Trainer" + current step + "Step 2 of 5" + [X]
---------------------------------------------------------------------------
function UI:RenderRouteBox()
	local R = CSU.Route
	local box = self.routeBox
	if not (R and R.steps) then
		if box then box:Hide() end
		return
	end
	if not box then
		box = MakeFrame("Frame", "SkillUpProfitRouteBox", UIParent)
		box:SetSize(340, 84)
		box:SetFrameStrata("FULLSCREEN_DIALOG")
		box:SetFrameLevel(850)
		if box.SetToplevel then box:SetToplevel(true) end
		box:SetClampedToScreen(true)
		box:SetMovable(true)
		box:EnableMouse(true)
		box:RegisterForDrag("LeftButton")
		box:SetScript("OnDragStart", function(self)
			local af = CSU.Arrow and CSU.Arrow:GetFrame()
			if af and af:IsShown() then
				self._draggingArrow = true
				af:StartMoving()
			else
				self._draggingArrow = false
				self:StartMoving()
			end
		end)
		box:SetScript("OnDragStop", function(self)
			if self._draggingArrow then
				self._draggingArrow = false
				if CSU.Arrow and CSU.Arrow.StopMoving then CSU.Arrow:StopMoving() end
			else
				self:StopMovingOrSizing()
				local point, _, relPoint, x, y = self:GetPoint(1)
				CSU.settings.routeBoxPoint = { point, relPoint, x, y }
			end
		end)
		box:SetScript("OnHide", function(self)
			if self._draggingArrow then
				self._draggingArrow = false
				if CSU.Arrow and CSU.Arrow.StopMoving then CSU.Arrow:StopMoving() end
			else
				self:StopMovingOrSizing()
			end
		end)
		local th = GetTheme()
		box:SetBackdrop(th.cardBackdrop)
		box:SetBackdropColor(unpack(th.card))
		box:SetBackdropBorderColor(unpack(th.cardBorder))

		local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		title:SetPoint("TOPLEFT", 10, -8)
		title:SetPoint("TOPRIGHT", -34, -8)
		title:SetJustifyH("LEFT")
		if title.SetWordWrap then title:SetWordWrap(false) end
		box.title = title

		local close = MakeFlatButton(box, 20, 20, "X", "default")
		close:SetPoint("TOPRIGHT", -6, -5)
		close:SetScript("OnClick", function() CSU.Route:Stop() end)
		close._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("Stop the route", 1, 0.82, 0)
			GameTooltip:Show()
		end

		local step = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		step:SetPoint("TOPLEFT", 10, -26)
		step:SetPoint("TOPRIGHT", -10, -26)
		step:SetJustifyH("LEFT")
		if step.SetWordWrap then step:SetWordWrap(true) end
		box.step = step

		local count = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		count:SetPoint("BOTTOMLEFT", 10, 8)
		count:SetTextColor(0.65, 0.70, 0.78)
		box.count = count
		self.routeBox = box
		box:SetScale(self:GetScale())
	end
	local s = R.steps[R.index]
	box.title:SetText(CSU:Color(CSU.COLORS.title, "Way to " .. (R.place and R.place.npc or "trainer")))
	if R.done then
		box.step:SetText(CSU:Color(CSU.COLORS.good, "You're there! Talk to " .. (R.place and R.place.npc or "the trainer") .. "."))
	else
		box.step:SetText(s and s.text or "")
	end
	box.count:SetText(string.format("Step %d of %d", R.index, #R.steps))
	-- Dock directly under the arrow when the arrow is visible; otherwise stand on its own.
	local af = CSU.Arrow and CSU.Arrow:GetFrame()
	box:ClearAllPoints()
	if af and af:IsShown() then
		box:SetPoint("TOP", af, "BOTTOM", 0, -2)
		if CSU.Arrow.SetTitleShown then CSU.Arrow:SetTitleShown(false) end
	else
		local pt = CSU.settings.routeBoxPoint or CSU.settings.arrowPoint
		if type(pt) == "table" then
			box:SetPoint(pt[1] or "CENTER", UIParent, pt[2] or "CENTER", pt[3] or 0, pt[4] or 0)
		else
			box:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		end
	end
	box:Show()
end

function UI:RenderTrainBanner(prof)
	local f = self.frame
	local b = f.trainBanner
	local advice
	if prof then
		local live = CSU.Calc.GetLiveProfessions()[prof.name]
		local skill = live and live.skillLevel or prof.skillLevel
		local maxS = live and live.maxSkillLevel or prof.maxSkillLevel
		advice = CSU.Calc:GetTrainingAdvice(prof.name, skill, maxS)
		if advice then advice.skill, advice.max = skill, maxS end
	end
	local y = -72
	if advice then
		local txt = advice.text
		if advice.capped and advice.canLearn then
			txt = CSU:Color(CSU.COLORS.bad, string.format("Stuck at %d/%d! ", advice.skill, advice.max)) .. txt
			b:SetBackdropColor(0.28, 0.08, 0.06, 1)
			b:SetBackdropBorderColor(0.85, 0.30, 0.22, 1)
		elseif advice.canLearn then
			b:SetBackdropColor(0.26, 0.17, 0.04, 1)
			b:SetBackdropBorderColor(0.90, 0.62, 0.20, 1)
		else
			b:SetBackdropColor(0.07, 0.12, 0.20, 1)
			b:SetBackdropBorderColor(0.30, 0.50, 0.80, 1)
		end
		b.text:SetText(txt)
		local pl = advice.place
		b.mapBtn.place = pl
		b.mapBtn.title = pl and string.format("%s (%s %s)", pl.npc, advice.rank, prof.name) or nil
		b.mapBtn.track = pl and { prof = prof.name, cap = advice.cap } or nil
		b.mapBtn:SetShown(pl ~= nil and pl.x ~= nil)
		b:Show()
		y = -110
	else
		b:Hide()
	end
	self:ApplyLayout(y ~= -72)
end

function UI.GetBagState()
	if CSU.settings.bagOnly then return "only" end
	if CSU.settings.subtractBags then return "on" end
	return "off"
end

-- Recipes with group header rows (Chest, Legs, Potion...) when grouping is on.
-- Normal mode: groups A to Z. Ranked modes: the group with the best recipe first, ranking kept inside.
local function BuildDisplayList(list, mode)
	if CSU.settings.groupByType == false then return list end
	local groups, order = {}, {}
	for _, e in ipairs(list) do
		local cat = CSU.Calc:GetCategory(e.outputItemID, e.name)
		local g = groups[cat]
		if not g then
			g = { name = cat, items = {} }
			groups[cat] = g
			table.insert(order, g)
		end
		table.insert(g.items, e)
	end
	if mode == "normal" then
		table.sort(order, function(a, b) return a.name < b.name end)
	end
	local collapsed = CSU.settings.collapsed or {}
	local out = {}
	for _, g in ipairs(order) do
		table.insert(out, { isHeader = true, group = g.name, count = #g.items, collapsed = collapsed[g.name] })
		if not collapsed[g.name] then
			for _, e in ipairs(g.items) do table.insert(out, e) end
		end
	end
	return out
end

-- Fills one of the three number boxes. lines = { {label, value}, ... }
local function FillCalcCol(col, title, lines)
	col.title:SetText(CSU:Color("8a93a6", title))
	for i, l in ipairs(col.lines) do
		local d = lines and lines[i]
		l.label:SetText(d and d[1] or "")
		l.value:SetText(d and d[2] or "")
	end
end

local function FindSelectedEntry(list)
	if UI.selectedRecipeID then
		for _, e in ipairs(list) do
			if e.recipeID == UI.selectedRecipeID then
				return e
			end
		end
	end
	return list[1]
end

-- Nothing left to buy: say where the mats are (bags, mailbox, bank)
local function HaveLabel(itemID, required)
	local bags = CSU:GetBagCount(itemID)
	required = required or 0
	if bags >= required then return "In Bags" end
	local mail = CSU:GetIncoming(itemID)
	local bank = CSU.GetBankIncluded and CSU:GetBankIncluded(itemID) or 0
	local parts = {}
	if bags > 0 then table.insert(parts, "Bags") end
	if mail > 0 then table.insert(parts, "Mail") end
	if bank > 0 and bags + mail < required then table.insert(parts, "Bank") end
	if #parts == 1 then return "In " .. parts[1] end
	if #parts == 0 then return "In Bags" end
	return table.concat(parts, " + ")
end

local function ConfigureBuyButton(btn, itemID, needQty, source, required)
	btn.itemID = itemID
	btn.qty = needQty

	if needQty <= 0 then
		local where = HaveLabel(itemID, required)
		btn:SetLabel(CSU:Color(where == "In Bags" and CSU.COLORS.good or CSU.COLORS.vendor, where))
		btn:SetEnabledStyled(false, "default")
		return
	end

	if CSU.Buyer:CanBuyFromMerchant(itemID) then
		btn:SetLabel("Buy " .. needQty .. " (V)")
		btn:SetEnabledStyled(true, "vendor")
	elseif CSU.Prices.ahOpen then
		local state, total, got = CSU.Buyer:GetState(itemID, needQty)
		if state == "buy" then
			btn:SetLabel("Buy " .. math.min(got, needQty))
			btn:SetEnabledStyled(true, "buy")
		elseif state == "scanning" then
			btn:SetLabel("Scanning...")
			btn:SetEnabledStyled(true, "default")
		elseif state == "buying" then
			btn:SetLabel("Buying...")
			btn:SetEnabledStyled(true, "default")
		elseif state == "confirm" then
			btn:SetLabel("Confirm " .. (got or needQty))
			btn:SetEnabledStyled(true, "buy")
		elseif state == "none" then
			btn:SetLabel("None listed")
			btn:SetEnabledStyled(true, "default")
		else
			btn:SetLabel("Scan AH")
			btn:SetEnabledStyled(true, "gold")
		end
	else
		-- AH not open: still Scan AH (a click says to open the AH); vendor mats are marked "Vendor" by the name
		btn:SetLabel("Scan AH")
		btn:SetEnabledStyled(true, "default")
	end
end

function UI:RenderSidebar(activeProfName)
	local profs = CSU.Calc:GetSidebarProfessions()
	for i = 1, MAX_SIDEBAR_PROFS do
		local btn = self.sidebarButtons[i]
		local p = profs[i]
		btn.profData = p
		if p then
			local isActive = (activeProfName ~= nil and p.name == activeProfName)
			btn._active = isActive
			btn.icon:SetTexture(p.icon or 134400)
			btn.nameFS:SetText(p.name)

			local adv = CSU.Calc:GetTrainingAdvice(p.name, p.skillLevel, p.maxSkillLevel)
			btn.advice = adv
			local trainTag = ""
			if adv and adv.canLearn then
				trainTag = "  " .. CSU:Color(adv.capped and CSU.COLORS.bad or CSU.COLORS.warn, "Train!")
				UI.trainNoted = UI.trainNoted or {}
				local key = p.name .. adv.rank
				if not UI.trainNoted[key] then
					UI.trainNoted[key] = true
					CSU:Print(adv.text)
				end
			end
			if p.scanned then
				btn.skillFS:SetText(string.format("%d / %d", p.skillLevel or 0, p.maxSkillLevel or 0) .. trainTag)
				btn.skillFS:SetTextColor(isActive and 0.95 or 0.65, isActive and 0.85 or 0.70, isActive and 0.45 or 0.78)
			else
				btn.skillFS:SetText(string.format("%d/%d  |cff7a8290(open)|r", p.skillLevel or 0, p.maxSkillLevel or 0) .. trainTag)
			end

			local pct = 0
			if p.maxSkillLevel and p.maxSkillLevel > 0 then
				pct = math.max(0.02, math.min(1, (p.skillLevel or 0) / p.maxSkillLevel))
			end
			local barW = math.max(1, (SIDEBAR_WIDTH - 30) * pct)
			btn.barFill:SetWidth(barW)

			local th = GetTheme()
			btn.barBg:SetColorTexture(unpack(th.barBg))
			btn.accent:SetColorTexture(unpack(th.accent))
			if isActive then
				btn:SetBackdropColor(unpack(th.profActiveBg))
				btn:SetBackdropBorderColor(unpack(th.profActiveBorder))
				btn.nameFS:SetTextColor(1.0, 0.92, 0.60)
				btn.accent:Show()
				btn.barFill:SetColorTexture(unpack(th.barFillActive))
			else
				btn:SetBackdropColor(unpack(th.profIdleBg))
				btn:SetBackdropBorderColor(unpack(th.profIdleBorder))
				btn.nameFS:SetTextColor(p.scanned and 0.85 or 0.52, p.scanned and 0.88 or 0.55, p.scanned and 0.92 or 0.60)
				btn.accent:Hide()
				btn.barFill:SetColorTexture(unpack(th.barFillIdle))
			end
			btn:Show()
		else
			btn:Hide()
		end
	end

	local tabs = self.frame.profTabs
	if tabs then
		for i, t in ipairs(tabs) do
			local p = profs[i]
			if p then
				local sb = self.sidebarButtons[i]
				local train = (sb and type(sb.advice) == "table" and sb.advice.canLearn) and CSU:Color(CSU.COLORS.warn, "  Train!") or ""
				t:SetLabel(string.format("%s  %d/%d", p.name, p.skillLevel or 0, p.maxSkillLevel or 0) .. train)
				t:SetStyle((activeProfName ~= nil and p.name == activeProfName) and "gold" or "default")
				t:Show()
			else
				t:Hide()
			end
		end
	end

	local age = CSU.Prices:GetOwnScanAge()
	local count = CSU.Prices:GetOwnScanCount()
	if age then
		self.frame.sideFooter:SetText(string.format("AH Scan: %s\n%d items priced", CSU:FormatAge(age), count))
	else
		self.frame.sideFooter:SetText("No own AH scan yet.\nUsing fallback source.")
	end
end

function UI:RenderRows()
	if not self.frame then return end
	local list = self.displayList or self.currentList or {}
	local offset = self.scrollOffset or 0
	local selected = FindSelectedEntry(self.currentList or {})
	local selID = selected and selected.recipeID or nil

	-- Calculate how many rows actually fit in the current listContainer height
	local availH = self.frame.listContainer:GetHeight() or (VISIBLE_ROWS * ROW_HEIGHT)
	local fitRows = math.max(1, math.min(VISIBLE_ROWS, math.floor(availH / ROW_HEIGHT)))

	for i = 1, VISIBLE_ROWS do
		local row = self.rows[i]
		local item = (i <= fitRows) and list[offset + i] or nil
		local entry = (item and not item.isHeader) and item or nil
		row.entry = entry
		row.group = item and item.isHeader and item.group or nil
		if item and item.isHeader then
			row.icon:Hide()
			row.nameFS:ClearAllPoints()
			row.nameFS:SetPoint("LEFT", 6, 0)
			row.nameFS:SetPoint("RIGHT", row.diffFS, "LEFT", -8, 0)
			row.nameFS:SetText(CSU:Color(CSU.COLORS.title, (item.collapsed and "[+]  " or "[-]  ") .. item.group) .. CSU:Color(CSU.COLORS.muted, "  (" .. item.count .. ")"))
			row.diffFS:SetText("")
			row.costFS:SetText("")
			row.buyFS:SetText("")
			row.matsFS:SetText("")
			row.sel:Hide()
			row.selBar:Hide()
			row:Show()
		elseif entry then
			local ic = entry.icon or (entry.outputItemID and select(4, CSU:GetItemInfoSafe(entry.outputItemID))) or 134400
			row.icon:SetTexture(ic)
			row.icon:Show()
			row.nameFS:ClearAllPoints()
			row.nameFS:SetPoint("LEFT", 28, 0)
			row.nameFS:SetPoint("RIGHT", row.diffFS, "LEFT", -8, 0)

			local label, hex = CSU.Calc:GetDifficultyMeta(entry.difficulty)
			row.diffFS:SetText(CSU:Color(hex, label))

			local title = entry.name
			if entry.numSkillUps > 1 then
				title = title .. CSU:Color(CSU.COLORS.good, string.format(" (+%d)", entry.numSkillUps))
			end
			if UI.compactList then
				-- no TYPE column: the name shows the difficulty colour
				title = CSU:Color(hex, entry.name) .. title:sub(#entry.name + 1)
			end
			row.nameFS:SetText(title)

			local mode = CSU.Calc:GetMode()
			if mode == "earnback" or mode == "profit" then
				-- CRAFT COST | SELLS FOR | NET PER POINT or PROFIT
				row.costFS:SetText(entry.complete and CSU:FormatMoney(entry.costBasis) or CSU:Color(CSU.COLORS.bad, "No price"))
				row.buyFS:SetText(SellText(entry))
				if not entry.complete then
					row.matsFS:SetText(CSU:Color(CSU.COLORS.muted, "—"))
				elseif mode == "profit" then
					row.matsFS:SetText(SignedMoney(entry.profit))
				else
					row.matsFS:SetText(SignedMoney(-entry.netCostPerSkillUp))
				end
			else
				if entry.complete then
					row.costFS:SetText(CSU:FormatMoney(entry.totalCost))
					if entry.buyCost == 0 then
						row.buyFS:SetText(CSU:Color(CSU.COLORS.good, "In bags!"))
					else
						row.buyFS:SetText(CSU:FormatMoney(entry.buyCost))
					end
				else
					row.costFS:SetText(CSU:Color(CSU.COLORS.bad, "No price"))
					row.buyFS:SetText(CSU:Color(CSU.COLORS.muted, "—"))
				end

				local matCount = #(entry.reagents or {})
				if entry.bagCrafts then
					row.matsFS:SetText(CSU:Color(CSU.COLORS.good, "make " .. entry.bagCrafts))
				else
					row.matsFS:SetText(CSU:Color(CSU.COLORS.muted, string.format("%d mat%s", matCount, matCount == 1 and "" or "s")))
				end
			end
			if entry.bagCrafts and (mode == "earnback" or mode == "profit") then
				row.nameFS:SetText(title .. CSU:Color(CSU.COLORS.good, " x" .. entry.bagCrafts))
			end
			local isSel = (entry.recipeID == selID)
			row.sel:SetShown(isSel)
			row.selBar:SetShown(isSel)
			row:Show()
		else
			row:Hide()
		end
	end
end

-- The card's mat rows: each mat, and under a mat you make yourself, the mats it is made from
function UI.BuildMatLines(entry, crafts)
	crafts = crafts or 1
	local lines = {}
	for _, r in ipairs(entry and entry.reagents or {}) do
		local req = r.qty * crafts
		local ln = { kind = "mat", r = r, itemID = r.itemID, req = req }
		table.insert(lines, ln)
		if r.how == "make" and r.subs then
			local toMake = math.max(0, req - CSU:GetOwnedCount(r.itemID))
			local makerCrafts = math.ceil(toMake / (r.makeOutQty or 1))
			for _, sub in ipairs(r.subs) do
				table.insert(lines, { kind = "sub", itemID = sub.itemID, req = sub.qty * makerCrafts, parent = r })
			end
		end
	end
	return lines
end

function UI:RenderBuyCard(entry, isCheapest, prof)
	local card = self.frame.bestCard
	local crafts = math.max(1, self.craftCount or 1)
	card.countText:SetText("x" .. crafts)

	if not entry then
		card.itemHoverBtn.entry = nil
		if UI.GetLayout() == "classic" then card:SetHeight(76) end
		card.icon:Hide()
		card.bestTag:SetText(CSU:Color(CSU.COLORS.muted, "NO MATCHING RECIPES"))
		card.calcBox:Hide()
		if not prof then
			card.name:SetText(CSU:Color(CSU.COLORS.body, "Open any profession window once"))
			card.sub:SetText(CSU:Color(CSU.COLORS.muted, "Select a profession from the left sidebar after opening it."))
		else
			if CSU.Calc:IsBagMode() then
				card.name:SetText(CSU:Color(CSU.COLORS.body, "Nothing to make from your ticked bag items"))
				card.sub:SetText(CSU:Color(CSU.COLORS.muted, "Tick more items in Choose items, or untick Only bag items."))
			else
				card.name:SetText(CSU:Color(CSU.COLORS.body, "No recipes match your color filter"))
				card.sub:SetText(CSU:Color(CSU.COLORS.muted, "Enable Red / Orange, Yellow, or Green above."))
			end
		end
		card.btnToYellow:SetEnabledStyled(false, "default")
		card.btnToYellow:SetLabel("To Yellow")
		card.btnToGreen:SetEnabledStyled(false, "default")
		card.btnToGreen:SetLabel("To Green")
		card.buyNextBtn:SetEnabledStyled(false, "default")
		card.buyNextBtn.craftAllQty, card.buyNextBtn.craftAllRecipe = nil, nil
		card.buyNextBtn:SetLabel("Nothing to Buy")
		card.craftBtn:SetEnabledStyled(false, "default")
		card.craftBtn:SetLabel("Craft")
		for i = 1, MAX_BUY_ROWS do self.buyRows[i]:Hide() end
		return
	end

	-- Classic: same card height for every recipe (room for the most mats), so the list below never jumps
	-- when you click between a recipe with 3 mats and one with 4. Other layouts: the card has a fixed
	-- place and the money boxes are pinned, so nothing moves either.
	card.itemHoverBtn.entry = entry
	local layout = UI.GetLayout()
	local box = card.calcBox
	box:ClearAllPoints()
	local stackH = 3 * CALC_H + 12
	if layout == "classic" then
		local matsBottom = 70 + ((self.rowReserve or MIN_RESERVE_ROWS) * (BUY_ROW_HEIGHT + 2))
		card:SetHeight(matsBottom + 8 + CALC_H + 8)
		box:SetPoint("TOPLEFT", 8, -(matsBottom + 8))
		box:SetPoint("TOPRIGHT", -8, -(matsBottom + 8))
		box:SetHeight(CALC_H)
		local cw = ((card:GetWidth() or 600) - 16 - 12) / 3
		for c, col in ipairs(card.calcCols) do
			col:ClearAllPoints()
			col:SetPoint("TOPLEFT", box, "TOPLEFT", (c - 1) * (cw + 6), 0)
			col:SetSize(cw, CALC_H)
		end
	else
		if layout == "C" then
			box:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -70)
			box:SetSize(C_CALC_W, stackH)
		else
			box:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 8)
			box:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
			box:SetHeight(stackH)
		end
		for c, col in ipairs(card.calcCols) do
			col:ClearAllPoints()
			col:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -(c - 1) * (CALC_H + 6))
			col:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, -(c - 1) * (CALC_H + 6))
			col:SetHeight(CALC_H)
		end
	end
	box:Show()

	-- Update To Yellow / To Green buttons
	local tilY = entry.craftsToYellow or 0
	card.btnToYellow.targetCrafts = tilY
	card.btnToYellow.targetSkill = entry.yellowSkill
	card.btnToYellow.estimated = entry.thresholdEstimated
	if tilY > 0 then
		local pfx = entry.thresholdEstimated and "~" or ""
		card.btnToYellow:SetLabel(CSU:Color(CSU.COLORS.medium, string.format("To Yellow (%s%d)", pfx, tilY)))
		card.btnToYellow:SetEnabledStyled(true, "default")
	else
		card.btnToYellow:SetLabel("Is Yellow+")
		card.btnToYellow:SetEnabledStyled(false, "default")
	end

	local tilG = entry.craftsToGreen or 0
	card.btnToGreen.targetCrafts = tilG
	card.btnToGreen.targetSkill = entry.greenSkill
	card.btnToGreen.estimated = entry.thresholdEstimated
	if tilG > 0 then
		local pfx = entry.thresholdEstimated and "~" or ""
		card.btnToGreen:SetLabel(CSU:Color(CSU.COLORS.easy, string.format("To Green (%s%d)", pfx, tilG)))
		card.btnToGreen:SetEnabledStyled(true, "default")
	else
		card.btnToGreen:SetLabel("Is Green")
		card.btnToGreen:SetEnabledStyled(false, "default")
	end

	local label, hex = CSU.Calc:GetDifficultyMeta(entry.difficulty)
	card.icon:SetTexture(entry.icon or 134400)
	card.icon:Show()
	card.name:SetText(CSU:Color(hex, entry.name))

	local mode = CSU.Calc:GetMode()
	local bestWord = (mode == "profit" and "BEST PROFIT  ") or (mode == "earnback" and "BEST LEVEL + EARN  ") or (mode == "normal" and "RECIPE  ") or "CHEAPEST SKILL-UP  "
	local prefix = isCheapest and bestWord or "SELECTED RECIPE  "
	local tag = CSU:Color(CSU.COLORS.good, prefix) .. "[" .. CSU:Color(hex, label) .. "]"
	if entry.numSkillUps > 1 then
		tag = tag .. CSU:Color(CSU.COLORS.good, string.format("  +%d pts", entry.numSkillUps))
	end
	if entry.subPoints and entry.subPoints >= 0.05 then
		tag = tag .. CSU:Color(CSU.COLORS.good, string.format("  +%.1f pts from mats you make", entry.subPoints))
	end
	if entry.bagCrafts then
		tag = tag .. CSU:Color(CSU.COLORS.good, string.format("  can make %d from bags", entry.bagCrafts))
	end
	card.bestTag:SetText(tag)

	local batchTotal = 0
	local batchBuy = 0
	local bagUnits, bagValue, bagCost = 0, 0, 0
	local unitsBags, unitsMail, unitsBank = 0, 0, 0
	local vendorNeeded
	local function unitOf(r) return r.unitPrice end
	local batchComplete = true
	local craftableNow = math.huge
	local nextItemID, nextNeed

	local lines = UI.BuildMatLines(entry, crafts)
	-- rows that fit on the card (side layouts have a fixed card)
	local maxRows = MAX_BUY_ROWS
	local lay = UI.GetLayout()
	if lay ~= "classic" and lay ~= "C" then
		local h = tonumber(card:GetHeight()) or 0
		if h > 0 then
			maxRows = math.max(1, math.min(MAX_BUY_ROWS, math.floor((h - NARROW_MATS_TOP - (3 * CALC_H + 12) - 16) / (BUY_ROW_HEIGHT + 2))))
		end
	end
	local makeFirst -- a mat you make yourself that is missing in your bags: Craft makes it first
	local missingParts = {} -- what's missing in the bags for one craft (Craft (0) says it)

	for i = 1, MAX_BUY_ROWS do
		local rRow = self.buyRows[i]
		local ln = (i <= maxRows) and lines[i] or nil
		if ln then
			local itemID = ln.itemID
			local isSub = ln.kind == "sub"
			local r = ln.r
			local reqTotal = ln.req
			local inBags = CSU:GetBagCount(itemID)
			local coming = CSU:GetIncoming(itemID) -- bought on the AH, waiting in the mailbox
			local fromBank = CSU.GetBankIncluded and CSU:GetBankIncluded(itemID) or 0 -- Count bank: ON
			local have = inBags + coming + fromBank
			local unit
			if isSub then unit = CSU.Calc:MatCost(itemID) else unit = r.unitPrice end
			local making = (not isSub) and r.how == "make" and r.subs
			-- what the mats taken from your bags would sell for on the AH (vendor if no AH price)
			local fromBags = math.min(have, reqTotal)
			-- which part comes from where: bags first, then mailbox, then bank
			local b = math.min(inBags, reqTotal)
			local m = math.min(coming, reqTotal - b)
			unitsBags = unitsBags + b
			unitsMail = unitsMail + m
			unitsBank = unitsBank + math.max(0, fromBags - b - m)
			if fromBags > 0 then
				local _, _, ahNet, vend = CSU.Prices:GetSellValue(itemID)
				bagUnits = bagUnits + fromBags
				bagValue = bagValue + fromBags * (ahNet or vend or 0)
				if unit then bagCost = bagCost + fromBags * unit end
			end
			local need = math.max(0, reqTotal - have)
			if not isSub then
				local canMake = math.floor(inBags / math.max(1, r.qty)) -- you can only craft with what's in your bags
				if canMake < craftableNow then craftableNow = canMake end
				if inBags < r.qty then
					local where = ""
					if coming > 0 then where = " (in your mailbox)" elseif fromBank > 0 then where = " (in your bank)" end
					table.insert(missingParts, string.format("%dx %s%s", r.qty - inBags, r.name or "?", where))
				end
			end

			if unit then
				if not isSub then batchTotal = batchTotal + (unit * reqTotal) end
				-- what you still pay: bought mats, and the raw mats of what you make (not the made mat itself)
				if not making then batchBuy = batchBuy + (unit * need) end
			elseif not isSub then
				batchComplete = false
			end

			local _, _, _, itemIcon = CSU:GetItemInfoSafe(itemID)
			rRow.icon:SetTexture(itemIcon or 134400)
			rRow.icon:ClearAllPoints()
			rRow.icon:SetPoint("LEFT", isSub and 16 or 0, 0)
			rRow.itemHover.itemID = itemID

			local name
			if isSub then name = CSU:Color(CSU.COLORS.muted, "for it: ") .. CSU:GetItemName(itemID) else name = r.name end
			local srcTag = CSU.Calc:IsVendorMat(itemID) and CSU:Color(CSU.COLORS.vendor, "  Vendor") or ""
			rRow.nameFS:SetText(name .. srcTag)

			-- Buy / Make toggle
			local mb = rRow.modeBtn
			if not isSub and r.makeable then
				mb.itemID, mb.how = itemID, r.how
				mb.buyUnit, mb.makeUnit = r.buyUnit, r.makeUnit
				mb.makerProf = r.maker and r.maker.prof
				mb:SetLabel(r.how == "make" and "Make" or "Buy")
				mb:SetStyle(r.how == "make" and "gold" or "default")
				mb:Show()
			else
				mb:Hide()
			end

			if UI.narrowCard then
				rRow.countFS:SetText(string.format("%d/%d", have, reqTotal))
			else
				rRow.countFS:SetText(string.format("%d/%d (%s %d)", have, reqTotal, making and "make" or "buy", need))
			end
			if unit then
				rRow.costFS:SetText(need > 0 and CSU:FormatMoney(unit * need) or CSU:Color(CSU.COLORS.good, "0c"))
			else
				rRow.costFS:SetText(CSU:Color(CSU.COLORS.bad, "No price"))
			end

			rRow.searchBtn.itemID = itemID
			local bb = rRow.buyBtn
			bb.makeRecipeID, bb.makeQty = nil, nil
			if making then
				-- the Buy button becomes Make: makes the missing ones from their mats in your bags
				local fromRaw = math.huge
				for _, sub in ipairs(r.subs) do
					fromRaw = math.min(fromRaw, math.floor(CSU:GetBagCount(sub.itemID) / math.max(1, sub.qty)))
				end
				if fromRaw == math.huge then fromRaw = 0 end
				local outQ = r.makeOutQty or 1
				local wantCrafts = math.ceil(need / outQ)
				bb.itemID, bb.qty = itemID, 0
				if need <= 0 then
					ConfigureBuyButton(bb, itemID, 0, nil, reqTotal)
				else
					bb.makeRecipeID = r.maker.rec.id
					bb.makeQty = math.min(wantCrafts, fromRaw)
					bb:SetLabel("Make " .. need)
					bb:SetEnabledStyled(fromRaw > 0, fromRaw > 0 and "gold" or "default")
				end
				-- missing in bags for this craft: Craft makes them first
				local shortInBags = reqTotal - inBags
				if not makeFirst and shortInBags > 0 and fromRaw > 0 then
					makeFirst = { recipeID = r.maker.rec.id, qty = math.min(math.ceil(shortInBags / outQ), fromRaw), name = r.name }
				end
			else
				ConfigureBuyButton(bb, itemID, need, (not isSub) and r.source or nil, reqTotal)
				if need > 0 and CSU.Prices.ahOpen and not CSU.Buyer:CanBuyFromMerchant(itemID) then
					local st, exact, got = CSU.Buyer:GetState(itemID, need)
					if (st == "buy" or st == "confirm") and exact then
						-- real price of the first `need` on the AH right now
						local txt = CSU:FormatMoney(exact)
						if got and got < need then txt = txt .. CSU:Color(CSU.COLORS.warn, " (" .. got .. ")") end
						rRow.costFS:SetText(txt)
					elseif st == "none" then
						rRow.costFS:SetText(CSU:Color(CSU.COLORS.bad, "none on AH"))
					elseif unit then
						rRow.costFS:SetText(CSU:Color(CSU.COLORS.muted, "~") .. CSU:FormatMoney(unit * need))
					end
				end
				if not nextItemID and need > 0 then
					local src
					if isSub then src = select(2, CSU.Prices:GetUnitCost(itemID)) else src = r.source end
					if CSU.Buyer:CanBuyFromMerchant(itemID) or src ~= "vendor" or CSU.Prices.ahOpen then
						nextItemID, nextNeed = itemID, need
					else
						vendorNeeded = (vendorNeeded or 0) + 1
					end
				end
			end

			rRow:Show()
		else
			rRow:Hide()
		end
	end

	-- Craft button: enchants go on an item; mats you make come first; else craft
	if craftableNow == math.huge then craftableNow = 0 end
	local toCraft = math.min(crafts, craftableNow)
	local enchantInfoEarly = CSU.Enchant and CSU.Enchant:SlotFor(entry)
	local cb = card.craftBtn
	cb:SetWidth(84)
	cb.recipeID = entry.recipeID
	cb.craftQty = toCraft
	cb.craftAllQty = (not enchantInfoEarly) and craftableNow or nil
	cb.makeRecipeID, cb.makeQty, cb.makeName, cb.enchantEntry = nil, nil, nil, nil
	cb.missingText = #missingParts > 0 and ("Not enough materials in your bags: missing " .. table.concat(missingParts, ", ")) or nil
	local enchantInfo = CSU.Enchant and CSU.Enchant:SlotFor(entry)
	if enchantInfo then
		cb.enchantEntry = entry
		cb.craftQty = craftableNow
		cb:SetLabel(craftableNow > 0 and ("Enchant (" .. craftableNow .. ")") or "Enchant (0)")
		cb:SetEnabledStyled(true, craftableNow > 0 and "gold" or "default")
	elseif toCraft < crafts and makeFirst then
		cb.makeRecipeID, cb.makeQty, cb.makeName = makeFirst.recipeID, makeFirst.qty, makeFirst.name
		cb:SetLabel("Make x" .. makeFirst.qty)
		cb:SetEnabledStyled(true, "gold")
	elseif toCraft > 0 then
		cb:SetLabel("Craft x" .. toCraft)
		cb:SetEnabledStyled(true, "gold")
	else
		cb:SetLabel("Craft (0)")
		cb:SetEnabledStyled(true, "default") -- still clickable: says what's missing
	end

	-- Clear numbers for this many crafts
	local M = function(c) return CSU:FormatMoney(c) end
	local muted = function(t) return CSU:Color(CSU.COLORS.muted, t) end
	local cols = card.calcCols
	local function soft(t) return CSU:Color(CSU.COLORS.muted, t) end
	if batchComplete then
		-- MATERIALS
		local matLines = { { "All mats", M(batchTotal) } }
		if bagUnits > 0 then
			local whereParts = {}
			if unitsBags > 0 then table.insert(whereParts, string.format("bags %d", unitsBags)) end
			if unitsMail > 0 then table.insert(whereParts, string.format("mail %d", unitsMail)) end
			if unitsBank > 0 then table.insert(whereParts, string.format("bank %d", unitsBank)) end
			local whereLabel = (#whereParts == 1 and unitsBags > 0) and string.format("From bags (%d)", unitsBags)
				or ("You have: " .. table.concat(whereParts, ", "))
			table.insert(matLines, { whereLabel, M(bagCost) })
			table.insert(matLines, { soft("  they'd sell on AH for"), soft(M(bagValue)) })
		end
		table.insert(matLines, { "To buy", batchBuy > 0 and M(batchBuy) or CSU:Color(CSU.COLORS.good, "nothing") })
		FillCalcCol(cols[1], string.format("MATERIALS  x%d", crafts), matLines)

		-- CRAFTED ITEM
		local sold = (entry.sellTotal or 0) * crafts
		local outCount = math.floor((entry.outputQty or 1) * crafts + 0.5)
		if entry.sellUnit then
			local onAH = entry.sellChannel == "ah"
			local hours = CSU.Prices:GetAHHours()
			local deposit = 0
			if onAH then
				-- AH: price, minus the 5% cut, and the deposit you put up (back when it sells)
				local unitAH = CSU.Prices:GetAHPrice(entry.outputItemID) or 0
				local gross = math.max(sold, unitAH * outCount)
				deposit = CSU.Prices:GetDeposit(entry.outputItemID, outCount)
				FillCalcCol(cols[2], "CRAFTED ITEM  on the AH", {
					{ string.format("%dx %s", outCount, entry.name), "" },
					{ "AH price", M(gross) },
					{ "AH cut 5%", SignedMoney(sold - gross) },
					{ string.format("Deposit %dh %s", hours, soft("(back if sold)")), M(deposit) },
				})
			else
				FillCalcCol(cols[2], "CRAFTED ITEM  at a vendor", {
					{ string.format("%dx %s", outCount, entry.name), "" },
					{ "Vendor pays", M(sold) },
					{ soft("pays more than the AH"), "" },
				})
			end
			-- PROFIT: what you really end up with, after the AH cut
			local pl = { { onAH and string.format("Real profit (%dh AH)", hours) or "Real profit (vendor)", SignedMoney(sold - batchTotal) } }
			if bagUnits > 0 then
				table.insert(pl, { "Bag mats free", SignedMoney(sold - batchBuy) })
				table.insert(pl, { "vs selling bag mats", SignedMoney(sold - batchBuy - bagValue) })
			end
			if onAH then
				table.insert(pl, { soft("If it doesn't sell"), SignedMoney(-deposit) })
			end
			FillCalcCol(cols[3], "PROFIT", pl)
		else
			FillCalcCol(cols[2], "CRAFTED ITEM", {
				{ string.format("%dx %s", outCount, entry.name), "" },
				{ soft("Can't be sold"), "" },
				{ soft("(no AH or vendor price)"), "" },
			})
			FillCalcCol(cols[3], "PROFIT", { { soft("nothing to sell"), "" } })
		end
	else
		FillCalcCol(cols[1], "MATERIALS", { { CSU:Color(CSU.COLORS.warn, "Some prices missing"), "" }, { soft("Click Scan AH"), "" } })
		FillCalcCol(cols[2], "CRAFTED ITEM", {})
		FillCalcCol(cols[3], "PROFIT", {})
	end

	if batchComplete then
		card.sub:SetText(string.format("x%d crafts", crafts))
	else
		card.sub:SetText(CSU:Color(CSU.COLORS.warn, "Some reagent prices missing — run an AH scan"))
	end

	card.buyNextBtn.craftAllQty, card.buyNextBtn.craftAllRecipe = nil, nil
	if nextItemID and nextNeed and nextNeed > 0 then
		card.buyNextBtn.targetItemID = nextItemID
		card.buyNextBtn.targetQty = nextNeed

		if CSU.Buyer:CanBuyFromMerchant(nextItemID) then
			card.buyNextBtn:SetLabel("Buy " .. nextNeed .. "x (Vendor)")
			card.buyNextBtn:SetEnabledStyled(true, "vendor")
		elseif CSU.Prices.ahOpen then
			local state, total, got = CSU.Buyer:GetState(nextItemID, nextNeed)
			if state == "buy" then
				card.buyNextBtn:SetLabel("Buy " .. math.min(got, nextNeed) .. "x (" .. CSU:FormatMoney(total) .. ")")
				card.buyNextBtn:SetEnabledStyled(true, "buy")
			elseif state == "scanning" then
				card.buyNextBtn:SetLabel("Scanning...")
				card.buyNextBtn:SetEnabledStyled(true, "default")
			elseif state == "buying" then
				card.buyNextBtn:SetLabel("Buying...")
				card.buyNextBtn:SetEnabledStyled(true, "default")
			elseif state == "confirm" then
				card.buyNextBtn:SetLabel("Confirm (" .. CSU:FormatMoney(total) .. ")")
				card.buyNextBtn:SetEnabledStyled(true, "buy")
			elseif state == "none" then
				card.buyNextBtn:SetLabel("None listed - rescan")
				card.buyNextBtn:SetEnabledStyled(true, "default")
			else
				card.buyNextBtn:SetLabel("Scan AH: Next Mat")
				card.buyNextBtn:SetEnabledStyled(true, "gold")
			end
		else
			card.buyNextBtn:SetLabel("Open AH to Buy")
			card.buyNextBtn:SetEnabledStyled(true, "default")
		end
	else
		card.buyNextBtn.targetItemID = nil
		card.buyNextBtn.targetQty = nil
		local cb2 = card.craftBtn
		local allN = cb2 and tonumber(cb2.craftAllQty)
		if not vendorNeeded and allN and allN > (tonumber(cb2.craftQty) or 0)
			and type(cb2.makeRecipeID) ~= "number" and type(cb2.enchantEntry) ~= "table" then
			-- Craft all on the right (the gold button), Craft xN on the left
			local single = tonumber(cb2.craftQty) or 1
			cb2.craftQty = allN
			cb2:SetWidth(allN >= 100 and 118 or 108)
			cb2:SetLabel(string.format("Craft all (%d)", allN))
			cb2:SetEnabledStyled(true, "gold")
			card.buyNextBtn.craftAllQty, card.buyNextBtn.craftAllRecipe = single, cb2.recipeID
			card.buyNextBtn:SetLabel("Craft x" .. single)
			card.buyNextBtn:SetEnabledStyled(true, "default")
			return
		end
		if vendorNeeded then
			card.buyNextBtn:SetLabel(CSU:Color(CSU.COLORS.vendor, "Buy rest at a vendor"))
		else
			card.buyNextBtn:SetLabel(CSU:Color(CSU.COLORS.good, "All Mats Ready!"))
		end
		card.buyNextBtn:SetEnabledStyled(false, "default")
	end
end

---------------------------------------------------------------------------
-- Bag items panel (tick which bag materials may be used)
---------------------------------------------------------------------------

local BAG_ROWS = 40
local BAG_ROW_H = 22

function UI:CreateBagPanel()
	if self.bagPanel then return self.bagPanel end
	local main = self.frame
	-- Docked as the right column of the window, always open
	local p = MakeFrame("Frame", "CheapSkillUpBagPanel", main)
	p:SetFrameLevel(((main.bestCard and main.bestCard:GetFrameLevel()) or main:GetFrameLevel() or 1) + 30)
	p:SetWidth(BAGCOL_W)
	p:SetPoint("TOPRIGHT", main, "TOPRIGHT", -1, -(HEADER_HEIGHT + 1))
	p:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -1, 1)
	p:SetBackdrop(FLAT_BACKDROP)
	p:SetBackdropColor(unpack(PAL.sidebar))
	p:SetBackdropBorderColor(0, 0, 0, 0)
	local edge = p:CreateTexture(nil, "OVERLAY")
	edge:SetColorTexture(0.16, 0.18, 0.23, 1)
	edge:SetPoint("TOPLEFT", 0, 0)
	edge:SetPoint("BOTTOMLEFT", 0, 0)
	edge:SetWidth(1)
	p.edge = edge

	local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", 12, -12)
	title:SetText(CSU:Color("8a93a6", "BAG ITEMS"))
	if UI.frame then UI.frame.bagTitle = title end

	local help = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	help:SetPoint("TOPLEFT", 12, -34)
	help:SetPoint("TOPRIGHT", -12, -34)
	help:SetJustifyH("LEFT")
	help:SetTextColor(0.65, 0.70, 0.78)
	help:SetText("Mats in your bags (and bank, with Mats From Bank on) for this profession. Ticked ones are used by Only Bag Items.")

	local allBtn = MakeFlatButton(p, 60, 22, "All", "default")
	allBtn:SetPoint("TOPLEFT", 10, -78)
	allBtn:SetScript("OnClick", function() CSU.Calc:SetAllTicked(CSU.Calc.activeProfession, true) end)
	local noneBtn = MakeFlatButton(p, 60, 22, "None", "default")
	noneBtn:SetPoint("LEFT", allBtn, "RIGHT", 6, 0)
	noneBtn:SetScript("OnClick", function() CSU.Calc:SetAllTicked(CSU.Calc.activeProfession, false) end)

	local vend = MakeFlatButton(p, 228, 22, "", "default")
	vend:SetPoint("TOPLEFT", allBtn, "BOTTOMLEFT", 0, -6)
	local vbox = vend:CreateTexture(nil, "ARTWORK")
	vbox:SetSize(18, 18)
	vbox:SetPoint("LEFT", 4, 0)
	vbox:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
	local vtick = vend:CreateTexture(nil, "OVERLAY")
	vtick:SetAllPoints(vbox)
	vtick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	vend.tick = vtick
	vend:SetPoint("RIGHT", p, "RIGHT", -10, 0) -- as wide as the column, whatever its width
	vend.label:ClearAllPoints()
	vend.label:SetPoint("LEFT", vbox, "RIGHT", 4, 0)
	vend.label:SetPoint("RIGHT", vend, "RIGHT", -6, 0)
	vend.label:SetJustifyH("LEFT")
	vend:SetLabel("Use vendor mats too")
	vend._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Use vendor mats too", 1, 0.82, 0)
		GameTooltip:AddLine("With Only Bag Items on, recipes may still use mats any vendor sells (thread, salt, flux, dyes...). They're added to what you need to buy.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	vend:SetScript("OnClick", function()
		CSU.settings.bagVendor = not (CSU.settings.bagVendor ~= false)
		CSU:Fire("FILTER_CHANGED")
	end)
	p.vend = vend

	local list = CreateFrame("Frame", nil, p)
	list:SetPoint("TOPLEFT", 8, -136)
	list:SetPoint("BOTTOMRIGHT", -8, 30)
	list:EnableMouseWheel(true)
	p.list = list
	list:SetScript("OnMouseWheel", function(_, delta)
		local maxOff = math.max(0, #(UI.bagItems or {}) - UI:BagRowsFit())
		UI.bagOffset = math.max(0, math.min(maxOff, (UI.bagOffset or 0) - delta * 3))
		UI:RenderBagPanel(UI.bagItems)
	end)

	p.rows = {}
	for i = 1, BAG_ROWS do
		local r = CreateFrame("Button", nil, list)
		r:SetHeight(BAG_ROW_H)
		r:SetPoint("TOPLEFT", 0, -(i - 1) * BAG_ROW_H)
		r:SetPoint("TOPRIGHT", 0, -(i - 1) * BAG_ROW_H)
		local hl = r:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(0.85, 0.72, 0.30, 0.12)
		local cb = r:CreateTexture(nil, "ARTWORK")
		cb:SetSize(18, 18)
		cb:SetPoint("LEFT", 2, 0)
		cb:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
		local ck = r:CreateTexture(nil, "OVERLAY")
		ck:SetAllPoints(cb)
		ck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		r.tick = ck
		local ic = r:CreateTexture(nil, "ARTWORK")
		ic:SetSize(18, 18)
		ic:SetPoint("LEFT", cb, "RIGHT", 4, 0)
		ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		r.icon = ic
		local cnt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cnt:SetPoint("RIGHT", -4, 0)
		cnt:SetWidth(40)
		cnt:SetJustifyH("RIGHT")
		r.countFS = cnt
		local nm = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		nm:SetPoint("LEFT", ic, "RIGHT", 6, 0)
		nm:SetPoint("RIGHT", cnt, "LEFT", -4, 0)
		nm:SetJustifyH("LEFT")
		if nm.SetWordWrap then nm:SetWordWrap(false) end
		r.nameFS = nm
		r:SetScript("OnClick", function(self)
			if self.item then CSU.Calc:SetTicked(self.item.itemID, not self.item.ticked) end
		end)
		r:SetScript("OnEnter", function(self)
			if self.item and GameTooltip.SetItemByID then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetItemByID(self.item.itemID)
				GameTooltip:AddLine("Click to tick / untick.", 0.6, 0.6, 0.6)
				GameTooltip:Show()
			end
		end)
		r:SetScript("OnLeave", GameTooltip_Hide)
		r:Hide()
		p.rows[i] = r
	end

	local foot = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	foot:SetPoint("BOTTOMLEFT", 12, 10)
	foot:SetPoint("BOTTOMRIGHT", -12, 10)
	foot:SetJustifyH("LEFT")
	foot:SetTextColor(0.55, 0.60, 0.68)
	p.foot = foot

	self.bagPanel = p
	return p
end

function UI:BagRowsFit()
	local p = self.bagPanel
	local h = p and p.list and p.list:GetHeight() or (BAG_ROWS * BAG_ROW_H)
	return math.max(1, math.min(BAG_ROWS, math.floor((h or 0) / BAG_ROW_H)))
end

function UI:RenderBagPanel(items)
	self.bagItems = items or {}
	local p = self.bagPanel
	if not p or not p:IsShown() then return end
	p.vend.tick:SetShown(CSU.settings.bagVendor ~= false)
	local fit = self:BagRowsFit()
	local maxOff = math.max(0, #self.bagItems - fit)
	if (self.bagOffset or 0) > maxOff then self.bagOffset = maxOff end
	local off = self.bagOffset or 0
	for i = 1, BAG_ROWS do
		local r = p.rows[i]
		local it = (i <= fit) and self.bagItems[off + i] or nil
		r.item = it
		if it then
			r.tick:SetShown(it.ticked)
			r.icon:SetTexture(it.icon or 134400)
			local name = it.name
			if it.vendor then name = name .. CSU:Color(CSU.COLORS.vendor, " [V]") end
			r.nameFS:SetText(name)
			r.nameFS:SetAlpha(it.ticked and 1 or 0.5)
			r.countFS:SetText(tostring(it.count))
			r:Show()
		else
			r:Hide()
		end
	end
	if #self.bagItems == 0 then
		p.foot:SetText("No materials for this profession in your bags.")
	elseif #self.bagItems > fit then
		p.foot:SetText(string.format("%d items, scroll for more", #self.bagItems))
	else
		p.foot:SetText(string.format("%d items", #self.bagItems))
	end
end

function UI:Refresh()
	if not self.frame or not self.frame:IsShown() then return end
	local f = self.frame

	f.btnRed:UpdateVisual()
	f.btnYellow:UpdateVisual()
	f.btnGreen:UpdateVisual()

	local own = UI.UseOwnWindow()
	f.winBtn:SetLabel(own and "Blizzard Window" or "Window: Blizzard")
	f.winBtn:SetStyle(own and "gold" or "default")


	local mode = CSU.Calc:GetMode()
	f.modeBtn:SetLabel("Mode: " .. CSU.Calc.MODE_LABELS[mode])
	local showPills = (mode == "cheap" or mode == "earnback")
	f.btnRed:SetShown(showPills)
	f.btnYellow:SetShown(showPills)
	f.btnGreen:SetShown(showPills)
	f.modeHint:SetShown(not showPills)
	f.modeHint:SetText(mode == "normal" and "All known recipes, highest level first" or "All known recipes, most gold per craft first")
	local moneyMode = (mode == "earnback" or mode == "profit")
	f.hdrRecipe:UpdateLabel()
	f.hdrType:UpdateLabel()
	f.hdrCost:SetText((moneyMode and CSU.settings.subtractBags) and "TO BUY" or "CRAFT COST")
	if not moneyMode then
		f.hdrCol2:SetText("TO BUY")
		f.hdrCol3:SetText("MATS")
	elseif mode == "earnback" then
		f.hdrCol2:SetText("SELLS FOR")
		f.hdrCol3:SetText("PER POINT")
	else
		f.hdrCol2:SetText("SELLS FOR")
		f.hdrCol3:SetText("PROFIT")
	end

	local bst = UI.GetBagState()
	if bst == "only" then
		f.bagPill:SetLabel(CSU:Color(CSU.COLORS.good, "Only Bag Items"))
		f.bagPill:SetStyle("buy")
	elseif bst == "on" then
		f.bagPill:SetLabel(CSU:Color(CSU.COLORS.good, "Mats From Bags: ON"))
		f.bagPill:SetStyle("buy")
	else
		f.bagPill:SetLabel("Mats From Bags: OFF")
		f.bagPill:SetStyle("default")
	end
	if f.bankPill then
		local bk = CSU.settings.includeBank
		f.bankPill:SetLabel(bk and CSU:Color(CSU.COLORS.good, "Mats From Bank: ON") or "Mats From Bank: OFF")
		f.bankPill:SetStyle(bk and "buy" or "default")
	end
	if f.bagTitle then
		f.bagTitle:SetText(CSU:Color("8a93a6", CSU.settings.includeBank and "BAG + BANK ITEMS" or "BAG ITEMS"))
	end
	local grouped = CSU.settings.groupByType ~= false
	f.groupBtn:SetLabel(grouped and "Group by type: ON" or "Group by type: OFF")
	f.groupBtn:SetStyle(grouped and "buy" or "default")
	local ml = tonumber(CSU.settings.minLevel) or 0
	f.lvlText:SetText(ml > 0 and tostring(ml) or CSU:Color(CSU.COLORS.muted, "off"))

	local qn = CSU.Queue and CSU.Queue:Count() or 0
	f.queueHdr:SetLabel(qn > 0 and string.format("Queue (%d)", qn) or "Queue")
	f.queueHdr:SetStyle(qn > 0 and "gold" or "default")
	f.srcBtn:SetLabel(CSU.Prices:GetActiveSourceLabel())
	f.scanBtn:SetLabel(CSU.Prices.running and ("Stop (" .. (CSU.Prices.pages or 0) .. ")") or "Scan AH")

	local list, prof = CSU.Calc:GetRankedRecipes()
	if UI.sortCol then
		local col, asc = UI.sortCol, (UI.sortDir == "asc")
		local function val(e)
			if col == "name" then
				return (e.name or ""):lower()
			elseif col == "type" then
				local _, _, rank = CSU.Calc:GetDifficultyMeta(e.difficulty)
				return -(rank or 9) -- desc = Orange -> Yellow -> Green -> Gray
			elseif col == "cost" then
				return moneyMode and e.costBasis or e.totalCost
			elseif col == "col2" then
				return moneyMode and e.sellTotal or e.buyCost
			elseif col == "col3" then
				if mode == "profit" then return e.profit end
				if mode == "earnback" then return e.netCostPerSkillUp and -e.netCostPerSkillUp or nil end
				return e.bagCrafts or #(e.reagents or {})
			end
		end
		table.sort(list, function(a, b)
			local va, vb = val(a), val(b)
			if va == nil and vb == nil then return (a.name or "") < (b.name or "") end
			if va == nil then return false end
			if vb == nil then return true end
			if va ~= vb then
				if asc then return va < vb else return va > vb end
			end
			return (a.name or "") < (b.name or "")
		end)
	end
	self.currentList = list
	self.displayList = BuildDisplayList(list, mode)

	if prof then
		local staleNote = prof.stale and ("  " .. CSU:Color(CSU.COLORS.warn, "open " .. prof.name .. " to update")) or ""
		f.headerSub:SetText(string.format("%s  (%d / %d)", prof.name, prof.skillLevel or 0, prof.maxSkillLevel or 0) .. staleNote)
	else
		f.headerSub:SetText("Select a profession")
	end

	self:RenderSidebar(prof and prof.name or nil)
	self:RenderTrainBanner(prof)

	local bagItems = CSU.Calc:GetBagReagents(prof and prof.name or nil)
	self:RenderBagPanel(bagItems)
	if f.bestCard.tabBags then
		f.bestCard.tabBags:SetLabel(string.format("Bags (%d)", #(bagItems or {})))
	end

	local reserve = MIN_RESERVE_ROWS
	for _, e in ipairs(list) do
		local n = #(e.reagents or {})
		for _, r in ipairs(e.reagents or {}) do
			if r.how == "make" and r.subs then n = n + #r.subs end
		end
		if n > reserve then reserve = n end
	end
	self.rowReserve = math.min(MAX_BUY_ROWS, reserve)

	local selected = FindSelectedEntry(list)
	local isCheapest = (selected ~= nil and list[1] ~= nil and selected.recipeID == list[1].recipeID)
	self:RenderBuyCard(selected, isCheapest, prof)

	local availH = f.listContainer:GetHeight() or (VISIBLE_ROWS * ROW_HEIGHT)
	local fitRows = math.max(1, math.min(VISIBLE_ROWS, math.floor(availH / ROW_HEIGHT)))
	local maxScroll = math.max(0, #self.displayList - fitRows)
	f.scrollBar:SetMinMaxValues(0, maxScroll)
	if (self.scrollOffset or 0) > maxScroll then
		self.scrollOffset = maxScroll
		f.scrollBar:SetValue(maxScroll)
	end
	self:RenderRows()

	local priced = 0
	for _, e in ipairs(list) do
		if e.complete then priced = priced + 1 end
	end
	local foot = string.format("Showing %d recipes (%d priced)  |  Click any row to buy  |  Shift-click to open recipe", #list, priced)
	if UI.GetLayout() == "D" then
		local age = CSU.Prices:GetOwnScanAge()
		foot = foot .. "  |  " .. (age and ("AH scan " .. CSU:FormatAge(age)) or "No own AH scan yet")
	end
	f.footer:SetText(foot)
end

local refreshQueued = false
function UI:QueueRefresh()
	if not self.frame or not self.frame:IsShown() then return end
	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(0.1, function()
		refreshQueued = false
		UI:Refresh()
	end)
end

---------------------------------------------------------------------------
-- Profession window choice: CheapSkillUp (Blizzard's kept open but hidden) or Blizzard
---------------------------------------------------------------------------

local function UseOwnWindow()
	return not (CSU.settings and CSU.settings.craftWindow == "blizzard")
end
UI.UseOwnWindow = UseOwnWindow

local function IsBlizzardOpen()
	local pf = _G.ProfessionsFrame
	return pf ~= nil and pf:IsShown()
end

local function LoadBlizzardProfessions()
	if _G.ProfessionsFrame then return true end
	if ProfessionsFrame_LoadUI then
		pcall(ProfessionsFrame_LoadUI)
	elseif C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_Professions")
	end
	return _G.ProfessionsFrame ~= nil
end

local blizzHooked = false
local blizzScale

-- Crafting from the queue / Simple view opens the profession out of sight: no Blizzard
-- window and no big addon window popping up. Stays hidden until that profession closes.
local function Now() return GetTime and GetTime() or 0 end
local function IsQuiet()
	return (UI.quietUntil or 0) > Now()
end
function UI:BeginQuiet(seconds)
	local pf = _G.ProfessionsFrame
	if pf and pf:IsShown() and not pf._csuHidden then return end -- you have it open: leave it
	self.quietUntil = Now() + (seconds or 5)
end

-- Closing Blizzard's window closes the profession, so in CheapSkillUp mode it stays open
-- but is made invisible (alpha 0) and tiny (so it can't catch clicks). Switching back restores it.
function UI:ApplyBlizzardWindowMode()
	local pf = _G.ProfessionsFrame
	if not pf then return end
	if not blizzHooked then
		blizzHooked = true
		pf:HookScript("OnShow", function()
			UI:ApplyBlizzardWindowMode()
			if UseOwnWindow() and not pf._csuQuiet and not (UI.frame and UI.frame:IsShown()) then
				UI:Show(true)
			elseif not UseOwnWindow() and not pf._csuQuiet then
				-- only one of the two on screen: Blizzard's is up, so the addon's goes to its icon
				if (UI.frame and UI.frame:IsShown()) or (UI.compact and UI.compact:IsShown()) then UI:Minimize() end
			end
		end)
		pf:HookScript("OnHide", function()
			-- opened quietly for a craft: back to normal size while it's closed
			if pf._csuQuiet then
				pf._csuQuiet = nil
				if not UseOwnWindow() and pf._csuHidden then
					pcall(pf.SetScale, pf, blizzScale or 1)
					pcall(pf.SetAlpha, pf, 1)
					pf._csuHidden = nil
				end
			end
			UI:QueueRefresh()
		end)
	end
	if IsQuiet() and not pf._csuQuiet then
		pf._csuQuiet = true
	end
	if UseOwnWindow() or pf._csuQuiet then
		local sc = pf:GetScale()
		if sc and sc > 0.01 then blizzScale = sc end
		pcall(pf.SetAlpha, pf, 0)
		pcall(pf.SetScale, pf, 0.001)
		pf._csuHidden = true
	elseif pf._csuHidden then
		pcall(pf.SetScale, pf, blizzScale or 1)
		pcall(pf.SetAlpha, pf, 1)
		pf._csuHidden = nil
		-- it was laid out while tiny: Blizzard has to open it again to draw it right
		pf._csuNeedsReopen = pf:IsShown() and true or nil
		if UpdateUIPanelPositions then pcall(UpdateUIPanelPositions, pf) end
	end
	if UI.SyncSwapButtons then UI:SyncSwapButtons() end
end

local EnsureProfessionButton

function UI:SetWindowMode(m)
	CSU.settings.craftWindow = (m == "blizzard") and "blizzard" or "csu"
	self:ApplyBlizzardWindowMode()
	if UseOwnWindow() then
		CSU:Print("Profession window: SkillUp & Profit (Blizzard's window stays hidden).")
		if not (self.frame and self.frame:IsShown()) then
			self:Show(true)
		elseif not IsBlizzardOpen() then
			self:OpenProfession(CSU.Calc.activeProfession)
		end
	else
		CSU:Print("Profession window: Blizzard.")
		local pfr = _G.ProfessionsFrame
		if pfr and pfr._csuNeedsReopen and IsBlizzardOpen() and C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then
			-- close and open again at normal size, so Blizzard draws its window properly
			pfr._csuNeedsReopen = nil
			local name = CSU.Calc.activeProfession
			pcall(C_TradeSkillUI.CloseTradeSkill)
			if pfr:IsShown() and HideUIPanel then pcall(HideUIPanel, pfr) end
			C_Timer.After(0.2, function()
				if name then UI:OpenProfession(name) end
			end)
		elseif not IsBlizzardOpen() then
			local name = CSU.Calc.activeProfession
			if not name then
				local list = CSU.Calc:GetSidebarProfessions()
				name = list[1] and list[1].name
			end
			if name then self:OpenProfession(name) end
		end
		if EnsureProfessionButton then EnsureProfessionButton() end
		local pf = _G.ProfessionsFrame or _G.TradeSkillFrame or _G.CraftFrame
		if pf then
			pcall(pf.SetAlpha, pf, 1)
			if pf.Raise then pcall(pf.Raise, pf) end
		end
		if self.frame and self.frame:IsShown() then
			self:Minimize()
		end
	end
	self:Refresh()
end

function UI:GetSkillLine(profName)
	if not profName then return nil end
	local live = CSU.Calc.GetLiveProfessions and CSU.Calc.GetLiveProfessions()[profName]
	if live and live.skillLine and live.skillLine > 0 then return live.skillLine end
	local saved = CSU:GetCharDB().professions[profName]
	return saved and saved.professionID or nil
end

-- Opens a profession in the background so its recipes are read and Craft works.
function UI:OpenProfession(profName)
	local line = self:GetSkillLine(profName)
	local T = C_TradeSkillUI
	if not (line and T and T.OpenTradeSkill) then return false end
	LoadBlizzardProfessions()
	self:ApplyBlizzardWindowMode()
	local okCur, cur = pcall(T.GetBaseProfessionInfo)
	if okCur and cur and cur.professionID == line and T.IsTradeSkillReady and T.IsTradeSkillReady() then
		return true
	end
	local ok, opened = pcall(T.OpenTradeSkill, line)
	return ok and opened ~= false
end

function UI:Show(fromBlizzard)
	if not UseOwnWindow() and UI.BlizzardVisible and UI.BlizzardVisible() then
		-- only one of the two on screen: switching to this window hides Blizzard's
		CSU.settings.craftWindow = "csu"
		self:ApplyBlizzardWindowMode()
	end
	self:CreateMainFrame()
	self.minimized = false
	self:UpdateLauncher()
	CSU.Calc:ScanOpenProfession()
	self.frame:Show()
	self.frame:Raise()
	self:UpdateLauncher()
	if UseOwnWindow() and not fromBlizzard and not IsBlizzardOpen() then
		local name = CSU.Calc.activeProfession
		if not name then
			local list = CSU.Calc:GetSidebarProfessions()
			name = list[1] and list[1].name
		end
		if name then self:OpenProfession(name) end
	end
	self:Refresh()
	if UI.IsSimple() then self:SetViewMode("simple") end -- you use the small window
end

-- In CheapSkillUp mode the hidden profession closes together with this window.
function UI:OnMainHidden()
	if self.minimizing then return end -- hidden into the icon: keep the profession open
	self.minimized = false
	self:UpdateLauncher()
	if UseOwnWindow() and C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then
		local T = C_TradeSkillUI
		if IsBlizzardOpen() or (T.IsTradeSkillReady and T.IsTradeSkillReady()) then
			pcall(T.CloseTradeSkill)
		end
	end
end

function UI:Hide()
	if self.frame then self.frame:Hide() end
end

-- X: hide the window into the icon, keeping the profession open
function UI:Minimize()
	if not self.frame and not self.compact then return end
	self.minimizing = true
	if self.frame then self.frame:Hide() end
	if self.compact then self.compact:Hide() end
	self.minimizing = nil
	self.minimized = true
	if not self.launcherBtn and self.CreateLauncherButton then self.CreateLauncherButton(true) end
	if self.launcherBtn then self.launcherBtn:Show() end
	self:UpdateLauncher()
end

-- Floating icon glow: hover = 100%, window on screen = 50%, hidden into the icon or closed = 0%
function UI:UpdateLauncher()
	local b = self.launcherBtn
	if not (b and b.glow) then return end
	if b.pulse and b.pulse:IsPlaying() then b.pulse:Stop() end
	local onScreen = (self.frame and self.frame:IsShown()) or (self.compact and self.compact:IsShown())
	if b.hover then
		b.glow:SetAlpha(1)
	elseif onScreen then
		b.glow:SetAlpha(0.5)
	else
		b.glow:SetAlpha(0)
	end
end

function UI:Toggle()
	if (self.frame and self.frame:IsShown()) or (self.compact and self.compact:IsShown()) then
		self:Minimize()
	else
		self:Show()
	end
end

---------------------------------------------------------------------------
-- Quick-Swap Button on Blizzard Profession Windows (ProfessionsFrame / TradeSkillFrame / CraftFrame)
---------------------------------------------------------------------------

-- Blizzard's window counts as "on screen" only when it isn't hidden by the addon
local function BlizzardVisible(pf)
	pf = pf or _G.ProfessionsFrame
	return pf ~= nil and pf:IsShown() and not pf._csuHidden
end
UI.BlizzardVisible = BlizzardVisible

function UI:SyncSwapButtons()
	for _, pf in ipairs({ _G.ProfessionsFrame, _G.TradeSkillFrame, _G.CraftFrame }) do
		local b = pf and pf._csuSwapBtn
		if b then
			if BlizzardVisible(pf) and not (CSU.settings and CSU.settings.showProfButton == false) then b:Show() else b:Hide() end
		end
	end
end

local function AttachSwapButton(pf, btnName, ox, oy)
	if not pf or pf._csuSwapBtn then return end
	-- on UIParent, so Blizzard's own title bar can't cover it
	local btn = CreateFrame("Button", btnName, UIParent, "UIPanelButtonTemplate")
	btn:SetSize(128, 20)
	btn:SetText("SkillUp & Profit")
	btn:SetPoint("TOPRIGHT", pf, "TOPRIGHT", -28, -2)
	btn:SetFrameStrata("DIALOG")
	btn:SetFrameLevel(50)
	btn:SetScript("OnClick", function()
		UI:SetWindowMode("csu")
	end)
	pf:HookScript("OnShow", function() if C_Timer then C_Timer.After(0, function() UI:SyncSwapButtons() end) end UI:SyncSwapButtons() end)
	pf:HookScript("OnHide", function() UI:SyncSwapButtons() end)
	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("SkillUp & Profit Forever", 1, 0.82, 0)
		GameTooltip:AddLine("Switch to the SkillUp & Profit window. Blizzard's window goes away; the button in the addon window brings it back.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", GameTooltip_Hide)
	pf._csuSwapBtn = btn
	return btn
end

EnsureProfessionButton = function()
	if CSU.settings and not CSU.settings.showProfButton then return end
	if _G.ProfessionsFrame then
		local b = AttachSwapButton(_G.ProfessionsFrame, "CheapSkillUpProfButton", -34, -28)
		if b then UI.profToggleBtn = b end
	end
	if _G.TradeSkillFrame then
		AttachSwapButton(_G.TradeSkillFrame, "CheapSkillUpTradeSkillButton", -34, -28)
	end
	if _G.CraftFrame then
		AttachSwapButton(_G.CraftFrame, "CheapSkillUpCraftButton", -34, -28)
	end
	UI:SyncSwapButtons()
end

---------------------------------------------------------------------------
-- Floating Draggable Screen Button (starts in center of screen, drag anywhere!)
---------------------------------------------------------------------------

function UI:ResetPositions()
	if self.launcherBtn then
		self.launcherBtn:ClearAllPoints()
		self.launcherBtn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		self.launcherBtn:Show()
	end
	if self.frame then
		self.frame:ClearAllPoints()
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
	end
end

local function CreateLauncherButton(force)
	if UI.launcherBtn then return end
	if not force and CSU.settings and CSU.settings.showLauncherButton == false then return end

	local btn = CreateFrame("Button", "CheapSkillUpLauncherButton", UIParent)
	btn:SetSize(44, 44)
	btn:SetFrameStrata("FULLSCREEN_DIALOG")
	btn:SetFrameLevel(900)
	btn:SetMovable(true)
	btn:EnableMouse(true)
	btn:SetClampedToScreen(true)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:RegisterForDrag("LeftButton")

	if CSU.settings and type(CSU.settings.launcherPoint) == "table" then
		local p = CSU.settings.launcherPoint
		btn:SetPoint(p[1] or "CENTER", UIParent, p[2] or "CENTER", p[3] or 0, p[4] or 0)
	else
		btn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	-- Soft glow behind the icon: hover = faint, window open = bright, hidden-but-open = pulsing
	local glow = btn:CreateTexture(nil, "BACKGROUND")
	glow:SetPoint("CENTER")
	glow:SetSize(84, 84)
	glow:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Glow")
	glow:SetBlendMode("ADD")
	glow:SetVertexColor(1, 0.80, 0.30)
	glow:SetAlpha(0)
	btn.glow = glow
	local pulse = glow:CreateAnimationGroup()
	local fade = pulse:CreateAnimation("Alpha")
	fade:SetFromAlpha(0.25)
	fade:SetToAlpha(0.95)
	fade:SetDuration(0.9)
	fade:SetSmoothing("IN_OUT")
	pulse:SetLooping("BOUNCE")
	btn.pulse = pulse

	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Icon")
	btn.icon = icon

	-- Brighter icon on hover (the icon added on top of itself)
	local hl = btn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Icon")
	hl:SetBlendMode("ADD")
	hl:SetAlpha(0.25)
	btn.hl = hl

	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\AddOns\\SkillUpProfitForever\\Border")
	btn.border = border

	-- Hover makes the icon a bit bigger
	function btn:SetGrow(px)
		for _, t in ipairs({ self.icon, self.hl, self.border }) do
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", -px, px)
			t:SetPoint("BOTTOMRIGHT", px, -px)
		end
	end
	btn:SetGrow(0)

	btn:SetScript("OnDragStart", function(self)
		self._dragging = true
		self:StartMoving()
	end)

	btn:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint(1)
		if CSU.settings then
			CSU.settings.launcherPoint = { point, relPoint, x, y }
		end
		C_Timer.After(0.05, function() self._dragging = false end)
	end)

	btn:SetScript("OnClick", function(self, button)
		if self._dragging then return end
		if button == "RightButton" then
			if CSU.Prices and CSU.Prices.ahOpen then
				CSU.Prices:StartScan()
			elseif CSU.Calc then
				CSU.Calc:PrintBestToChat()
			end
		else
			UI:Toggle()
		end
	end)

	btn:SetScript("OnEnter", function(self)
		self.hover = true
		UI:UpdateLauncher()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("SkillUp & Profit Forever", 1, 0.82, 0)
		local age = CSU.Prices and CSU.Prices:GetOwnScanAge()
		GameTooltip:AddLine("AH Scan: " .. (age and CSU:FormatAge(age) or "None yet"), 0.8, 0.8, 0.8)
		GameTooltip:AddLine(" ")
		if UI.minimized then
			GameTooltip:AddLine("Still open, hidden here.", 1, 0.82, 0.25)
		end
		GameTooltip:AddLine("|cff4cd137Left-Click:|r Show / hide SkillUp & Profit", 1, 1, 1)
		GameTooltip:AddLine("|cffffd100Right-Click:|r Scan AH (at AH) or Print Best", 1, 1, 1)
		GameTooltip:AddLine("|cff9d9d9dDrag:|r Move icon anywhere on screen", 1, 1, 1)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function(self)
		self.hover = false
		UI:UpdateLauncher()
		GameTooltip_Hide()
	end)

	btn:Show()
	UI.launcherBtn = btn
	btn:SetScale(UI:GetScale())
	UI:UpdateLauncher()
end
UI.CreateLauncherButton = CreateLauncherButton

---------------------------------------------------------------------------
-- Craft Queue popup
---------------------------------------------------------------------------
local QW, QH = 580, 486
local Q_CRAFT_ROWS, Q_MAT_ROWS = 6, 9
local Q_ROW_H, Q_MAT_H = 24, 22
-- material columns (x from the left of a row, width)
local QC = { need = { 236, 44 }, bags = { 284, 44 }, bank = { 332, 44 }, mail = { 380, 40 }, buy = { 424, 40 } }

function UI:CreateQueueFrame()
	if self.queueFrame then return self.queueFrame end
	local q = MakeFrame("Frame", "SkillUpProfitQueue", UIParent)
	q:SetSize(QW, QH)
	q:SetFrameStrata("FULLSCREEN_DIALOG")
	q:SetFrameLevel(880)
	if q.SetToplevel then q:SetToplevel(true) end
	q:SetClampedToScreen(true)
	q:SetMovable(true)
	q:EnableMouse(true)
	q:RegisterForDrag("LeftButton")
	q:SetScript("OnDragStart", q.StartMoving)
	q:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint(1)
		CSU.settings.queuePoint = { point, relPoint, x, y }
	end)
	local pt = CSU.settings.queuePoint
	if type(pt) == "table" then
		q:SetPoint(pt[1] or "CENTER", UIParent, pt[2] or "CENTER", pt[3] or 0, pt[4] or 0)
	else
		q:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
	end
	q:SetBackdrop(FLAT_BACKDROP)
	q:SetBackdropColor(unpack(PAL.bg))
	q:SetBackdropBorderColor(unpack(PAL.borderGold))
	q:SetScale(self:GetScale())
	-- (not closed by Escape: it stays until you click its X)

	local title = q:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText(CSU:Color(CSU.COLORS.title, "Craft Queue"))
	local close = MakeFlatButton(q, 24, 22, "X", "default")
	close:SetPoint("TOPRIGHT", -8, -8)
	close:SetScript("OnClick", function()
		CSU.settings.queueShown = false -- you closed it: stays closed until you open it or queue something
		q:Hide()
	end)

	local function Label(text, y)
		local fs = q:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetPoint("TOPLEFT", 12, y)
		fs:SetText(CSU:Color("8a93a6", text))
		return fs
	end

	-- TO CRAFT
	Label("TO CRAFT", -40)
	q.empty = q:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	q.empty:SetPoint("TOPLEFT", 14, -62)
	q.empty:SetTextColor(0.65, 0.70, 0.78)
	q.empty:SetText("Nothing queued. Pick a recipe and click Queue on the recipe card.")
	q.craftRows = {}
	for i = 1, Q_CRAFT_ROWS do
		local r = CreateFrame("Frame", nil, q)
		r:SetHeight(Q_ROW_H)
		r:SetPoint("TOPLEFT", 10, -56 - (i - 1) * Q_ROW_H)
		r:SetPoint("TOPRIGHT", -10, -56 - (i - 1) * Q_ROW_H)
		local bg = r:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.035 or 0.012)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		r.icon:SetSize(18, 18)
		r.icon:SetPoint("LEFT", 4, 0)
		r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		-- amount: [-10][-5][-][ type it ][+][+5][+10]  [x]
		local function Change(d)
			local it = CSU.Queue:List()[r.index]
			if it then CSU.Queue:SetCount(r.index, math.max(1, it.count + d)) end
		end
		r.del = MakeFlatButton(r, 22, 20, "x", "default")
		r.del:SetPoint("RIGHT", -2, 0)
		r.del:SetScript("OnClick", function() CSU.Queue:Remove(r.index) end)
		r.del._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("Remove from the queue", 1, 0.82, 0)
			GameTooltip:Show()
		end
		local prev, gap = r.del, -8
		for _, d in ipairs({ 10, 5, 1 }) do
			local b = MakeFlatButton(r, d == 1 and 22 or 28, 20, d == 1 and "+" or ("+" .. d), "default")
			b:SetPoint("RIGHT", prev, "LEFT", gap, 0)
			b:SetScript("OnClick", function() Change(d) end)
			prev, gap = b, -2
		end
		local eb = MakeFrame("EditBox", nil, r)
		eb:SetSize(40, 20)
		eb:SetPoint("RIGHT", prev, "LEFT", -3, 0)
		eb:SetBackdrop(FLAT_BACKDROP)
		eb:SetBackdropColor(unpack((GetTheme()).calcBg))
		eb:SetBackdropBorderColor(unpack(PAL.border))
		eb:SetFontObject(GameFontHighlight)
		eb:SetJustifyH("CENTER")
		eb:SetAutoFocus(false)
		eb:SetNumeric(true)
		eb:SetMaxLetters(4)
		eb:SetTextInsets(2, 2, 0, 0)
		local function Apply(self)
			local n = tonumber(self:GetText() or "")
			local it = CSU.Queue:List()[r.index]
			if it and n and n > 0 and n ~= it.count then
				CSU.Queue:SetCount(r.index, n)
			else
				UI:RenderQueue()
			end
		end
		eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
		eb:SetScript("OnEscapePressed", function(self) self.cancel = true self:ClearFocus() end)
		eb:SetScript("OnEditFocusLost", function(self)
			if self.cancel then
				self.cancel = nil
				UI:RenderQueue()
			else
				Apply(self)
			end
		end)
		eb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("How many to craft", 1, 0.82, 0)
			GameTooltip:AddLine("Click and type a number, then Enter.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		eb:SetScript("OnLeave", GameTooltip_Hide)
		r.countEdit = eb
		prev, gap = eb, -3
		for _, d in ipairs({ 1, 5, 10 }) do
			local b = MakeFlatButton(r, d == 1 and 22 or 28, 20, d == 1 and "-" or ("-" .. d), "default")
			b:SetPoint("RIGHT", prev, "LEFT", gap, 0)
			b:SetScript("OnClick", function() Change(-d) end)
			prev, gap = b, -2
		end
		r.infoFS = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		r.infoFS:SetPoint("RIGHT", prev, "LEFT", -10, 0)
		r.infoFS:SetWidth(118)
		r.infoFS:SetJustifyH("RIGHT")
		r.nameFS = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		r.nameFS:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
		r.nameFS:SetPoint("RIGHT", r.infoFS, "LEFT", -6, 0)
		r.nameFS:SetJustifyH("LEFT")
		if r.nameFS.SetWordWrap then r.nameFS:SetWordWrap(false) end
		r:Hide()
		q.craftRows[i] = r
	end
	q.moreCraft = q:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	q.moreCraft:SetPoint("TOPLEFT", 14, -56 - Q_CRAFT_ROWS * Q_ROW_H - 2)
	q.moreCraft:SetTextColor(0.65, 0.70, 0.78)

	-- MATERIALS
	local my = -56 - Q_CRAFT_ROWS * Q_ROW_H - 22
	Label("MATERIALS", my)
	local hdr = CreateFrame("Frame", nil, q)
	hdr:SetHeight(16)
	hdr:SetPoint("TOPLEFT", 10, my - 16)
	hdr:SetPoint("TOPRIGHT", -10, my - 16)
	local function HdrCol(text, col, tip)
		local fs = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetPoint("LEFT", col[1], 0)
		fs:SetWidth(col[2])
		fs:SetJustifyH("RIGHT")
		fs:SetText(CSU:Color("7d8699", text))
		return fs
	end
	HdrCol("NEED", QC.need)
	HdrCol("BAGS", QC.bags)
	q.bankHdr = HdrCol("BANK", QC.bank)
	HdrCol("MAIL", QC.mail)
	HdrCol("BUY", QC.buy)
	q.matRows = {}
	for i = 1, Q_MAT_ROWS do
		local r = CreateFrame("Frame", nil, q)
		r:SetHeight(Q_MAT_H)
		r:SetPoint("TOPLEFT", 10, my - 34 - (i - 1) * Q_MAT_H)
		r:SetPoint("TOPRIGHT", -10, my - 34 - (i - 1) * Q_MAT_H)
		local bg = r:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.035 or 0.012)
		local hover = CreateFrame("Button", nil, r)
		hover:SetPoint("LEFT", 0, 0)
		hover:SetSize(QC.need[1] - 6, Q_MAT_H)
		hover:SetScript("OnEnter", function(self)
			if self.itemID and GameTooltip.SetItemByID then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				GameTooltip:SetItemByID(self.itemID)
				GameTooltip:Show()
			end
		end)
		hover:SetScript("OnLeave", GameTooltip_Hide)
		r.hover = hover
		r.icon = hover:CreateTexture(nil, "ARTWORK")
		r.icon:SetSize(16, 16)
		r.icon:SetPoint("LEFT", 4, 0)
		r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		r.nameFS = hover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		r.nameFS:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
		r.nameFS:SetPoint("RIGHT", 0, 0)
		r.nameFS:SetJustifyH("LEFT")
		if r.nameFS.SetWordWrap then r.nameFS:SetWordWrap(false) end
		r.cols = {}
		for key, col in pairs(QC) do
			local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			fs:SetPoint("LEFT", col[1], 0)
			fs:SetWidth(col[2])
			fs:SetJustifyH("RIGHT")
			r.cols[key] = fs
		end
		local buy = MakeFlatButton(r, 92, 20, "Buy", "buy")
		buy:SetPoint("RIGHT", 0, 0)
		buy:SetScript("OnClick", function(self)
			if self.itemID and self.qty and self.qty > 0 then
				CSU.Buyer:ClickBuy(self.itemID, self.qty)
				UI:RenderQueue()
			end
		end)
		r.buyBtn = buy
		r:Hide()
		q.matRows[i] = r
	end
	q.moreMats = q:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	q.moreMats:SetPoint("TOPLEFT", 14, my - 34 - Q_MAT_ROWS * Q_MAT_H - 2)
	q.moreMats:SetTextColor(0.65, 0.70, 0.78)

	-- bottom: totals and actions
	q.totalFS = q:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	q.totalFS:SetPoint("BOTTOMLEFT", 12, 40)
	q.totalFS:SetPoint("BOTTOMRIGHT", -12, 40)
	q.totalFS:SetJustifyH("LEFT")

	local bankBtn = MakeFlatButton(q, 150, 24, "Count bank: OFF", "default")
	bankBtn:SetPoint("BOTTOMLEFT", 10, 10)
	bankBtn:SetScript("OnClick", function()
		CSU:SetIncludeBank(not CSU.settings.includeBank)
	end)
	bankBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Count bank items", 1, 0.82, 0)
		GameTooltip:AddLine("ON: mats in your bank count as yours, so Buy asks only for the rest. When you open your bank, the mats the queue still needs go to your bags by themselves.", 1, 1, 1, true)
		if not CSU:HasSeenBank() then GameTooltip:AddLine("Visit your bank once so I know what's in it.", 1, 0.6, 0.2, true) end
		GameTooltip:Show()
	end
	q.bankBtn = bankBtn

	-- the bank is used by itself: at the banker, missing queue mats go to your bags
	local bankNote = q:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bankNote:SetPoint("LEFT", bankBtn, "RIGHT", 8, 0)
	bankNote:SetWidth(200)
	bankNote:SetJustifyH("LEFT")
	bankNote:SetTextColor(0.65, 0.70, 0.78)
	q.bankNote = bankNote

	local clearBtn = MakeFlatButton(q, 70, 24, "Clear", "default")
	clearBtn:SetPoint("BOTTOMRIGHT", -10, 10)
	clearBtn:SetScript("OnClick", function() CSU.Queue:Clear() end)

	local craftBtn = MakeFlatButton(q, 150, 24, "Craft all", "gold")
	craftBtn:SetPoint("RIGHT", clearBtn, "LEFT", -6, 0)
	craftBtn:SetScript("OnClick", function() UI:CraftQueueNext() end)
	craftBtn._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Craft all", 1, 0.82, 0)
		GameTooltip:AddLine("Crafts all of the first recipe in the queue that your bags have mats for. Each finished craft counts the queue down. With more recipes queued, click again for the next one.", 1, 1, 1, true)
		GameTooltip:AddLine("The profession opens out of sight: no Blizzard window and no big addon window.", 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
	end
	q.craftBtn = craftBtn

	q:SetScript("OnShow", function() UI:RenderQueue() end)
	q:Hide()
	self.queueFrame = q
	return q
end

function UI:ShowQueue()
	CSU.settings.queueShown = true
	local q = self:CreateQueueFrame()
	q:Show()
	q:Raise()
	self:RenderQueue()
end

function UI:ToggleQueue()
	local q = self:CreateQueueFrame()
	if q:IsShown() then
		CSU.settings.queueShown = false
		q:Hide()
	else
		self:ShowQueue()
	end
end

function UI:RenderQueue()
	local q = self.queueFrame
	if not (q and q:IsShown()) then return end
	local Qd = CSU.Queue
	local list = Qd:List()
	local incBank = CSU.settings.includeBank and true or false

	q.empty:SetShown(#list == 0)
	for i, r in ipairs(q.craftRows) do
		local it = list[i]
		r.index = i
		if it then
			local ic = it.icon or (it.outputItemID and select(4, CSU:GetItemInfoSafe(it.outputItemID))) or 134400
			r.icon:SetTexture(ic)
			r.nameFS:SetText(it.name or "?")
			if not r.countEdit:HasFocus() then r.countEdit:SetText(tostring(it.count)) end
			local can = Qd:CanMakeFromBags(it)
			local prof = it.prof and CSU:Color(CSU.COLORS.muted, it.prof .. "  ") or ""
			r.infoFS:SetText(prof .. (can >= it.count and CSU:Color(CSU.COLORS.good, "ready")
				or (can > 0 and CSU:Color(CSU.COLORS.warn, string.format("can make %d", can)) or CSU:Color(CSU.COLORS.muted, "need mats"))))
			r:Show()
		else
			r:Hide()
		end
	end
	q.moreCraft:SetText(#list > Q_CRAFT_ROWS and string.format("+%d more", #list - Q_CRAFT_ROWS) or "")

	local mats = Qd:Materials()
	local buyTotal, priced, unpriced = 0, 0, 0
	local bankTakeable = 0
	for _, m in ipairs(mats) do
		m.bags = CSU:GetBagCount(m.itemID)
		m.bank = CSU:GetBankCount(m.itemID)
		m.mail = CSU:GetIncoming(m.itemID)
		m.made = m.produced or 0 -- made by something earlier in the queue (bolts...)
		m.buy = math.max(0, m.need - m.bags - m.mail - (incBank and m.bank or 0) - m.made)
		local missing = m.need - m.bags - m.mail - m.made
		if missing > 0 and m.bank > 0 then bankTakeable = bankTakeable + math.min(missing, m.bank) end
		if m.buy > 0 then
			local unit = CSU.Prices:GetUnitCost(m.itemID)
			if unit then buyTotal = buyTotal + unit * m.buy priced = priced + 1 else unpriced = unpriced + 1 end
		end
	end
	local muted = CSU.COLORS.muted
	for i, r in ipairs(q.matRows) do
		local m = mats[i]
		if m then
			local _, _, _, ic = CSU:GetItemInfoSafe(m.itemID)
			r.icon:SetTexture(ic or 134400)
			r.hover.itemID = m.itemID
			r.nameFS:SetText((m.name or "?") .. (m.vendor and CSU:Color(CSU.COLORS.vendor, "  Vendor") or "")
				.. (m.made > 0 and CSU:Color(CSU.COLORS.muted, string.format("  (queue makes %d)", m.made)) or ""))
			r.cols.need:SetText(tostring(m.need))
			r.cols.bags:SetText(m.bags > 0 and tostring(m.bags) or CSU:Color(muted, "0"))
			local bankTxt = tostring(m.bank)
			if m.bank == 0 then bankTxt = CSU:Color(muted, "0")
			elseif not incBank then bankTxt = CSU:Color(muted, bankTxt) end
			r.cols.bank:SetText(bankTxt)
			r.cols.mail:SetText(m.mail > 0 and tostring(m.mail) or CSU:Color(muted, "0"))
			r.cols.buy:SetText(m.buy > 0 and CSU:Color(CSU.COLORS.warn, tostring(m.buy)) or CSU:Color(CSU.COLORS.good, "0"))
			ConfigureBuyButton(r.buyBtn, m.itemID, m.buy, nil, m.need)
			if m.buy <= 0 and m.made > 0 and m.need > m.bags + m.mail + (incBank and m.bank or 0) then
				r.buyBtn:SetLabel(CSU:Color(CSU.COLORS.vendor, "Made in queue"))
			end
			r:Show()
		else
			r:Hide()
		end
	end
	q.moreMats:SetText(#mats > Q_MAT_ROWS and string.format("+%d more materials", #mats - Q_MAT_ROWS) or "")
	q.bankHdr:SetText(CSU:Color(incBank and "7d8699" or "4f5666", "BANK"))

	local total
	if #mats == 0 then
		total = ""
	elseif priced == 0 and unpriced == 0 then
		total = CSU:Color(CSU.COLORS.good, "You have all the mats.")
	else
		total = "Left to buy: " .. CSU:FormatMoney(buyTotal)
		if unpriced > 0 then total = total .. CSU:Color(muted, string.format("  (+%d without a price, Scan AH)", unpriced)) end
	end
	if bankTakeable > 0 then
		total = total .. CSU:Color(CSU.COLORS.vendor, string.format("   |   %d waiting in the bank", bankTakeable))
	end
	q.totalFS:SetText(total)

	q.bankBtn:SetLabel(incBank and CSU:Color(CSU.COLORS.good, "Count bank: ON") or "Count bank: OFF")
	q.bankBtn:SetStyle(incBank and "buy" or "default")
	local note
	if Qd.moving then
		note = CSU:Color(CSU.COLORS.vendor, "Taking mats from the bank...")
	elseif Qd.bankOpen and Qd.waitingForRoom then
		note = CSU:Color(CSU.COLORS.warn, "Bags full: make room to take the rest")
	elseif bankTakeable > 0 then
		note = "Go to the bank: these are taken by themselves"
	elseif not CSU:HasSeenBank() then
		note = "Visit your bank once so I know what's in it"
	else
		note = ""
	end
	q.bankNote:SetText(note)
	q.craftBtn:SetEnabledStyled(#list > 0, #list > 0 and "gold" or "default")
	local nextN
	for _, it in ipairs(list) do
		local can = CSU.Queue:CanMakeFromBags(it)
		if can > 0 then nextN = math.min(can, it.count) break end
	end
	q.craftBtn:SetLabel(nextN and string.format("Craft all (%d)", nextN) or "Craft all")
end

-- Crafts the first queued item, as many as the bags allow
function UI:CraftQueueNext()
	local Qd = CSU.Queue
	local list = Qd:List()
	self:BeginQuiet(5)
	for _, it in ipairs(list) do
		local can = Qd:CanMakeFromBags(it)
		if can > 0 then
			local n = math.min(can, it.count)
			if CSU.Enchant and CSU.Enchant:SlotFor(it) then
				CSU.Enchant:Cast(it, OpenRecipeInProfessionFrame)
				return
			end
			if CraftRecipeFromWindow(it.recipeID, n) then
				CSU:Print("Crafting %dx %s.", n, it.name or "?")
			end
			return
		end
	end
	if #list > 0 then
		CSU:Print("Not enough mats in your bags for anything in the queue yet. Buy them, or take them from the bank or mailbox.")
	end
end

---------------------------------------------------------------------------
-- Simple view: a small window with just the recipes, how many you can make, and a
-- Craft / Enchant button on each. Toggle between Simple and Full; remembered.
---------------------------------------------------------------------------
local CW, CH = 290, 340
local C_ROW_H = 20
local DIFF_ORDER = { optimal = 1, medium = 2, easy = 3, trivial = 4 }

function UI.IsSimple()
	return CSU.settings and CSU.settings.viewMode == "simple"
end

-- how many you can make from what's in your bags (0 if a mat is switched off)
local function CanMakeFromBags(e)
	local n = math.huge
	for _, r in ipairs(e.reagents or {}) do
		if not CSU.Calc:IsTicked(r.itemID) then return 0 end
		n = math.min(n, math.floor(CSU:GetBagCount(r.itemID) / math.max(1, r.qty or 1)))
	end
	if n == math.huge then n = 0 end
	return n
end

local function MissingText(e)
	local parts, off = {}, {}
	for _, r in ipairs(e.reagents or {}) do
		if not CSU.Calc:IsTicked(r.itemID) then table.insert(off, r.name or "?") end
		local have = CSU:GetBagCount(r.itemID)
		if have < (r.qty or 1) then
			local where = ""
			if CSU:GetIncoming(r.itemID) > 0 then where = " (in your mailbox)"
			elseif (CSU.GetBankCount and CSU:GetBankCount(r.itemID) or 0) > 0 then where = " (in your bank)" end
			table.insert(parts, string.format("%dx %s%s", (r.qty or 1) - have, r.name or "?", where))
		end
	end
	if #off > 0 then return "You switched off: " .. table.concat(off, ", ") .. ". Tick it under the recipe to use it." end
	if #parts == 0 then return "Not enough materials in your bags." end
	return "Not enough materials in your bags: missing " .. table.concat(parts, ", ")
end

function UI:CreateCompact()
	if self.compact then return self.compact end
	local c = MakeFrame("Frame", "SkillUpProfitSimple", UIParent)
	local sz = CSU.settings.compactSize
	c:SetSize((type(sz) == "table" and sz[1]) or CW, (type(sz) == "table" and sz[2]) or CH)
	c:SetFrameStrata("FULLSCREEN_DIALOG")
	c:SetFrameLevel(820)
	if c.SetToplevel then c:SetToplevel(true) end
	c:SetClampedToScreen(true)
	c:SetMovable(true)
	c:SetResizable(true)
	if c.SetResizeBounds then c:SetResizeBounds(240, 180, 600, 1000) elseif c.SetMinResize then c:SetMinResize(240, 180) end
	c:EnableMouse(true)
	c:RegisterForDrag("LeftButton")
	c:SetScript("OnDragStart", c.StartMoving)
	c:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint(1)
		CSU.settings.compactPoint = { point, relPoint, x, y }
	end)
	local pt = CSU.settings.compactPoint
	if type(pt) == "table" then
		c:SetPoint(pt[1] or "CENTER", UIParent, pt[2] or "CENTER", pt[3] or 0, pt[4] or 0)
	else
		c:SetPoint("RIGHT", UIParent, "RIGHT", -260, 40)
	end
	c:SetBackdrop(FLAT_BACKDROP)
	c:SetBackdropColor(unpack(PAL.bg))
	c:SetBackdropBorderColor(unpack(PAL.borderGold))
	c:SetScale(self:GetScale())

	-- top: < Profession skill >   [Full] [x]
	local close = MakeFlatButton(c, 22, 20, "x", "default")
	close:SetPoint("TOPRIGHT", -6, -6)
	close:SetScript("OnClick", function() UI:Minimize() end)
	close._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Hide into the icon (stays open for crafting)", 1, 0.82, 0)
		GameTooltip:Show()
	end
	local full = MakeFlatButton(c, 44, 20, "Full", "gold")
	full:SetPoint("RIGHT", close, "LEFT", -4, 0)
	full:SetScript("OnClick", function() UI:SetViewMode("full") end)
	full._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Full view", 1, 0.82, 0)
		GameTooltip:AddLine("Back to the big window with prices, profit, buying and the queue.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	local prev = MakeFlatButton(c, 20, 20, "<", "default")
	prev:SetPoint("TOPLEFT", 6, -6)
	prev:SetScript("OnClick", function() UI:CompactSwitchProf(-1) end)
	local nextB = MakeFlatButton(c, 20, 20, ">", "default")
	nextB:SetPoint("RIGHT", full, "LEFT", -6, 0)
	nextB:SetScript("OnClick", function() UI:CompactSwitchProf(1) end)
	c.title = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	c.title:SetPoint("LEFT", prev, "RIGHT", 6, 0)
	c.title:SetPoint("RIGHT", nextB, "LEFT", -6, 0)
	c.title:SetJustifyH("CENTER")
	if c.title.SetWordWrap then c.title:SetWordWrap(false) end

	-- second line: filters (can make, colours) ; third line: search
	local only = MakeFlatButton(c, 74, 18, "Can make", "default")
	only:SetPoint("TOPLEFT", 6, -30)
	only:SetScript("OnClick", function()
		CSU.settings.compactOnly = not CSU.settings.compactOnly
		UI:RenderCompact()
	end)
	only._onEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Only what you can make", 1, 0.82, 0)
		GameTooltip:AddLine("Hide recipes you have no mats for in your bags.", 1, 1, 1, true)
		GameTooltip:Show()
	end
	c.only = only
	c.colorBtns = {}
	local COLORS = { { "optimal", "Orange" }, { "medium", "Yellow" }, { "easy", "Green" }, { "trivial", "Grey" } }
	local prevBtn = only
	for _, cd in ipairs(COLORS) do
		local key, label = cd[1], cd[2]
		local b = MakeFlatButton(c, 22, 18, "", "default")
		b:SetPoint("LEFT", prevBtn, "RIGHT", 3, 0)
		b:SetScript("OnClick", function()
			CSU.settings.compactHide = CSU.settings.compactHide or {}
			CSU.settings.compactHide[key] = not CSU.settings.compactHide[key] or nil
			UI:RenderCompact()
		end)
		b._onEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(label .. " recipes", 1, 0.82, 0)
			GameTooltip:AddLine("Click to show or hide them.", 1, 1, 1, true)
			GameTooltip:Show()
		end
		b.key = key
		c.colorBtns[key] = b
		prevBtn = b
	end
	c.hint = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	c.hint:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)
	c.hint:SetPoint("RIGHT", -8, 0)
	c.hint:SetJustifyH("RIGHT")
	c.hint:SetText("Shift: all")

	local search = MakeFrame("EditBox", nil, c)
	search:SetPoint("TOPLEFT", 6, -52)
	search:SetPoint("TOPRIGHT", -6, -52)
	search:SetHeight(18)
	search:SetBackdrop(FLAT_BACKDROP)
	search:SetBackdropColor(unpack((GetTheme()).calcBg))
	search:SetBackdropBorderColor(unpack(PAL.border))
	search:SetFontObject(GameFontHighlightSmall)
	search:SetAutoFocus(false)
	search:SetTextInsets(6, 6, 0, 0)
	search:SetScript("OnTextChanged", function(self)
		c.offset = 0
		UI:RenderCompact()
	end)
	search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
	search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	local ph = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ph:SetPoint("LEFT", 6, 0)
	ph:SetText("Search recipes...")
	search.placeholder = ph
	c.search = search

	-- list
	local list = CreateFrame("Frame", nil, c)
	list:SetPoint("TOPLEFT", 6, -76)
	list:SetPoint("BOTTOMRIGHT", -6, 18)
	c.list = list
	c.rows = {}
	c.offset = 0
	c:EnableMouseWheel(true)
	c:SetScript("OnMouseWheel", function(self, delta)
		self.offset = math.max(0, (self.offset or 0) - delta * 2)
		UI:RenderCompact()
	end)
	c.empty = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	c.empty:SetPoint("TOPLEFT", list, "TOPLEFT", 4, -6)
	c.empty:SetPoint("TOPRIGHT", list, "TOPRIGHT", -4, -6)
	c.empty:SetJustifyH("LEFT")
	c.empty:SetTextColor(0.7, 0.72, 0.76)
	c.foot = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	c.foot:SetPoint("BOTTOMLEFT", 8, 4)

	-- resize grip
	local grip = CreateFrame("Button", nil, c)
	grip:SetSize(14, 14)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetScript("OnMouseDown", function() c:StartSizing("BOTTOMRIGHT") end)
	grip:SetScript("OnMouseUp", function()
		c:StopMovingOrSizing()
		CSU.settings.compactSize = { math.floor(c:GetWidth() + 0.5), math.floor(c:GetHeight() + 0.5) }
		UI:RenderCompact()
	end)

	c:SetScript("OnShow", function() UI:RenderCompact() UI:UpdateLauncher() end)
	c:SetScript("OnHide", function() UI:UpdateLauncher() end)
	c:Hide()
	self.compact = c
	return c
end

local function CompactRow(c, i)
	local r = c.rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, c.list)
	r:SetHeight(C_ROW_H)
	r:SetPoint("TOPLEFT", c.list, "TOPLEFT", 0, -(i - 1) * C_ROW_H)
	r:SetPoint("TOPRIGHT", c.list, "TOPRIGHT", 0, -(i - 1) * C_ROW_H)
	r.bg = r:CreateTexture(nil, "BACKGROUND")
	r.bg:SetAllPoints()
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetSize(16, 16)
	r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	-- mat rows: tick to use / switch off this mat
	r.check = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
	r.check:SetSize(18, 18)
	r.check:SetPoint("LEFT", 14, 0)
	r.check:SetScript("OnClick", function(self)
		if r.itemID then
			CSU.Calc:SetTicked(r.itemID, self:GetChecked() and true or false)
			UI:RenderCompact()
			UI:QueueRefresh()
		end
	end)
	r.check:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Use this mat", 1, 0.82, 0)
		GameTooltip:AddLine("Untick to switch it off: recipes that need it show 0 and won't be crafted. Same as the tick boxes in the bag list.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	r.check:SetScript("OnLeave", GameTooltip_Hide)
	r.btn = MakeFlatButton(r, 64, 18, "Craft", "default")
	r.btn:SetPoint("RIGHT", 0, 0)
	r.btn:SetScript("OnClick", function(self)
		if r.kind == "mat" then
			if r.itemID and r.makeable then
				CSU.Calc:SetMatChoice(r.itemID, r.how == "make" and "buy" or "make")
			end
			return
		end
		local e = r.entry
		if not e then return end
		local can = CanMakeFromBags(e)
		if can <= 0 then
			CSU:ShowError(MissingText(e))
			return
		end
		UI:BeginQuiet(5)
		if CSU.Enchant and CSU.Enchant:SlotFor(e) then
			CSU.Enchant:Cast(e, OpenRecipeInProfessionFrame)
		else
			CraftRecipeFromWindow(e.recipeID, (IsShiftKeyDown and IsShiftKeyDown()) and can or 1)
		end
	end)
	r.count = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.count:SetPoint("RIGHT", r.btn, "LEFT", -6, 0)
	r.count:SetWidth(44)
	r.count:SetJustifyH("RIGHT")
	r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
	r.name:SetPoint("RIGHT", r.count, "LEFT", -4, 0)
	r.name:SetJustifyH("LEFT")
	if r.name.SetWordWrap then r.name:SetWordWrap(false) end
	-- click a recipe: show / hide its mats
	r:SetScript("OnClick", function(self)
		if self.kind ~= "recipe" or not self.entry then return end
		c.expanded = (c.expanded ~= self.entry.recipeID) and self.entry.recipeID or nil
		UI:RenderCompact()
	end)
	r:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		if self.kind == "mat" then
			if self.itemID and GameTooltip.SetItemByID then GameTooltip:SetItemByID(self.itemID) end
			GameTooltip:Show()
			return
		end
		local e = self.entry
		if not e then return end
		if e.outputItemID and GameTooltip.SetItemByID then
			GameTooltip:SetItemByID(e.outputItemID)
		else
			GameTooltip:AddLine(e.name or "?", 1, 0.82, 0)
		end
		GameTooltip:AddLine("Click to see its mats.", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", GameTooltip_Hide)
	c.rows[i] = r
	return r
end

local function SetupRecipeRow(r, e, i)
	r.kind, r.entry, r.itemID = "recipe", e, nil
	r.bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.035 or 0.012)
	r.check:Hide()
	r.icon:ClearAllPoints()
	r.icon:SetPoint("LEFT", 2, 0)
	r.icon:SetTexture(e.icon or 134400)
	local _, hex = CSU.Calc:GetDifficultyMeta(e.difficulty)
	local open = (UI.compact.expanded == e.recipeID)
	r.name:SetText((open and "- " or "+ ") .. CSU:Color(hex, e.name))
	local can = e._can
	r.count:SetText(can > 0 and CSU:Color(CSU.COLORS.good, "x" .. can) or CSU:Color(CSU.COLORS.muted, "0"))
	local isEnchant = CSU.Enchant and CSU.Enchant:SlotFor(e)
	r.btn:SetWidth(64)
	r.btn:SetLabel(isEnchant and "Enchant" or "Craft")
	r.btn:SetStyle(can > 0 and "gold" or "default")
	r.btn:Show()
end

local function SetupMatRow(r, rg)
	r.kind, r.entry, r.itemID = "mat", nil, rg.itemID
	r.makeable, r.how = rg.makeable, rg.how
	r.bg:SetColorTexture(0.95, 0.76, 0.25, 0.05)
	r.check:Show()
	local ticked = CSU.Calc:IsTicked(rg.itemID)
	r.check:SetChecked(ticked)
	r.icon:ClearAllPoints()
	r.icon:SetPoint("LEFT", r.check, "RIGHT", 2, 0)
	local _, _, _, ic = CSU:GetItemInfoSafe(rg.itemID)
	r.icon:SetTexture(ic or 134400)
	local name = rg.name or CSU:GetItemName(rg.itemID)
	r.name:SetText(ticked and name or CSU:Color(CSU.COLORS.muted, name .. " (off)"))
	local have = CSU:GetBagCount(rg.itemID)
	local need = rg.qty or 1
	r.count:SetText(CSU:Color(have >= need and CSU.COLORS.good or CSU.COLORS.bad, string.format("%d/%d", have, need)))
	if rg.makeable then
		r.btn:SetWidth(44)
		r.btn:SetLabel(rg.how == "make" and "Make" or "Buy")
		r.btn:SetStyle(rg.how == "make" and "gold" or "default")
		r.btn:Show()
	else
		r.btn:Hide()
	end
end

function UI:RenderCompact()
	local c = self.compact
	if not (c and c:IsShown()) then return end
	local profName = CSU.Calc.activeProfession
	if not profName then
		local profs = CSU.Calc:GetSidebarProfessions()
		profName = profs[1] and profs[1].name
	end
	local list, prof = {}, nil
	if profName then list, prof = CSU.Calc:GetRankedRecipes(profName, "normal") end
	if prof then
		c.title:SetText(string.format("%s  %s", CSU:Color(CSU.COLORS.title, prof.name),
			CSU:Color(CSU.COLORS.muted, string.format("%d/%d", prof.skillLevel or 0, prof.maxSkillLevel or 0))))
	else
		c.title:SetText(CSU:Color(CSU.COLORS.muted, "No profession yet"))
	end

	-- filters
	local only = CSU.settings.compactOnly
	local hide = CSU.settings.compactHide or {}
	local text = c.search:GetText()
	if type(text) ~= "string" then text = "" end
	c.search.placeholder:SetShown(text == "")
	local q = text:lower()
	local skill = prof and prof.skillLevel or 0
	local recipes = {}
	for _, e in ipairs(list or {}) do
		e._can = CanMakeFromBags(e)
		local keep = not hide[e.difficulty]
		if keep and only and e._can <= 0 then keep = false end
		if keep and q ~= "" and not (e.name or ""):lower():find(q, 1, true) then keep = false end
		if keep then
			e._lvl = CSU.Thresholds and CSU.Thresholds:LevelOf(e.recipeID, e.name, skill, e.difficulty) or 0
			table.insert(recipes, e)
		end
	end
	-- like Blizzard: highest level first, then by colour, then A to Z
	table.sort(recipes, function(a, b)
		if a._lvl ~= b._lvl then return a._lvl > b._lvl end
		local da, db = DIFF_ORDER[a.difficulty] or 5, DIFF_ORDER[b.difficulty] or 5
		if da ~= db then return da < db end
		return (a.name or "") < (b.name or "")
	end)

	-- display lines: recipes, and under the clicked one its mats
	local lines = {}
	for _, e in ipairs(recipes) do
		table.insert(lines, { kind = "recipe", e = e })
		if c.expanded == e.recipeID then
			for _, rg in ipairs(e.reagents or {}) do table.insert(lines, { kind = "mat", rg = rg }) end
		end
	end

	c.only:SetLabel(only and CSU:Color(CSU.COLORS.good, "Can make") or "Can make")
	c.only:SetStyle(only and "buy" or "default")
	local swatch = { optimal = CSU.COLORS.optimal, medium = CSU.COLORS.medium, easy = CSU.COLORS.easy, trivial = CSU.COLORS.trivial }
	for key, b in pairs(c.colorBtns) do
		local off = hide[key]
		b:SetLabel(CSU:Color(off and "4f5666" or swatch[key], off and "o" or "O"))
		b:SetStyle(off and "default" or "gold")
	end

	local fit = math.max(1, math.floor(((tonumber(c.list:GetHeight()) or (CH - 94))) / C_ROW_H))
	local maxOff = math.max(0, #lines - fit)
	if (c.offset or 0) > maxOff then c.offset = maxOff end
	local off = c.offset or 0
	local ri = 0
	for i = 1, math.max(fit, #c.rows) do
		local ln = (i <= fit) and lines[off + i] or nil
		local r = (i <= fit) and CompactRow(c, i) or c.rows[i]
		if ln and r then
			if ln.kind == "recipe" then
				ri = ri + 1
				SetupRecipeRow(r, ln.e, ri)
			else
				SetupMatRow(r, ln.rg)
			end
			r:Show()
		elseif r then
			r.entry, r.itemID = nil, nil
			r:Hide()
		end
	end
	if #recipes == 0 then
		c.empty:SetText((only or q ~= "" or next(hide)) and "Nothing matches your filters." or "No recipes yet: open this profession once.")
		c.empty:Show()
	else
		c.empty:Hide()
	end
	local canCount = 0
	for _, e in ipairs(recipes) do if e._can > 0 then canCount = canCount + 1 end end
	c.foot:SetText(string.format("%d recipes, %d you can make", #recipes, canCount))
end

function UI:CompactSwitchProf(step)
	local profs = CSU.Calc:GetSidebarProfessions()
	if #profs == 0 then return end
	local cur = CSU.Calc.activeProfession
	local idx = 1
	for i, p in ipairs(profs) do if p.name == cur then idx = i end end
	idx = ((idx - 1 + step) % #profs) + 1
	local name = profs[idx].name
	CSU.Calc.activeProfession = name
	if UI.UseOwnWindow() and self.OpenProfession then self:OpenProfession(name) end
	if self.compact then self.compact.offset = 0 end
	self:RenderCompact()
end

-- Simple <-> Full
function UI:SetViewMode(mode)
	CSU.settings.viewMode = (mode == "simple") and "simple" or "full"
	if mode == "simple" then
		if self.frame and self.frame:IsShown() then
			self.minimizing = true -- keep the profession open
			self.frame:Hide()
			self.minimizing = nil
		end
		self.minimized = false
		self:CreateCompact():Show()
		self:RenderCompact()
	else
		if self.compact then self.compact:Hide() end
		self:Show()
	end
	self:UpdateLauncher()
end

local compactQueued = false
function UI:QueueCompact()
	if not (self.compact and self.compact:IsShown()) or compactQueued then return end
	compactQueued = true
	C_Timer.After(0.2, function()
		compactQueued = false
		UI:RenderCompact()
	end)
end

function UI:Init()
	CSU:On("PROFESSION_UPDATED", function() UI:QueueRefresh() end)
	CSU:On("MAT_CHOICE_CHANGED", function() UI:QueueRefresh() UI:RenderQueue() UI:QueueCompact() end)
	CSU:On("PROFESSION_UPDATED", function() UI:QueueCompact() end)
	CSU:RegisterEvent("BAG_UPDATE_DELAYED", function() UI:QueueCompact() end)
	CSU:On("PRICES_UPDATED", function() UI:QueueRefresh() end)
	CSU:On("FILTER_CHANGED", function() UI:QueueRefresh() end)
	CSU:On("BAGS_UPDATED", function() UI:QueueRefresh() end)
	CSU:On("SCAN_STATE_CHANGED", function() UI:QueueRefresh() end)
	CSU:On("BUYER_STATE_CHANGED", function() UI:QueueRefresh() UI:RenderQueue() end)
	CSU:On("QUEUE_CHANGED", function()
		UI:QueueRefresh()
		UI:RenderQueue()
		UI:UpdateOptions()
	end)
	CSU:RegisterEvent("BAG_UPDATE_DELAYED", function() UI:RenderQueue() end)
	-- Queue window: back on screen after login / reload while something is queued, unless you closed it
	local function RestoreQueue()
		if CSU.settings.queueShown ~= false and CSU.Queue and #CSU.Queue:List() > 0 then
			UI:CreateQueueFrame():Show()
			UI:RenderQueue()
		end
	end
	if C_Timer and C_Timer.After then C_Timer.After(1, RestoreQueue) else RestoreQueue() end

	CSU:RegisterEvent("GET_ITEM_INFO_RECEIVED", function() UI:QueueRefresh() end)
	CSU:RegisterEvent("AUCTION_HOUSE_SHOW", function() UI:QueueRefresh() end)
	CSU:RegisterEvent("TRADE_SKILL_SHOW", function()
		EnsureProfessionButton()
		local pfs = _G.ProfessionsFrame
		if pfs and pfs._csuQuiet and not IsQuiet() and not UI.UseOwnWindow() then
			-- you opened a profession yourself while one was open out of sight: show it properly
			local okI, info = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
			local id = okI and info and info.professionID
			if C_TradeSkillUI.CloseTradeSkill then pcall(C_TradeSkillUI.CloseTradeSkill) end
			if pfs:IsShown() and HideUIPanel then pcall(HideUIPanel, pfs) end
			if id and C_Timer then
				C_Timer.After(0.2, function() pcall(C_TradeSkillUI.OpenTradeSkill, id) end)
			end
			return
		end
		UI:ApplyBlizzardWindowMode()
		local pfq = _G.ProfessionsFrame
		if UI.UseOwnWindow() and not (pfq and pfq._csuQuiet) and not IsQuiet() then
			if not (UI.frame and UI.frame:IsShown()) then
				UI:Show(true)
			else
				UI.frame:Raise()
				UI:QueueRefresh()
			end
		end
	end)
	CSU:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED", function()
		EnsureProfessionButton()
		UI:ApplyBlizzardWindowMode()
		local pfq = _G.ProfessionsFrame
		if UI.UseOwnWindow() and IsBlizzardOpen() and not (pfq and pfq._csuQuiet) and not IsQuiet() then
			if not (UI.frame and UI.frame:IsShown()) then
				UI:Show(true)
			else
				UI:QueueRefresh()
			end
		end
	end)
	CSU:RegisterEvent("CRAFT_SHOW", function()
		EnsureProfessionButton()
	end)
	CSU:RegisterEvent("ADDON_LOADED", function(_, name)
		if name == "Blizzard_Professions" or name == "Blizzard_TradeSkillUI" or name == "Blizzard_CraftUI" then
			EnsureProfessionButton()
			UI:ApplyBlizzardWindowMode()
		end
	end)
	EnsureProfessionButton()
	UI:ApplyBlizzardWindowMode()
	CreateLauncherButton()
end
