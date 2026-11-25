-- CheapSkillUp :: Thresholds
-- Tracks recipe color thresholds [orange, yellow, green, gray] to calculate
-- exact crafts & materials needed until a Red/Orange recipe turns Yellow or Green.
-- Seeded with standard Classic 1-300 leveling recipes (matched by recipe name) and
-- automatically learns exact thresholds for any custom WoW Forever recipe as you level!

local _, CSU = ...
local Thresholds = {}
CSU.Thresholds = Thresholds

-- Format: ["lowercase recipe name"] = { orange, yellow, green, gray }
-- Values are standard Classic 1-300 thresholds; runtime learning overrides with exact server values.
local SEED_BY_NAME = {
	-- First Aid (Classic values: orange, yellow, green, gray)
	["linen bandage"] = { 1, 30, 45, 60 },
	["heavy linen bandage"] = { 40, 50, 75, 100 },
	["wool bandage"] = { 80, 80, 115, 150 },
	["heavy wool bandage"] = { 115, 115, 150, 185 },
	["anti-venom"] = { 80, 80, 115, 150 },
	["strong anti-venom"] = { 130, 130, 165, 200 },
	["silk bandage"] = { 150, 150, 180, 210 },
	["heavy silk bandage"] = { 180, 180, 210, 240 },
	["mageweave bandage"] = { 210, 210, 240, 270 },
	["heavy mageweave bandage"] = { 240, 240, 270, 300 },
	["runecloth bandage"] = { 260, 260, 290, 320 },
	["heavy runecloth bandage"] = { 290, 290, 320, 350 },

	-- Tailoring
	["bolt of linen cloth"] = { 1, 50, 62, 75 },
	["linen belt"] = { 15, 45, 57, 70 },
	["reinforced linen cape"] = { 60, 75, 87, 100 },
	["bolt of woolen cloth"] = { 75, 100, 112, 125 },
	["simple kilt"] = { 75, 105, 117, 130 },
	["double-stitched woolen shoulders"] = { 110, 125, 137, 150 },
	["bolt of silk cloth"] = { 125, 145, 157, 170 },
	["azure silk hood"] = { 145, 160, 172, 185 },
	["silk headband"] = { 160, 175, 187, 200 },
	["formal white shirt"] = { 170, 185, 197, 210 },
	["bolt of mageweave"] = { 175, 185, 197, 210 },
	["crimson silk vest"] = { 185, 205, 217, 230 },
	["crimson silk pantaloons"] = { 195, 215, 227, 240 },
	["black mageweave leggings"] = { 205, 225, 237, 250 },
	["black mageweave gloves"] = { 215, 235, 247, 260 },
	["black mageweave headband"] = { 230, 250, 262, 275 },
	["bolt of runecloth"] = { 250, 260, 270, 280 },
	["runecloth belt"] = { 255, 275, 287, 300 },
	["runecloth bag"] = { 260, 280, 292, 305 },
	["runecloth gloves"] = { 275, 295, 307, 320 },
	["runecloth headband"] = { 295, 315, 327, 340 },

	-- Alchemy
	["minor healing potion"] = { 1, 55, 65, 75 },
	["lesser healing potion"] = { 55, 85, 100, 115 },
	["elixir of wisdom"] = { 90, 120, 135, 150 },
	["healing potion"] = { 110, 140, 155, 170 },
	["greater healing potion"] = { 155, 185, 200, 215 },
	["elixir of agility"] = { 185, 215, 230, 245 },
	["elixir of greater defense"] = { 195, 225, 240, 255 },
	["superior healing potion"] = { 215, 245, 260, 275 },
	["elixir of detect undead"] = { 230, 260, 275, 290 },
	["elixir of greater agility"] = { 240, 270, 285, 300 },
	["superior mana potion"] = { 260, 285, 297, 310 },
	["major healing potion"] = { 275, 295, 307, 320 },

	-- Blacksmithing
	["rough sharpening stone"] = { 1, 25, 37, 50 },
	["rough grinding stone"] = { 25, 50, 62, 75 },
	["copper chain belt"] = { 35, 65, 80, 95 },
	["coarse grinding stone"] = { 75, 90, 102, 115 },
	["runed copper belt"] = { 70, 95, 107, 120 },
	["silvered bronze shoulders"] = { 125, 150, 162, 175 },
	["heavy grinding stone"] = { 125, 150, 162, 175 },
	["golden scale bracers"] = { 185, 205, 217, 230 },
	["solid grinding stone"] = { 200, 210, 220, 230 },
	["mithril scale bracers"] = { 215, 235, 247, 260 },
	["mithril spurs"] = { 235, 255, 267, 280 },
	["dense sharpening stone"] = { 250, 260, 270, 280 },
	["thorium bracers"] = { 260, 280, 292, 305 },
	["imperial plate belt"] = { 265, 285, 297, 310 },
	["thorium boots"] = { 280, 300, 312, 325 },

	-- Engineering
	["rough blasting powder"] = { 1, 20, 35, 50 },
	["handful of copper bolts"] = { 30, 45, 52, 60 },
	["copper tube"] = { 50, 65, 72, 80 },
	["coarse blasting powder"] = { 75, 85, 95, 105 },
	["silver contact"] = { 90, 105, 112, 120 },
	["bronze tube"] = { 105, 120, 127, 135 },
	["heavy blasting powder"] = { 125, 140, 150, 160 },
	["whirring bronze gizmo"] = { 125, 145, 155, 165 },
	["gold power core"] = { 150, 170, 180, 190 },
	["solid blasting powder"] = { 175, 185, 195, 205 },
	["mithril tube"] = { 195, 215, 225, 235 },
	["unstable trigger"] = { 200, 220, 230, 240 },
	["hi-impact mithril slugs"] = { 210, 230, 240, 250 },
	["mithril casing"] = { 215, 235, 245, 255 },
	["dense blasting powder"] = { 250, 260, 270, 280 },
	["thorium widget"] = { 260, 280, 290, 300 },
	["thorium shells"] = { 285, 300, 310, 320 },

	-- Leatherworking
	["light armor kit"] = { 1, 30, 45, 60 },
	["handstitched leather cloak"] = { 20, 45, 57, 70 },
	["embossed leather gloves"] = { 55, 80, 92, 105 },
	["medium armor kit"] = { 100, 115, 127, 140 },
	["cured medium hide"] = { 100, 115, 122, 130 },
	["fine leather belt"] = { 125, 145, 157, 170 },
	["heavy armor kit"] = { 150, 170, 182, 195 },
	["hillman's shoulders"] = { 130, 155, 167, 180 },
	["barbaric shoulders"] = { 175, 195, 207, 220 },
	["thick armor kit"] = { 200, 220, 232, 245 },
	["nightscape headband"] = { 205, 225, 237, 250 },
	["nightscape tunic"] = { 205, 225, 237, 250 },
	["nightscape pants"] = { 230, 250, 262, 275 },
	["rugged armor kit"] = { 250, 270, 282, 295 },
	["wicked leather gauntlets"] = { 260, 280, 292, 305 },
	["wicked leather bracers"] = { 265, 285, 297, 310 },
	["wicked leather headband"] = { 280, 300, 312, 325 },

	-- Enchanting
	["enchant bracer - minor health"] = { 1, 50, 62, 75 },
	["enchant bracer - minor stamina"] = { 50, 75, 87, 100 },
	["enchant bracer - minor agility"] = { 80, 105, 117, 130 },
	["enchant shield - minor stamina"] = { 105, 125, 137, 150 },
	["enchant bracer - lesser stamina"] = { 130, 155, 167, 180 },
	["enchant bracer - lesser strength"] = { 140, 165, 177, 190 },
	["enchant shield - lesser stamina"] = { 155, 175, 187, 200 },
	["enchant bracer - spirit"] = { 165, 190, 202, 215 },
	["enchant bracer - strength"] = { 180, 205, 217, 230 },
	["enchant cloak - greater defense"] = { 205, 225, 237, 250 },
	["enchant gloves - agility"] = { 210, 230, 242, 255 },
	["enchant bracer - greater stamina"] = { 220, 245, 257, 270 },
	["enchant chest - superior health"] = { 220, 245, 257, 270 },
	["enchant shield - greater stamina"] = { 265, 285, 297, 310 },
	["enchant cloak - superior defense"] = { 285, 305, 317, 330 },

	-- Cooking
	["roasted boar meat"] = { 1, 45, 65, 85 },
	["charred wolf meat"] = { 1, 45, 65, 85 },
	["smoked bear meat"] = { 40, 80, 100, 120 },
	["boiled clams"] = { 50, 90, 110, 130 },
	["seasoned wolf kabob"] = { 100, 140, 160, 180 },
	["curiously tasty omelet"] = { 130, 170, 190, 210 },
	["roast raptor"] = { 175, 215, 235, 255 },
	["monster omelet"] = { 225, 255, 275, 295 },
	["spotted yellowtail"] = { 225, 255, 275, 295 },
	["baked salmon"] = { 275, 305, 325, 345 },
	["nightfin soup"] = { 250, 280, 300, 320 },
}

