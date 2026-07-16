--
-- 2E Thematic Saves
--
-- Display-only renames of the ten AD&D 2E saving throw categories.
-- Database keys (saves.paralyzation.score, etc.) and mechanics are unchanged.
--
--   paralyzation  -> Hold
--   poison        -> Poison   (unchanged)
--   death         -> Death    (unchanged)
--   rod           -> Fear
--   staff         -> Device
--   wand          -> Ray
--   petrification -> Stone
--   polymorph     -> Curse
--   breath        -> Blast
--   spell         -> Spell    (unchanged)
--
-- Chat rolls build labels from DataCommon.saves_stol, so we patch that table
-- on init. Sheet labels come from the strings XML overrides.
--

ThematicSavesManager = {};

local THEMATIC_NAMES = {
	poison = "Poison",
	paralyzation = "Hold",
	death = "Death",
	rod = "Fear",
	staff = "Device",
	wand = "Ray",
	petrification = "Stone",
	polymorph = "Curse",
	breath = "Blast",
	spell = "Spell",
};

function ThematicSavesManager.isActive()
	return true;
end

function ThematicSavesManager.getDisplayName(sSave)
	local sKey = StringManager.trim(sSave or ""):lower();
	return THEMATIC_NAMES[sKey] or sSave;
end

function onInit()
	if DataCommon and DataCommon.saves_stol then
		for sKey, sName in pairs(THEMATIC_NAMES) do
			DataCommon.saves_stol[sKey] = sName;
		end
	end
end
