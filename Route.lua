-- SkillUp & Profit :: Route
-- Step-by-step way to a trainer: walk -> fly -> boat/zeppelin -> portal -> trainer.
-- The map pin and the arrow (Arrow.lua) always point at the next place: the flight master,
-- the dock, the zeppelin tower, the portal, then the trainer. Steps move on by themselves.
--
-- Flight points come from the game (C_TaxiMap). Which ones you know is remembered every
-- time you open a flight master. Boats/zeppelins are listed below (WoW Forever routes).
-- Walking is a straight line, so it can't see mountains or walls.

local _, CSU = ...
local Route = {}
CSU.Route = Route

local CONTINENTS = { 1414, 1415 } -- Kalimdor, Eastern Kingdoms (Classic map numbers)
local WALK_SPEED = 8      -- yards per second (rough, some walking some riding)
local FLY_SPEED = 30      -- gryphon speed, routes bend so distance is padded
local FLY_OVERHEAD = 25   -- talk to flight master, take off, land
local BOAT_COST = 240     -- wait for the boat + the ride
local PORTAL_COST = 10

---------------------------------------------------------------------------
-- Docks, zeppelin towers, portals (zone coordinates). fp = use that town's flight master spot.
---------------------------------------------------------------------------
-- town = how the place is named as a destination; go = where you walk to board
local function S(zone, x, y, town, go) return { zone = zone, x = x, y = y, town = town, go = go } end
local function F(fp, town, go) return { fp = fp, town = town, go = go } end

local SPOTS = {
	sw_harbor  = S("Stormwind City", 26.0, 54.5, "Stormwind Harbor", "Stormwind Harbor, the left dock with night elf banners"),
	auberdine  = S("Darkshore", 32.4, 43.8, "Auberdine", "the docks in Auberdine"),
	rutheran   = S("Teldrassil", 54.9, 96.8, "Rut'theran Village", "the dock in Rut'theran Village"),
	menethil   = F("Menethil", "Menethil Harbor", "the docks in Menethil Harbor"),
	southshore = F("Southshore", "Southshore", "the dock in Southshore"),
	theramore  = F("Theramore", "Theramore Isle", "the dock in Theramore"),
	bootybay   = S("Stranglethorn Vale", 25.9, 73.1, "Booty Bay", "the dock in Booty Bay"),
	ratchet    = S("The Barrens", 63.7, 38.6, "Ratchet", "the dock in Ratchet"),
	org_zep    = S("Durotar", 50.8, 13.8, "Orgrimmar", "the zeppelin tower outside Orgrimmar"),
	uc_zep     = S("Tirisfal Glades", 60.7, 58.8, "Undercity", "the zeppelin tower outside Undercity"),
	gg_zep     = S("Stranglethorn Vale", 31.6, 29.2, "Grom'gol Base Camp", "the zeppelin tower in Grom'gol Base Camp"),
	feathermoon= S("Feralas", 31.0, 39.8, "Feathermoon Stronghold", "the dock in Feathermoon Stronghold"),
	forgotten  = S("Feralas", 43.3, 42.8, "the Forgotten Coast", "the dock on the Forgotten Coast"),
	steamwheedle = F("Steamwheedle", "Steamwheedle Port", "the dock in Steamwheedle Port"),
	powderfuse = F("Powderfuse", "Powderfuse Port", "the dock in Powderfuse Port"),
	darn_portal= S("Darnassus", 30.0, 41.3, "Darnassus", "the portal in Darnassus"),
}

-- kind: boat | zeppelin | portal. oneway = only a -> b. line groups legs of the same ship.
local LINKS = {
	{ "sw_harbor", "auberdine", "boat", "Alliance" },
	{ "auberdine", "rutheran", "boat", "Alliance", cost = 110 },
	{ "menethil", "theramore", "boat", "Alliance" },
	{ "auberdine", "menethil", "boat", "Alliance", oneway = true, line = "loop" },
	{ "menethil", "southshore", "boat", "Alliance", oneway = true, line = "loop" },
	{ "southshore", "auberdine", "boat", "Alliance", oneway = true, line = "loop" },
	{ "feathermoon", "forgotten", "boat", "Alliance" },
	{ "bootybay", "ratchet", "boat", "Both" },
	{ "steamwheedle", "powderfuse", "boat", "Both" },
	{ "org_zep", "uc_zep", "zeppelin", "Horde" },
	{ "org_zep", "gg_zep", "zeppelin", "Horde" },
	{ "uc_zep", "gg_zep", "zeppelin", "Horde" },
	{ "rutheran", "darn_portal", "portal", "Alliance" },
}