local function GetLearnedTable()
	if not CSU.db then return nil end
	CSU.db.thresholds = CSU.db.thresholds or {}
	return CSU.db.thresholds
end

-- Called when a recipe is scanned with a known currentSkill and difficulty.
-- Automatically narrows/learns exact yellow/green/gray thresholds on live WoW Forever servers!
function Thresholds:Observe(recipeID, currentSkill, diffKey)
	if not (recipeID and currentSkill and currentSkill > 0 and diffKey) then return end
	local db = GetLearnedTable()
	if not db then return end

	local rec = db[recipeID]
	if not rec then
		rec = {}
		db[recipeID] = rec
	end

	-- Track highest skill seen as optimal/medium/easy and lowest skill seen as medium/easy/trivial
	if diffKey == "optimal" then
		if not rec.maxOpt or currentSkill > rec.maxOpt then rec.maxOpt = currentSkill end
	elseif diffKey == "medium" then
		if not rec.minMed or currentSkill < rec.minMed then rec.minMed = currentSkill end
		if not rec.maxMed or currentSkill > rec.maxMed then rec.maxMed = currentSkill end
		-- If we observed optimal at skill S and medium at S+1, we know exact yellowSkill = S+1!
		if rec.maxOpt and currentSkill == rec.maxOpt + 1 then
			rec.yellow = currentSkill
		end
	elseif diffKey == "easy" then
		if not rec.minEasy or currentSkill < rec.minEasy then rec.minEasy = currentSkill end
		if rec.maxMed and currentSkill == rec.maxMed + 1 then
			rec.green = currentSkill
		end
	elseif diffKey == "trivial" then
		if rec.minEasy and currentSkill > rec.minEasy and not rec.gray then
			rec.gray = currentSkill
		end
	end
