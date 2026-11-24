-- SkillUp & Profit :: Arrow
-- A TomTom-style arrow on your screen that points at the next stop of the route
-- (flight master, dock, zeppelin, portal, trainer).
--   Green  = you're facing it.   Yellow = it's to the side.   Red = it's behind you.
--   Close enough: the arrow turns around and bounces down over the spot.
-- Drag to move. Right-click to hide it (the route keeps going). /csu arrow shows it again.

local _, CSU = ...
local Arrow = {}
CSU.Arrow = Arrow

local ARRIVE = 15          -- yards: "you're there"
local SIZE = 56
local TEX = "Interface\\AddOns\\SkillUpProfitForever\\Arrow"
local PI, TWO_PI = math.pi, math.pi * 2

local frame, arrowTex, titleText, distText, etaText
local target            -- { cont, wx, wy, title }
local basis = {}        -- per continent: world vectors for "east" and "north"

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------
local function World(mapID, x, y) -- x, y 0..1
	if not (mapID and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
	local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
	if ok and cont and pos then return cont, pos.x, pos.y end
end

-- Which way is east and north in world numbers? Measured once per map from the map itself,
-- so it never depends on how the game orders its axes.
local function Basis(mapID)
	local b = basis[mapID]
	if b ~= nil then return b or nil end
	local _, wx1, wy1 = World(mapID, 0.4, 0.5)
	local _, wx2, wy2 = World(mapID, 0.6, 0.5)
	local _, wx3, wy3 = World(mapID, 0.5, 0.4)
	local _, wx4, wy4 = World(mapID, 0.5, 0.6)
	if not (wx1 and wx2 and wx3 and wx4) then basis[mapID] = false return nil end
	local ex, ey = wx2 - wx1, wy2 - wy1          -- east
	local nx, ny = wx3 - wx4, wy3 - wy4          -- north (map y grows southwards)
	local el, nl = math.sqrt(ex * ex + ey * ey), math.sqrt(nx * nx + ny * ny)
	if el == 0 or nl == 0 then basis[mapID] = false return nil end
	b = { ex = ex / el, ey = ey / el, nx = nx / nl, ny = ny / nl }
	basis[mapID] = b
	return b
end

local function Player()
	local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not m then return nil end
	local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(m, "player")
	if not pos then return nil end
	local px, py = pos.x, pos.y
	if pos.GetXY then px, py = pos:GetXY() end
	local cont, wx, wy = World(m, px, py)
	if not cont then return nil end
	return cont, wx, wy, m
end

-- distance in yards, and the direction as an angle counter-clockwise from north
-- (the same way GetPlayerFacing counts), or nil if it's on another continent
function Arrow:Vector()
	if not target then return nil end
	local cont, wx, wy, m = Player()
	if not cont then return nil, "nopos" end
	if cont ~= target.cont then return nil, "continent" end
	local b = Basis(m)
	if not b then return nil, "nopos" end
	local dx, dy = target.wx - wx, target.wy - wy
	local dist = math.sqrt(dx * dx + dy * dy)
	local east = dx * b.ex + dy * b.ey
	local north = dx * b.nx + dy * b.ny
	local angle = math.atan2(-east, north)       -- 0 = north, +pi/2 = west
	if angle < 0 then angle = angle + TWO_PI end
	return dist, angle
end

local function Wrap(a)
	a = a % TWO_PI
	if a > PI then a = a - TWO_PI end
	return a
end
Arrow.Wrap = Wrap

-- red (behind) -> yellow (side) -> green (ahead)
local function Color(rel)
	local p = 1 - math.abs(rel) / PI             -- 1 ahead, 0 behind
	if p > 0.5 then
		local t = (p - 0.5) * 2
		return 1 - t, 1, 0.1
	else
		local t = p * 2
		return 1, 0.15 + 0.85 * t, 0.1
	end
end
Arrow.Color = Color

local function Rotate(tex, a)
	if tex.SetRotation then
		tex:SetRotation(a)
		return
	end
	-- old clients: turn the texture coordinates instead
	local s, c = math.sin(a), math.cos(a)
	local function P(x, y)
		x, y = x - 0.5, y - 0.5
		return 0.5 + x * c - y * s, 0.5 + x * s + y * c
	end
	local ulx, uly = P(0, 0)
	local llx, lly = P(0, 1)
	local urx, ury = P(1, 0)
	local lrx, lry = P(1, 1)
	tex:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

local function FormatDist(d)
	if d >= 1000 then return string.format("%.1fk yd", d / 1000) end
	return string.format("%d yd", math.floor(d + 0.5))
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
local function SavePoint(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint(1)
	CSU.settings.arrowPoint = { point, relPoint, x, y }
end

local lastDist, speed, etaAcc, bob = nil, 0, 0, 0

local function OnUpdate(self, elapsed)
	local dist, angle = Arrow:Vector()
	if not dist then
		arrowTex:SetVertexColor(0.6, 0.6, 0.6)
		Rotate(arrowTex, 0)
		distText:SetText(angle == "continent" and "Other continent: take the boat or zeppelin" or "")
		etaText:SetText("")
		lastDist = nil
		return
	end
	distText:SetText(FormatDist(dist))

	if dist <= ARRIVE then
		-- arrived: arrow points down and bounces over the spot
		bob = (bob + elapsed * 4) % TWO_PI
		Rotate(arrowTex, PI)
		arrowTex:SetVertexColor(0.3, 1, 0.3)
		arrowTex:ClearAllPoints()
		arrowTex:SetPoint("CENTER", self, "CENTER", 0, 4 + math.abs(math.sin(bob)) * 8)
		etaText:SetText("You're there")
		return
	end
	arrowTex:ClearAllPoints()
	arrowTex:SetPoint("CENTER", self, "CENTER", 0, 4)

	local facing = GetPlayerFacing and GetPlayerFacing()
	if not facing then
		arrowTex:SetVertexColor(0.6, 0.6, 0.6)
		Rotate(arrowTex, 0)
	else
		local rel = Wrap(angle - facing)
		Rotate(arrowTex, rel)
		arrowTex:SetVertexColor(Color(rel))
	end

	-- time to arrive, worked out from how fast the distance drops
	etaAcc = etaAcc + elapsed
	if etaAcc >= 1 then
		if lastDist then
			local v = (lastDist - dist) / etaAcc
			speed = speed * 0.5 + v * 0.5
		end
		lastDist = dist
		etaAcc = 0
		if speed > 0.5 then
			local t = dist / speed
			etaText:SetText(string.format("%d:%02d", math.floor(t / 60), math.floor(t % 60)))
		else
			etaText:SetText("")
		end
	end
end

local function Create()
	if frame then return frame end
	frame = CreateFrame("Button", "SkillUpProfitArrow", UIParent)
	frame:SetSize(SIZE + 80, SIZE + 44)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(860)
	if frame.SetToplevel then frame:SetToplevel(true) end
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:RegisterForClicks("RightButtonUp")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", SavePoint)
	frame:SetScript("OnHide", frame.StopMovingOrSizing)
	frame:SetScript("OnClick", function(_, button)
		if button == "RightButton" then
			Arrow:SetShown(false)
			CSU:Print("Arrow hidden. Type /csu arrow to bring it back.")
		end
	end)
	frame:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine("SkillUp & Profit arrow", 1, 0.82, 0)
		GameTooltip:AddLine(target and target.title or "", 1, 1, 1, true)
		GameTooltip:AddLine("Green: straight ahead. Yellow: to the side. Red: behind you.", 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine("Drag to move. Right-click to hide.", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

	local pt = CSU.settings.arrowPoint
	if type(pt) == "table" then
		frame:SetPoint(pt[1] or "CENTER", UIParent, pt[2] or "CENTER", pt[3] or 0, pt[4] or 0)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	arrowTex = frame:CreateTexture(nil, "ARTWORK")
	arrowTex:SetTexture(TEX)
	arrowTex:SetSize(SIZE, SIZE)
	arrowTex:SetPoint("CENTER", frame, "CENTER", 0, 4)

	titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	titleText:SetPoint("BOTTOM", arrowTex, "TOP", 0, 0)
	titleText:SetWidth(240)
	titleText:SetWordWrap(true)

	distText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	distText:SetPoint("TOP", arrowTex, "BOTTOM", 0, -2)

	etaText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	etaText:SetPoint("TOP", distText, "BOTTOM", 0, -1)

	if CSU.UI and CSU.UI.GetScale then frame:SetScale(CSU.UI:GetScale()) end
	frame:SetScript("OnUpdate", OnUpdate)
	frame:Hide()
	return frame
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------
function Arrow:IsEnabled()
	return CSU.settings.arrow ~= false
end

function Arrow:GetFrame()
	return frame
end

function Arrow:StopMoving()
	if frame then SavePoint(frame) end
end

function Arrow:SetTitleShown(show)
	if not titleText then return end
	if show then titleText:Show() else titleText:Hide() end
end

-- mapID + zone coords 0..1
function Arrow:SetTarget(mapID, x, y, title)
	local cont, wx, wy = World(mapID, x, y)
	if not cont then
		self:Clear()
		return false
	end
	target = { cont = cont, wx = wx, wy = wy, title = title }
	lastDist, speed, etaAcc = nil, 0, 0
	if not self:IsEnabled() then return true end
	Create()
	titleText:SetText(title or "")
	if CSU.Route and CSU.Route.steps then
		titleText:Hide()
	else
		titleText:Show()
	end
	etaText:SetText("")
	frame:Show()
	return true
end

function Arrow:Clear()
	target = nil
	if frame then frame:Hide() end
	if CSU.UI and CSU.UI.RenderRouteBox then CSU.UI:RenderRouteBox() end
end

function Arrow:HasTarget()
	return target ~= nil
end

function Arrow:SetShown(on)
	CSU.settings.arrow = on and true or false
	if on and target then
		Create()
		titleText:SetText(target.title or "")
		if CSU.Route and CSU.Route.steps then
			titleText:Hide()
		else
			titleText:Show()
		end
		frame:Show()
	elseif frame then
		frame:Hide()
	end
	if CSU.UI and CSU.UI.RenderRouteBox then CSU.UI:RenderRouteBox() end
end

function Arrow:Toggle()
	self:SetShown(not self:IsEnabled())
	if self:IsEnabled() then
		CSU:Print(target and "Arrow on." or "Arrow on. It shows up when you pin a trainer or start a route.")
	else
		CSU:Print("Arrow off.")
	end
end

function Arrow:ResetPosition()
	CSU.settings.arrowPoint = nil
	if frame then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end