---------------------------------------------------------------------------
-- Map helpers
---------------------------------------------------------------------------
local mapByName = {}
local function MapIDByName(zone)
	if not zone then return nil end
	if mapByName[zone] ~= nil then return mapByName[zone] or nil end
	local id = CSU.Calc.TRAIN_MAPS and CSU.Calc.TRAIN_MAPS[zone]
	local ok, info = pcall(C_Map.GetMapInfo, id or 0)
	if not (ok and info and info.name == zone) then
		id = nil
		for i = 1400, 1460 do
			local ok2, inf = pcall(C_Map.GetMapInfo, i)
			if ok2 and inf and inf.name == zone then id = i break end
		end
		if not id then
			for i = 1, 2600 do
				local ok2, inf = pcall(C_Map.GetMapInfo, i)
				if ok2 and inf and inf.name == zone and inf.mapType == 3 then id = i break end
			end
		end
	end
	mapByName[zone] = id or false
	return id
end
Route.MapIDByName = MapIDByName

-- zone coords (0-100) -> continentID, world x, world y
local function ToWorld(mapID, x, y)
	if not (mapID and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
	local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x / 100, y / 100))
	if ok and cont and pos then return cont, pos.x, pos.y end
	return nil
end

-- which continent map (1414 / 1415) belongs to a continent ID
local contOfMap = {}
local function ContinentMapFor(cont)
	for _, cm in ipairs(CONTINENTS) do
		if contOfMap[cm] == nil then
			local c = ToWorld(cm, 50, 50)
			contOfMap[cm] = c or false
		end
		if contOfMap[cm] == cont then return cm end
	end
end

-- world -> best zone map + zone coords (0-100)
local function ToZone(cont, wx, wy)
	if not (C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
	local cm = ContinentMapFor(cont)
	if cm then
		local ok, m, pos = pcall(C_Map.GetMapPosFromWorldPos, cont, CreateVector2D(wx, wy), cm)
		if ok and m and pos and pos.x >= 0 and pos.x <= 1 and pos.y >= 0 and pos.y <= 1 then
			local ok2, zone = pcall(C_Map.GetMapInfoAtPosition, cm, pos.x, pos.y)
			if ok2 and zone and zone.mapID then
				local ok3, zm, zpos = pcall(C_Map.GetMapPosFromWorldPos, cont, CreateVector2D(wx, wy), zone.mapID)
				if ok3 and zpos then return zone.mapID, zpos.x * 100, zpos.y * 100, zone.name end
			end
			return cm, pos.x * 100, pos.y * 100, nil
		end
	end
	return nil
end

-- Land you can't walk off: Rut'theran (bottom of the tree), Teldrassil/Darnassus (top), Feathermoon island
local function IslandOf(zone, x, y)
	if zone == "Darnassus" then return "teldrassil" end
	if zone == "Teldrassil" then return (y and y >= 85) and "rutheran" or "teldrassil" end
	if zone == "Feralas" and x and x < 37 then return "feathermoon" end
	return "main"
end

local function Dist(a, b)
	local dx, dy = a.wx - b.wx, a.wy - b.wy
	return math.sqrt(dx * dx + dy * dy)
end

local function PlayerFaction()
	return (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
end

---------------------------------------------------------------------------
-- Flight points you know (remembered when you open a flight master)
---------------------------------------------------------------------------
local function KnownFPs()
	local char = CSU:GetCharDB()
	char.knownFP = char.knownFP or {}
	return char.knownFP
end

local function RecordFlightMaster()
	if not (C_TaxiMap and C_TaxiMap.GetAllTaxiNodes) then return end
	local known = KnownFPs()
	local n = 0
	for _, cm in ipairs(CONTINENTS) do
		local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, cm)
		if ok and type(nodes) == "table" then
			for _, node in ipairs(nodes) do
				if node.name and node.state ~= 2 then -- 2 = Unreachable (not discovered)
					if not known[node.name] then n = n + 1 end
					known[node.name] = true
				end
			end
		end
	end
	known.__recorded = true
end

local function FlightPoints()
	local out = {}
	if not (C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap) then return out end
	local faction = PlayerFaction()
	local fcode = (faction == "Horde") and 1 or 2
	local known = KnownFPs()
	for _, cm in ipairs(CONTINENTS) do
		local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, cm)
		if ok and type(nodes) == "table" then
			for _, node in ipairs(nodes) do
				local fac = node.faction or 0
				if node.position and (fac == 0 or fac == fcode) then
					local cont, wx, wy = ToWorld(cm, node.position.x * 100, node.position.y * 100)
					if cont then
						local zm, zx, zy, zname = ToZone(cont, wx, wy)
						local isKnown
						if known.__recorded then isKnown = known[node.name] and true or false
						else isKnown = (node.isUndiscovered == false) end
						table.insert(out, {
							kind = "fp", name = node.name, cont = cont, wx = wx, wy = wy,
							map = zm, x = zx, y = zy, zone = zname,
							island = IslandOf(zname, zx, zy), known = isKnown,
						})
					end
				end
			end
		end
	end
	return out