end

-- Returns { yellow = number, green = number, gray = number, estimated = boolean }
function Thresholds:GetForRecipe(recipeID, recipeName, currentSkill, diffKey)
	local learned = GetLearnedTable() and GetLearnedTable()[recipeID]
	local seed = recipeName and SEED_BY_NAME[recipeName:lower()] or nil

	local yellow = (learned and learned.yellow) or (seed and seed[2])
	local green = (learned and learned.green) or (seed and seed[3])
	local gray = (learned and learned.gray) or (seed and seed[4])

	-- Sanity-check against live current difficulty so rebalanced WoW Forever recipes never use mismatched Classic seeds!
	local skill = currentSkill or 1
	if diffKey == "optimal" and yellow and yellow <= skill then
		yellow, green, gray = nil, nil, nil
	elseif diffKey == "medium" then
		-- Already Yellow at `skill`: if seed thinks it shouldn't even be Yellow yet (or is already past Green), ignore seed
		if (yellow and yellow > skill) or (green and green <= skill) then
			yellow, green, gray = nil, nil, nil
		end
	elseif diffKey == "easy" then
		if (green and green > skill) or (gray and gray <= skill) then
			yellow, green, gray = nil, nil, nil
		end
	end

	local estimated = false
	if not yellow then
		estimated = true
		if diffKey == "optimal" then
			-- Standard WoW milestones are multiples of 5, typically ~10-15 pts above current skill
			local nextFive = math.floor((skill + 15) / 5) * 5
			yellow = math.max(skill + 5, nextFive)
		else
			yellow = skill
		end
	end

	if not green then
		estimated = true
		if diffKey == "optimal" or diffKey == "medium" then
			green = math.max(skill + 5, yellow + 15)
		else
			green = skill
		end
	end

	if not gray then
		gray = green + 15
	end

	return {
		yellow = yellow,
		green = green,
		gray = gray,
		estimated = estimated,
	}
