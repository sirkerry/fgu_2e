--
-- 2E Better Subraces
--
-- The stock addRaceSelect (manager_char.lua) always applies the base
-- race's own proficiencies and Advanced Effects to a character, but for
-- a chosen subrace it only ever applies traits - there was no UI to
-- author subrace-level proficiencies/effects at all until this
-- extension's record_subrace_plus.xml added one. This wraps
-- CharManager.addRaceSelect to also apply those two lists off the
-- subrace's own record, reusing CharManager's own generic helpers
-- (the same ones the stock function already uses for the base race).
--

local Original_CharManager_addRaceSelect = nil;

function onInit()
	Original_CharManager_addRaceSelect = CharManager.addRaceSelect;
	CharManager.addRaceSelect = addRaceSelect_subraceplus;
end

function addRaceSelect_subraceplus(aSelection, aTable)
	Original_CharManager_addRaceSelect(aSelection, aTable);

	-- Mirrors the stock function's own validation: only proceed with a
	-- single, unambiguous subrace selection.
	if not aSelection or #aSelection ~= 1 then
		return;
	end

	local sSubRace;
	if type(aSelection[1]) == "table" then
		sSubRace = aSelection[1].text;
	else
		sSubRace = aSelection[1];
	end

	local nodeChar = aTable["char"];
	if not nodeChar then
		return;
	end

	for _, vSubRace in ipairs(aTable["suboptions"] or {}) do
		if sSubRace == vSubRace.text then
			local nodeSubRace = DB.findNode(vSubRace.linkrecord);
			if nodeSubRace then
				CharManager.addWeaponProficiencies(nodeSubRace, nodeChar, "reference_racialproficiency");
				CharManager.addEffectFeature(DB.getChild(nodeSubRace, "effectlist"), nodeChar);
			end
			break;
		end
	end
end