end
Route.FlightPoints = FlightPoints

local function FindFP(fps, pattern)
	for _, fp in ipairs(fps) do
		if fp.name and fp.name:find(pattern, 1, true) then return fp end
	end
end

---------------------------------------------------------------------------
-- Graph + shortest way (Dijkstra)
---------------------------------------------------------------------------
local function MakeSpot(key, spot, fps)
	local n = { kind = "spot", key = key, name = spot.town, go = spot.go }
	if spot.fp then
		local fp = FindFP(fps, spot.fp)
		if not fp then return nil end
		n.cont, n.wx, n.wy, n.map, n.x, n.y, n.zone = fp.cont, fp.wx, fp.wy, fp.map, fp.x, fp.y, fp.zone
	else
		local m = MapIDByName(spot.zone)
		local cont, wx, wy = ToWorld(m, spot.x, spot.y)
		if not cont then return nil end
		n.cont, n.wx, n.wy, n.map, n.x, n.y, n.zone = cont, wx, wy, m, spot.x, spot.y, spot.zone
	end
	n.island = IslandOf(n.zone, n.x, n.y)
	return n
end

local function PlayerNode()
	local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not m then return nil end
	local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(m, "player")
	if not pos then return nil end
	local cont, wx, wy = ToWorld(m, pos.x * 100, pos.y * 100)
	if not cont then return nil end
	local info = C_Map.GetMapInfo(m)
	local zone = info and info.name
	return { kind = "start", name = "you", cont = cont, wx = wx, wy = wy, map = m, x = pos.x * 100, y = pos.y * 100,
		zone = zone, island = IslandOf(zone, pos.x * 100, pos.y * 100) }
end
Route.PlayerNode = PlayerNode