end

-- How high a recipe is, for sorting like Blizzard (highest first): the skill where it turns grey.
function Thresholds:LevelOf(recipeID, recipeName, currentSkill, diffKey)
	local t = self:GetForRecipe(recipeID, recipeName, currentSkill, diffKey)
	return t and t.gray or 0
end

-- Colour of a recipe at a given skill, from learned exact values or the seed table.
-- Returns "optimal" | "medium" | "easy" | "trivial", or nil when nothing is known.
function Thresholds:DifficultyAt(recipeID, recipeName, skill)
	if not skill then return nil end
	local learned = GetLearnedTable() and GetLearnedTable()[recipeID]
	local seed = recipeName and SEED_BY_NAME[recipeName:lower()] or nil
	local yellow = (learned and learned.yellow) or (seed and seed[2])
	local green = (learned and learned.green) or (seed and seed[3])
	local gray = (learned and learned.gray) or (seed and seed[4])
	if gray and skill >= gray then return "trivial" end
	if green and skill >= green then return "easy" end
	if yellow and skill >= yellow then return "medium" end
	if yellow then return "optimal" end
	return nil
end

-- Computes expected crafts to reach `targetColor` ("yellow" | "green") from currentSkill.
-- While Optimal (Red/Orange): 100% skill-up per craft (+numSkillUps).
-- While Medium (Yellow): WoW linear probability P(s) = (gray - s) / (gray - yellow).
-- Returns: crafts (integer), targetSkill (integer), estimated (boolean)
function Thresholds:EstimateCraftsUntil(recipeID, recipeName, currentSkill, diffKey, numSkillUps, targetColor)
	local skill = currentSkill or 1
	local pts = (numSkillUps and numSkillUps > 0) and numSkillUps or 1
	local th = self:GetForRecipe(recipeID, recipeName, skill, diffKey)

	if targetColor == "yellow" then
		if diffKey ~= "optimal" or skill >= th.yellow then
			return 0, th.yellow, th.estimated
		end
		local neededPts = th.yellow - skill
		local crafts = math.ceil(neededPts / pts)
		return crafts, th.yellow, th.estimated
	end

	-- targetColor == "green"
	if diffKey == "easy" or diffKey == "trivial" or skill >= th.green then
		return 0, th.green, th.estimated
	end

	local crafts = 0
	local s = skill

	-- Phase 1: Red/Orange -> Yellow (100% chance per craft)
	if s < th.yellow then
		local optPts = th.yellow - s
		local optCrafts = math.ceil(optPts / pts)
		crafts = crafts + optCrafts
		s = s + (optCrafts * pts)
	end

	-- Phase 2: Yellow -> Green (expected crafts = sum of 1 / P(s))
	local span = math.max(1, th.gray - th.yellow)
	while s < th.green do
		local prob = math.max(0.25, (th.gray - s) / span)
		crafts = crafts + (1 / prob)
		s = s + pts
	end

	return math.ceil(crafts), th.green, th.estimated
end
