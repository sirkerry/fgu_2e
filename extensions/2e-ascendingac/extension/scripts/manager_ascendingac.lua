--
-- 2E Ascending AC
--
-- Registers the HouseRule_ASCENDING_AC option -- present throughout shared
-- ADND combat/character code (manager_action_attack.lua, char_main.lua,
-- npc_main.lua, template_char.xml) but never registered for 2E, so it was
-- previously impossible to turn on. Defaults to "on" so loading this
-- extension is enough by itself; still a real Options toggle (House Rules
-- (GM)) so a GM can switch back to descending without unloading it.
--
-- Once registered, most of ascending AC already works natively for PCs
-- (Total AC display, attack-roll BAB labels, ascending hit resolution --
-- confirmed live). Two gaps remain, both because stock only half-finished
-- the wiring:
--   1. PC sheet's combat-score box (charsheet_main "thaco") always shows
--      THAC0/"THACO" -- char_main.lua only mirrors the DB values between
--      combat.thaco.score/combat.bab.score, it never swaps the visible
--      label or value. Fixed in record_char_ascendingac.xml by adding a
--      parallel "BAB" box in the same slot, toggled by visibility.
--   2. NPC sheet: npc_main.lua's own ac_ascending/bab mirroring
--      (updateAscendingAC/updateBAB) and the option-driven show/hide
--      (updateNPCEditMode) are both present but commented out, and the
--      ac_ascending/bab controls referenced there don't exist in
--      record_npc.xml. This script re-implements the mirroring globally
--      (DB.addHandler on npc.*.ac/thaco, not tied to a window being open),
--      and record_char_ascendingac.xml adds the missing controls.
--

AscendingACManager = {};

function AscendingACManager.isActive()
	return true;
end

function AscendingACManager.isOn()
	return (OptionsManager.getOption("HouseRule_ASCENDING_AC") or ""):match("on") ~= nil;
end

-- ac/thaco stay the source of truth (2E descending, matching modules and
-- the attack pipeline); ac_ascending/bab are read-only derived caches for
-- display, mirrored one-way only.
local function syncNode(node)
	if not node then
		return;
	end

	local nAC = DB.getValue(node, "ac", 10);
	local nAscAC = (nAC < 10) and (20 - nAC) or nAC;
	if DB.getValue(node, "ac_ascending", 10) ~= nAscAC then
		DB.setValue(node, "ac_ascending", "number", nAscAC);
	end

	local nTHACO = DB.getValue(node, "thaco", 20);
	local nBAB = 20 - nTHACO;
	if DB.getValue(node, "bab", 0) ~= nBAB then
		DB.setValue(node, "bab", "number", nBAB);
	end
end

function AscendingACManager.syncAllNPCs()
	for _, node in pairs(DB.getChildren(DB.getPath("npc"))) do
		syncNode(node);
	end
end
function AscendingACManager.syncAllCT()
	local nodeList = DB.findNode("combattracker.list");
	if not nodeList then
		return;
	end
	for _, node in pairs(DB.getChildren(nodeList)) do
		syncNode(node);
	end
end

local function onACOrThacoUpdated(nodeField)
	syncNode(DB.getParent(nodeField));
end

local function registerHandlers()
	DB.addHandler("npc.*.ac", "onUpdate", onACOrThacoUpdated);
	DB.addHandler("npc.*.thaco", "onUpdate", onACOrThacoUpdated);
	DB.addHandler("combattracker.list.*.ac", "onUpdate", onACOrThacoUpdated);
	DB.addHandler("combattracker.list.*.thaco", "onUpdate", onACOrThacoUpdated);
	DB.addHandler("npc", "onChildAdded", function(_, node) syncNode(node); end);
	DB.addHandler("combattracker.list", "onChildAdded", function(_, node) syncNode(node); end);
end

function onInit()
	if AttackThrowManager and AttackThrowManager.isActive and AttackThrowManager.isActive() then
		ChatManager.SystemMessage(
			"2E Ascending AC: 2E Attack Throw is also loaded. Use only one of these extensions.");
	end

	OptionsManager.registerOptionData({
		sKey = "HouseRule_ASCENDING_AC",
		sGroupRes = "option_header_houserule",
		sLabelRes = "ascendingac_option_label",
		tCustom = { default = "on" },
	});

	registerHandlers();

	if Session.IsHost then
		AscendingACManager.syncAllNPCs();
		AscendingACManager.syncAllCT();
	end
end