-- Returns a list of steps, or nil + reason
function Route:Plan(place, title)
	if not (place and place.zone and place.x) then return nil, "no map spot for this trainer" end
	local start = PlayerNode()
	if not start then return nil, "can't see where you are (indoors or in a dungeon?)" end
	local tm = MapIDByName(place.zone)
	local tc, twx, twy = ToWorld(tm, place.x, place.y)
	if not tc then return nil, "couldn't find " .. place.zone .. " on the map" end
	local goal = { kind = "goal", name = place.npc, cont = tc, wx = twx, wy = twy, map = tm, x = place.x, y = place.y,
		zone = place.zone, island = IslandOf(place.zone, place.x, place.y), place = place }

	local faction = PlayerFaction()
	local fps = FlightPoints()
	local nodes = { start, goal }
	for _, fp in ipairs(fps) do
		if fp.known then table.insert(nodes, fp) end
	end
	local spotNode = {}
	for key, spot in pairs(SPOTS) do
		local n = MakeSpot(key, spot, fps)
		if n then spotNode[key] = n table.insert(nodes, n) end
	end

	-- edges
	local edges = {}
	local function add(a, b, cost, kind, extra)
		edges[a] = edges[a] or {}
		table.insert(edges[a], { to = b, cost = cost, kind = kind, extra = extra })
	end
	for i = 1, #nodes do
		local a = nodes[i]
		for j = 1, #nodes do
			local b = nodes[j]
			if i ~= j and a.cont == b.cont then
				local d = Dist(a, b)
				if a.island == b.island then
					add(a, b, d / WALK_SPEED, "walk")
				end
				if a.kind == "fp" and b.kind == "fp" then
					add(a, b, d * 1.3 / FLY_SPEED + FLY_OVERHEAD, "fly")
				end
			end
		end
	end
	for _, l in ipairs(LINKS) do
		local a, b = spotNode[l[1]], spotNode[l[2]]
		local ok = (l[4] == "Both" or l[4] == faction)
		if a and b and ok then
			local cost = l.cost or ((l[3] == "portal") and PORTAL_COST or BOAT_COST)
			add(a, b, cost, l[3], l)
			if not l.oneway then add(b, a, cost, l[3], l) end
		end
	end

	-- Dijkstra (small graph, simple version)
	local dist, prev, done = {}, {}, {}
	dist[start] = 0
	while true do
		local u, best = nil, math.huge
		for _, n in ipairs(nodes) do
			if not done[n] and dist[n] and dist[n] < best then u, best = n, dist[n] end
		end
		if not u or u == goal then break end
		done[u] = true
		for _, e in ipairs(edges[u] or {}) do
			local nd = best + e.cost
			if not dist[e.to] or nd < dist[e.to] then
				dist[e.to] = nd
				prev[e.to] = { from = u, edge = e }
			end
		end
	end
	if not dist[goal] then return nil, "no way found with the flight points and boats I know" end

	-- path as edges
	local path = {}
	local n = goal
	while prev[n] do
		table.insert(path, 1, { from = prev[n].from, to = n, kind = prev[n].edge.kind, link = prev[n].edge.extra })
		n = prev[n].from
	end

	-- steps (merge walks; merge legs of the same ship line)
	local steps = {}
	local function placeName(node)
		if node.kind == "fp" then return "the flight master in " .. node.name end
		if node.kind == "spot" then return node.go end
		return node.name
	end
	local i = 1
	while i <= #path do
		local p = path[i]
		if p.kind == "walk" then
			local last = p
			while path[i + 1] and path[i + 1].kind == "walk" do i = i + 1 last = path[i] end
			local nx = path[i + 1]
			local text
			if last.to.kind == "goal" then
				text = string.format("Go to %s (%s, %s).", place.npc, place.town or place.zone, place.zone)
			elseif nx and nx.kind == "fly" then
				text = "Go to " .. placeName(last.to) .. "."
			elseif nx and (nx.kind == "boat" or nx.kind == "zeppelin") then
				-- name the final stop of that ship
				local j, dest = i + 1, nx.to
				while path[j + 1] and path[j + 1].kind == nx.kind and nx.link and nx.link.line and path[j + 1].link and path[j + 1].link.line == nx.link.line do
					j = j + 1
					dest = path[j].to
				end
				text = string.format("Go to %s and take the %s to %s.", last.to.go, nx.kind, dest.name)
			elseif nx and nx.kind == "portal" then
				text = "Go to the portal in " .. last.to.name .. "."
			else
				text = "Go to " .. placeName(last.to) .. "."
			end
			table.insert(steps, { kind = last.to.kind == "goal" and "goal" or "walk", text = text, node = last.to })
		elseif p.kind == "fly" then
			table.insert(steps, { kind = "fly", text = "Fly to " .. p.to.name .. ".", node = p.to })
		elseif p.kind == "boat" or p.kind == "zeppelin" then
			local last = p
			local stops = {}
			while path[i + 1] and path[i + 1].kind == p.kind and p.link and path[i + 1].link and path[i + 1].link.line and path[i + 1].link.line == p.link.line do
				table.insert(stops, last.to.name)
				i = i + 1
				last = path[i]
			end
			local text = string.format("Take the %s to %s.", p.kind, last.to.name)
			if #stops > 0 then
				text = text .. " Stay on when it stops at " .. table.concat(stops, ", ") .. "."
			end
			table.insert(steps, { kind = "ride", text = text, node = last.to })
		elseif p.kind == "portal" then
			table.insert(steps, { kind = "portal", text = "Go through the portal to " .. p.to.name .. ".", node = p.to })
		end
		i = i + 1
	end
	if #steps == 0 or steps[#steps].kind ~= "goal" then
		table.insert(steps, { kind = "goal", text = string.format("Go to %s (%s, %s).", place.npc, place.town or place.zone, place.zone), node = goal })
	end
	steps[#steps].final = true
	local unknownNote = not KnownFPs().__recorded
	return steps, nil, unknownNote
end

---------------------------------------------------------------------------
-- Following the route: pin the next spot, move on when you get there
---------------------------------------------------------------------------
Route.steps = nil
Route.index = 0
Route.title = nil

local function PlayerWorld()
	local p = PlayerNode()
	return p
end

function Route:PinStep()
	local s = self.steps and self.steps[self.index]
	if not s then return end
	local n = s.node
	local pin = { npc = s.final and (self.place and self.place.npc) or (n.name or "next stop"), town = n.go, zone = n.zone, x = n.x, y = n.y, map = n.map }
	if CSU.UI and CSU.UI.PinOnMap then
		CSU.UI:PinOnMap(pin, string.format("%d/%d: %s", self.index, #self.steps, s.text), true)
	end
	if CSU.UI and CSU.UI.RenderRouteBox then CSU.UI:RenderRouteBox() end
end

local function CopyPlace(p)
	if type(p) ~= "table" then return nil end
	return { npc = p.npc, town = p.town, zone = p.zone, x = p.x, y = p.y, map = p.map }
end

local function CopyTrack(t)
	if type(t) ~= "table" or not (t.prof and t.cap) then return nil end
	return { prof = t.prof, cap = t.cap }
end

local function IsTrackLearned(track)
	if not (track and track.prof and track.cap) then return false end
	local live = CSU.Calc and CSU.Calc.GetLiveProfessions and CSU.Calc.GetLiveProfessions()[track.prof]
	return live ~= nil and (live.maxSkillLevel or 0) >= track.cap
end

function Route:SaveActive(mode, place, title, track)
	if not (CSU.db and CSU.GetCharDB) then return end
	local charDB = CSU:GetCharDB()
	if not (mode and place) then
		charDB.activeRoute = nil
		return
	end
	charDB.activeRoute = {
		mode = mode,
		place = CopyPlace(place),
		title = title,
		track = CopyTrack(track),
	}
end

function Route:CheckLearned()
	if self.steps and IsTrackLearned(self.track) then
		local t = self.track
		self:Stop()
		CSU:Print("Learned %s (cap %d)! Arrow cleared.", t.prof, t.cap)
		return true
	end
	if CSU.UI and CSU.UI.pinTrack and IsTrackLearned(CSU.UI.pinTrack) then
		local t = CSU.UI.pinTrack
		CSU.UI:ClearPin()
		CSU:Print("Learned %s (cap %d)! Arrow cleared.", t.prof, t.cap)
		return true
	end
	return false
end

function Route:Start(place, title, track, quiet)
	if IsTrackLearned(track) then
		self:Stop()
		return false
	end
	local steps, err, unknownNote = self:Plan(place, title)
	if not steps then
		if not quiet then
			CSU:Print("Couldn't plan a route: %s. Pinning the trainer instead.", err or "?")
		end
		if CSU.UI then CSU.UI:PinOnMap(place, title, quiet, track) end
		return false
	end
	self.steps, self.index, self.title, self.place, self.track, self.done = steps, 1, title, place, CopyTrack(track), false
	self:SaveActive("route", place, title, self.track)
	if not quiet then
		if unknownNote then
			CSU:Print("Tip: open any flight master once, so I know exactly which flight points you have.")
		end
		CSU:Print("Route to %s: %d step%s. Follow the arrow.", place.npc, #steps, #steps == 1 and "" or "s")
	end
	self:PinStep()
	return true
end

function Route:Stop()
	self.steps, self.index, self.track, self.done = nil, 0, nil, false
	self:SaveActive(nil)
	if CSU.UI and CSU.UI.ClearPin then CSU.UI:ClearPin() end
	if CSU.UI and CSU.UI.RenderRouteBox then CSU.UI:RenderRouteBox() end
end

local REPLAN_INTERVAL = 3   -- seconds between automatic route re-checks

local function SameRemainingRoute(oldSteps, oldIndex, newSteps)
	if not (oldSteps and newSteps) then return false end
	local rem = #oldSteps - oldIndex + 1
	if rem ~= #newSteps then return false end
	for i = 1, rem do
		local a, b = oldSteps[oldIndex + i - 1], newSteps[i]
		if a.kind ~= b.kind or a.text ~= b.text then return false end
	end
	return true
end

function Route:Next()
	if not self.steps then return end
	if self.index < #self.steps then
		self.index = self.index + 1
		self:PinStep()
	end
end

function Route:Back()
	if not self.steps then return end
	if self.index > 1 then
		self.index = self.index - 1
		self:PinStep()
	end
end

function Route:Replan()
	if self.place then self:Start(self.place, self.title, self.track) end
end

function Route:AutoReplan()
	if not (self.steps and self.place) or self.done then return end
	if UnitOnTaxi and UnitOnTaxi("player") then return end
	local steps = self:Plan(self.place, self.title)
	if not steps then return end
	if SameRemainingRoute(self.steps, self.index, steps) then return end
	self.steps, self.index, self.done = steps, 1, false
	self:PinStep()
end

-- Checked twice a second while a route is active
function Route:Tick()
	if self:CheckLearned() then return end
	local s = self.steps and self.steps[self.index]
	if not s or self.done then return end
	local me = PlayerWorld()
	if not me then return end
	local n = s.node
	local onTaxi = UnitOnTaxi and UnitOnTaxi("player")
	local d = (me.cont == n.cont) and Dist(me, n) or math.huge
	local arrived = false
	if s.kind == "walk" then
		arrived = d < 25
		-- already flying/sailing on to the next step
		local nx = self.steps[self.index + 1]
		if not arrived and onTaxi and nx and nx.kind == "fly" then arrived = true end
	elseif s.kind == "fly" then
		arrived = (not onTaxi) and d < 120
	elseif s.kind == "ride" then
		arrived = d < 150
	elseif s.kind == "portal" then
		arrived = (me.zone == n.zone) or d < 60
	elseif s.kind == "goal" then
		arrived = d < 15
	end
	if arrived then
		if s.final then
			self.done = true
			CSU:Print("You're there: talk to %s.", self.place and self.place.npc or "the trainer")
			if CSU.UI and CSU.UI.RenderRouteBox then CSU.UI:RenderRouteBox() end
		else
			self.index = self.index + 1
			self:PinStep()
		end
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ticker = CreateFrame("Frame")
local acc, replanAcc = 0, 0
ticker:SetScript("OnUpdate", function(_, elapsed)
	if not Route.steps then
		acc, replanAcc = 0, 0
		return
	end
	acc = acc + elapsed
	replanAcc = replanAcc + elapsed
	if acc >= 0.5 then
		acc = 0
		local ok, err = pcall(Route.Tick, Route)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
	if replanAcc >= REPLAN_INTERVAL then
		replanAcc = 0
		local ok, err = pcall(Route.AutoReplan, Route)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
end)

CSU:RegisterEvent("TAXIMAP_OPENED", function()
	C_Timer.After(0.2, function()
		RecordFlightMaster()
		if Route.steps then Route:AutoReplan() end
	end)
end)

local function OnSkillChanged()
	C_Timer.After(0.2, function() Route:CheckLearned() end)
end
CSU:RegisterEvent("SKILL_LINES_CHANGED", OnSkillChanged)
CSU:RegisterEvent("CHAT_MSG_SKILL", OnSkillChanged)
CSU:RegisterEvent("TRAINER_UPDATE", OnSkillChanged)

local function RestoreSavedRoute(attempt)
	if Route.steps or (CSU.Arrow and CSU.Arrow:HasTarget()) then return end
	if not (CSU.db and CSU.GetCharDB) then return end
	local saved = CSU:GetCharDB().activeRoute
	if type(saved) ~= "table" or type(saved.place) ~= "table" then return end
	if IsTrackLearned(saved.track) then
		CSU:GetCharDB().activeRoute = nil
		return
	end
	if saved.mode == "route" then
		if not PlayerNode() and (attempt or 1) < 3 then
			C_Timer.After(2, function() RestoreSavedRoute((attempt or 1) + 1) end)
			return
		end
		Route:Start(saved.place, saved.title, saved.track, true)
	elseif saved.mode == "pin" and CSU.UI and CSU.UI.PinOnMap then
		CSU.UI:PinOnMap(saved.place, saved.title, true, saved.track)
	end
end

CSU:RegisterEvent("PLAYER_LOGIN", function()
	C_Timer.After(1.5, function() RestoreSavedRoute(1) end)
end)
