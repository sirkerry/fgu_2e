--
-- 2E Attack Throws
--
-- Replaces AD&D 2E THACO / to-hit matrices with ACKS II Attack Throws
-- (ACKS II Revised Rulebook, Attack Throws by Level and HD).
--
-- RULES (ACKS II)
-- ===============
--   Roll 1d20 + modifiers. Success when total >= attack_throw + target AC,
--   where AC is ACKS ascending (unarmored = 0, plate = 6). Natural 1 always
--   misses; natural 20 always hits. Bonuses that always apply may be
--   recorded as reductions to the attack throw target (not done here -
--   weapon/ability mods stay as roll modifiers, matching stock 2E).
--
-- ARMOR CLASS (ACKS ascending)
-- ============================
-- ACKS unarmored = AC 0 (higher is better). AD&D 2E stores descending AC
-- (unarmored = 10). Conversion (Compatibility Guide spirit for d20-from-10):
--   ACKS_AC = 10 - AD&D_descending_AC
-- Leather (2E AC 8) -> ACKS 2; plate+shield (2E ~2) -> ACKS ~8.
--
-- Item/component fields stay 2E-style (base 10, negative armor/shield) so
-- modules and inventory still work. Sheets and chat show ACKS AC.
--
-- HIT RESOLUTION
-- ==============
-- Explicit ACKS rule: total >= AttackThrow + target_ACKS_AC
-- (nat 1 miss, nat 20 hit). Stock getDefenseValue still builds the 2E
-- component sum and convertToAscendingAC; we map that to ACKS via
--   acks = stock_ascending_defense - 10
-- which equals 10 - descending_total.
--
-- PROGRESSIONS (ACKS II p.296 / class tables)
-- ===========================================
-- 2E's own four class groups drive the Attack Throw, mapped from 2E class
-- names (not from ACKS's own same-named classes -- see classGroupFromClassName):
--   warrior  - Fighter/ACKS track (fighter/ranger/paladin/barbarian/...)
--   priest   - Crusader-Thief/ACKS track (cleric/druid/priest/shaman/...)
--   rogue    - Crusader-Thief/ACKS track (thief/bard/assassin/monk/...)
--   wizard   - Mage/ACKS track (mage/wizard/illusionist/...)
-- Priest and Rogue currently share the same ACKS Attack Throw numbers
-- (Crusader and Thief print identical tables), but are kept as distinct
-- groups since that's a fact about ACKS, not about the 2E groups.
-- Multiclass: best (lowest) throw among active classes.
-- NPCs: Monster HD column of the same table.
--
-- MANUAL OVERRIDE
-- ===============
-- PC:  combat.attackthrow.manual = 1  -> use combat.attackthrow.score as-is
--      combat.attackthrow.track = "warrior"|"priest"|"rogue"|"wizard" forces one group
-- NPC: attackthrow_manual = 1         -> use attackthrow as-is
--      (also used on CT copies of NPCs)
-- Editing the sheet Throw field sets the manual flag; changing HD / class
-- level recomputes only when manual is off.
--

AttackThrowManager = {};

-- Originals captured at onInit for chaining / restoration awareness
local Original_getTHACO = nil;
local Original_getBaseAttack = nil;
local Original_modAttack = nil;
local Original_onAttack = nil;

-- Default non-proficient / 0-level attack throw (ACKS table row "0*")
local DEFAULT_THROW = 12;

-- Guard so UI onValueChanged handlers don't treat sync writes as user edits
local bSyncing = false;

function AttackThrowManager.isSyncing()
	return bSyncing;
end

-- ---------------------------------------------------------------------------
-- ACKS Armor Class helpers
-- ---------------------------------------------------------------------------

-- AD&D descending AC (10 = unarmored) -> ACKS ascending (0 = unarmored)
function AttackThrowManager.descendingToAcks(nDesc)
	return 10 - (tonumber(nDesc) or 10);
end

-- ACKS ascending -> AD&D descending (for writing NPC/CT ac fields)
function AttackThrowManager.acksToDescending(nAcks)
	return 10 - (tonumber(nAcks) or 0);
end

-- Stock getDefenseValue returns convertToAscendingAC(D) = (D < 10) and (20-D) or D.
-- That value is 10 + ACKS_AC, so ACKS_AC = defenseVal - 10.
function AttackThrowManager.stockDefenseToAcks(nDefenseVal)
	return (tonumber(nDefenseVal) or 10) - 10;
end

-- PC descending total from sheet components (same pieces as stock AC control)
function AttackThrowManager.getPCDescendingAC(nodeChar)
	if not nodeChar then
		return 10;
	end
	local rActor = ActorManager.resolveActor(nodeChar);
	local nDexBonus = 0;
	if rActor and ActorManagerADND and ActorManagerADND.getAbilityBonus then
		nDexBonus = ActorManagerADND.getAbilityBonus(rActor, "dexterity", "defenseadj") or 0;
	end
	local nACTemp = DB.getValue(nodeChar, "defenses.ac.temporary", 0);
	local nACBase = DB.getValue(nodeChar, "defenses.ac.base", 10);
	local nACArmor = DB.getValue(nodeChar, "defenses.ac.armor", 0);
	local nACShield = DB.getValue(nodeChar, "defenses.ac.shield", 0);
	local nACMisc = DB.getValue(nodeChar, "defenses.ac.misc", 0);
	return nDexBonus + nACTemp + nACBase + nACArmor + nACShield + nACMisc;
end

function AttackThrowManager.getPCAcksAC(nodeChar)
	return AttackThrowManager.descendingToAcks(AttackThrowManager.getPCDescendingAC(nodeChar));
end

function AttackThrowManager.getNPCAcksAC(nodeNPC)
	if not nodeNPC then
		return 0;
	end
	-- Prefer live descending "ac" field (modules/statblocks stay 2E-coded)
	local nDesc = DB.getValue(nodeNPC, "ac", 10);
	return AttackThrowManager.descendingToAcks(nDesc);
end

function AttackThrowManager.getAcksAC(rActor)
	local node = ActorManager.getCreatureNode(rActor);
	if not node then
		return 0;
	end
	if ActorManager.isPC(node) or ((DB.getPath(node) or ""):match("^charsheet%.") ~= nil) then
		return AttackThrowManager.getPCAcksAC(node);
	end
	return AttackThrowManager.getNPCAcksAC(node);
end

-- ---------------------------------------------------------------------------
-- ACKS II Attack Throw tables
-- Each entry: { max_level_or_hd, throw }. Tables are scanned top-down; the
-- first row whose max >= the actor's level/HD wins. Levels above the last
-- row keep the last (best) throw.
-- ---------------------------------------------------------------------------

-- Warrior column (also Monster HD shares the throw values via aHDThrows)
local aWarriorThrows = {
	{ 0, 11 },   -- level 0 trained-ish; table lists 0 as 11+, 0* as 12+
	{ 1, 10 },
	{ 3, 9 },
	{ 4, 8 },
	{ 6, 7 },
	{ 7, 6 },
	{ 9, 5 },
	{ 10, 4 },
	{ 12, 3 },
	{ 13, 2 },
	{ 14, 1 },
	-- above 14: stay at 1+ (ACKS fighter table ends here)
};

-- Priest and Rogue (Crusader and Thief in ACKS) print identical Attack
-- Throw columns -- both 2E's Priest and Rogue groups land here.
local aPriestRogueThrows = {
	{ 0, 11 },
	{ 2, 10 },
	{ 4, 9 },
	{ 6, 8 },
	{ 8, 7 },
	{ 10, 6 },
	{ 12, 5 },
	{ 14, 4 },
};

local aWizardThrows = {
	{ 0, 11 },
	{ 3, 10 },
	{ 6, 9 },
	{ 9, 8 },
	{ 12, 7 },
	{ 14, 6 },
};

-- Monster HD column: index by integer HD (special cases handled separately)
-- HD 1/2 or less -> 12+, 1-1 -> 11+, 1 -> 10+, 2 -> 9+, ... 20+ -> -9+
local function throwFromHDInteger(nHD)
	if nHD <= 0 then
		return 12;
	end
	-- HD 1 -> 10+, then -1 per HD up through 20 -> -9+
	local nThrow = 11 - nHD;
	if nThrow < -9 then
		nThrow = -9;
	end
	return nThrow;
end

local function throwFromTable(aTable, nLevel)
	if nLevel == nil then
		return DEFAULT_THROW;
	end
	nLevel = tonumber(nLevel) or 0;
	if nLevel < 0 then
		nLevel = 0;
	end
	local nThrow = DEFAULT_THROW;
	for _, row in ipairs(aTable) do
		nThrow = row[2];
		if nLevel <= row[1] then
			return nThrow;
		end
	end
	return nThrow;
end

-- ---------------------------------------------------------------------------
-- Class name -> 2E class-group mapping
-- ---------------------------------------------------------------------------

-- 2E groups classes into four THAC0 progressions: Warrior, Wizard, Priest,
-- and Rogue. Group membership is what determines the Attack Throw here --
-- NOT "which ACKS class happens to share this name" (ACKS's own Assassin
-- and Bard are Fighter-track by ACKS's own design; that says nothing about
-- 2E's Rogue-group Bard and Assassin). Priest and Rogue are kept as
-- separate name lists even though they currently resolve to the same
-- Attack Throw table (aPriestRogueThrows), since that's a fact about ACKS's
-- table, not about the 2E groups being the same thing.
local aWarriorNames = {
	"fighter", "ranger", "paladin", "barbarian", "cavalier", "archer",
	"berserker", "gladiator", "knight", "warrior", "soldier",
};

local aPriestNames = {
	"cleric", "druid", "priest", "priestess", "shaman", "paladin-cleric",
};

local aRogueNames = {
	"thief", "rogue", "bard", "assassin", "monk", "illusionist-thief",
};

local aWizardNames = {
	"mage", "wizard", "magic-user", "magic user", "illusionist",
	"sorcerer", "warlock", "witch", "necromancer", "elementalist",
};

local function classGroupFromClassName(sName)
	local s = StringManager.trim(sName or ""):lower();
	if s == "" then
		return "priest";
	end
	for _, v in ipairs(aWarriorNames) do
		if s == v or s:find(v, 1, true) then
			return "warrior";
		end
	end
	for _, v in ipairs(aWizardNames) do
		if s == v or s:find(v, 1, true) then
			return "wizard";
		end
	end
	for _, v in ipairs(aPriestNames) do
		if s == v or s:find(v, 1, true) then
			return "priest";
		end
	end
	for _, v in ipairs(aRogueNames) do
		if s == v or s:find(v, 1, true) then
			return "rogue";
		end
	end
	-- Unknown custom class: mid (Priest/Rogue) progression as a safe default
	return "priest";
end

local function throwForGroupAndLevel(sGroup, nLevel)
	if sGroup == "warrior" then
		return throwFromTable(aWarriorThrows, nLevel);
	elseif sGroup == "wizard" then
		return throwFromTable(aWizardThrows, nLevel);
	else
		return throwFromTable(aPriestRogueThrows, nLevel);
	end
end

-- ---------------------------------------------------------------------------
-- NPC HD parsing (mirrors CombatManagerADND.getNPCHitDice spirit)
-- ---------------------------------------------------------------------------

local function parseNPCHD(nodeNPC)
	local sHitDice = DB.getValue(nodeNPC, "hitDice", nil);
	if not sHitDice or sHitDice == "" then
		sHitDice = DB.getValue(nodeNPC, "hd", "1");
	end
	sHitDice = tostring(sHitDice or "1");

	-- Fractions / "1/2" / "½"
	if sHitDice:match("^1%s*/%s*2") or sHitDice == "0.5" or sHitDice:find("½") then
		return 0.5, false;
	end

	local s1, s2, s3 = sHitDice:match("(%d+)([%-+])(%d+)");
	if s1 and s2 and s3 then
		local nBase = tonumber(s1) or 1;
		if s1 == "1" and s2 == "-" then
			-- 1-1, 1-X : ACKS treats 1-1 as its own row (11+)
			return 1, true; -- flag as "1-1" style
		end
		if s2 == "+" then
			-- ACKS: HD with hp bonus rounds up for attack throws
			return nBase + 1, false;
		end
		return nBase, false;
	end

	local nPlain = tonumber(sHitDice:match("(%d+%.?%d*)") or "1") or 1;
	return nPlain, false;
end

function AttackThrowManager.getAttackThrowForNPC(nodeNPC)
	if not nodeNPC then
		return DEFAULT_THROW;
	end
	-- Manual override on the NPC node
	if DB.getValue(nodeNPC, "attackthrow_manual", 0) == 1 then
		return DB.getValue(nodeNPC, "attackthrow", DEFAULT_THROW);
	end

	local nHD, bOneMinus = parseNPCHD(nodeNPC);
	if bOneMinus then
		return 11; -- 1-1
	end
	if nHD <= 0.5 then
		return 12;
	end
	if nHD < 1 then
		return 12;
	end
	return throwFromHDInteger(math.floor(nHD + 0.0001));
end

function AttackThrowManager.getAttackThrowForPC(nodePC)
	if not nodePC then
		return DEFAULT_THROW;
	end

	-- Manual override
	if DB.getValue(nodePC, "combat.attackthrow.manual", 0) == 1 then
		return DB.getValue(nodePC, "combat.attackthrow.score", DEFAULT_THROW);
	end

	local sForcedTrack = StringManager.trim(DB.getValue(nodePC, "combat.attackthrow.track", "") or ""):lower();
	local nBestThrow = nil;

	local aClasses = DB.getChildren(nodePC, "classes");
	if aClasses then
		for _, nodeClass in pairs(aClasses) do
			local bActive = (DB.getValue(nodeClass, "classactive", 1) ~= 0);
			if bActive then
				local nLevel = DB.getValue(nodeClass, "level", 0) or 0;
				if nLevel > 0 then
					local sGroup = sForcedTrack;
					if sGroup ~= "warrior" and sGroup ~= "priest" and sGroup ~= "rogue" and sGroup ~= "wizard" then
						sGroup = classGroupFromClassName(DB.getValue(nodeClass, "name", ""));
					end
					local nThrow = throwForGroupAndLevel(sGroup, nLevel);
					if not nBestThrow or nThrow < nBestThrow then
						nBestThrow = nThrow;
					end
				end
			end
		end
	end

	if nBestThrow then
		return nBestThrow;
	end

	-- No classes: non-proficient 0-level
	return DEFAULT_THROW;
end

local function nodeIsPC(node)
	if not node then
		return false;
	end
	-- ActorManager.isPC accepts creature nodes and CT entries
	if ActorManager.isPC(node) then
		return true;
	end
	-- Fallback: charsheet path
	local sPath = DB.getPath(node) or "";
	return sPath:match("^charsheet%.") ~= nil;
end

function AttackThrowManager.getAttackThrowFromNode(node)
	if not node then
		return DEFAULT_THROW;
	end
	if nodeIsPC(node) then
		return AttackThrowManager.getAttackThrowForPC(node);
	end
	return AttackThrowManager.getAttackThrowForNPC(node);
end

function AttackThrowManager.getAttackThrow(rActor)
	local node = ActorManager.getCreatureNode(rActor);
	return AttackThrowManager.getAttackThrowFromNode(node);
end

function AttackThrowManager.throwToTHACO(nThrow)
	return 10 + (tonumber(nThrow) or DEFAULT_THROW);
end

function AttackThrowManager.throwToBaseAttack(nThrow)
	return 10 - (tonumber(nThrow) or DEFAULT_THROW);
end

-- ---------------------------------------------------------------------------
-- Sync DB fields so the sheet / matrix / any stock DB readers stay coherent
-- ---------------------------------------------------------------------------

function AttackThrowManager.syncNode(node)
	if not node then
		return;
	end

	bSyncing = true;

	local nThrow = AttackThrowManager.getAttackThrowFromNode(node);
	local nTHACO = AttackThrowManager.throwToTHACO(nThrow);
	local nBAB = AttackThrowManager.throwToBaseAttack(nThrow);

	if nodeIsPC(node) then
		if DB.getValue(node, "combat.attackthrow.manual", 0) ~= 1 then
			if DB.getValue(node, "combat.attackthrow.score", DEFAULT_THROW) ~= nThrow then
				DB.setValue(node, "combat.attackthrow.score", "number", nThrow);
			end
		else
			-- Manual: still derive display value from the stored throw
			nThrow = DB.getValue(node, "combat.attackthrow.score", DEFAULT_THROW);
			nTHACO = AttackThrowManager.throwToTHACO(nThrow);
			nBAB = AttackThrowManager.throwToBaseAttack(nThrow);
		end
		if DB.getValue(node, "combat.thaco.score", 20) ~= nTHACO then
			DB.setValue(node, "combat.thaco.score", "number", nTHACO);
		end
		if DB.getValue(node, "combat.bab.score", 0) ~= nBAB then
			DB.setValue(node, "combat.bab.score", "number", nBAB);
		end
	else
		-- NPC library record or CT entry
		if DB.getValue(node, "attackthrow_manual", 0) ~= 1 then
			if DB.getValue(node, "attackthrow", DEFAULT_THROW) ~= nThrow then
				DB.setValue(node, "attackthrow", "number", nThrow);
			end
		else
			nThrow = DB.getValue(node, "attackthrow", DEFAULT_THROW);
			nTHACO = AttackThrowManager.throwToTHACO(nThrow);
			nBAB = AttackThrowManager.throwToBaseAttack(nThrow);
		end
		if DB.getValue(node, "thaco", 20) ~= nTHACO then
			DB.setValue(node, "thaco", "number", nTHACO);
		end
		-- Keep BAB mirror coherent when ascending-AC house rule is used
		if DB.getValue(node, "bab", 0) ~= nBAB then
			DB.setValue(node, "bab", "number", nBAB);
		end
	end

	bSyncing = false;
end

function AttackThrowManager.syncActor(rActor)
	AttackThrowManager.syncNode(ActorManager.getCreatureNode(rActor));
end

function AttackThrowManager.syncAllPCs()
	for _, node in pairs(DB.getChildren(DB.getPath("charsheet"))) do
		AttackThrowManager.syncNode(node);
	end
end

function AttackThrowManager.syncAllNPCs()
	for _, node in pairs(DB.getChildren(DB.getPath("npc"))) do
		AttackThrowManager.syncNode(node);
	end
end

function AttackThrowManager.syncAllCT()
	local nodeList = DB.findNode("combattracker.list");
	if not nodeList then
		return;
	end
	for _, nodeCT in pairs(DB.getChildren(nodeList)) do
		AttackThrowManager.syncNode(nodeCT);
	end
end

function AttackThrowManager.syncAll()
	AttackThrowManager.syncAllPCs();
	AttackThrowManager.syncAllNPCs();
	AttackThrowManager.syncAllCT();
end

-- ---------------------------------------------------------------------------
-- Patched ActionAttack entry points
-- ---------------------------------------------------------------------------

local function getTHACO_attackthrow(rActor)
	local nThrow = AttackThrowManager.getAttackThrow(rActor);
	return AttackThrowManager.throwToTHACO(nThrow);
end

local function getBaseAttack_attackthrow(rActor)
	local nThrow = AttackThrowManager.getAttackThrow(rActor);
	return AttackThrowManager.throwToBaseAttack(nThrow);
end

local function modAttack_attackthrow(rSource, rTarget, rRoll)
	if Original_modAttack then
		Original_modAttack(rSource, rTarget, rRoll);
	end

	if not rRoll or rRoll.bPsionic then
		return;
	end

	-- Re-assert base attack from Attack Throw (stock modAttack already set
	-- nBaseAttack via our patched getBaseAttack, but re-stamp for clarity
	-- and rewrite the THACO tag in the description).
	if rSource then
		local nThrow = AttackThrowManager.getAttackThrow(rSource);
		local nBase = AttackThrowManager.throwToBaseAttack(nThrow);
		rRoll.nBaseAttack = nBase;
		rRoll.bAttackThrow = true;
		rRoll.nAttackThrow = nThrow;

		-- Replace [THACO(N)] / [BAB(N)] with [ATKTHROW(N+)]
		if rRoll.sDesc then
			rRoll.sDesc = string.gsub(rRoll.sDesc, " %[THACO%([^%)]*%)]", "");
			rRoll.sDesc = string.gsub(rRoll.sDesc, " %[BAB%([^%)]*%)]", "");
			rRoll.sDesc = rRoll.sDesc .. " [ATKTHROW(" .. nThrow .. "+)] ";
		end
	end
end

-- ACKS hit resolution + messaging (non-psionic). Mirrors stock onAttack's
-- structure for crit/fumble/effects/post-resolve, but target AC is ACKS
-- ascending and the test is total >= throw + AC.
local function onAttack_attackthrow(rSource, rTarget, rRoll)
	if not rRoll or rRoll.bPsionic then
		if Original_onAttack then
			Original_onAttack(rSource, rTarget, rRoll);
		end
		return;
	end

	local sExtendedText = "";
	rRoll.aMessages = {};

	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus =
		ActorManagerADND.getDefenseValue(rSource, rTarget, rRoll);

	if nAtkEffectsBonus ~= 0 then
		rRoll.nMod = rRoll.nMod + nAtkEffectsBonus;
		rRoll.nTotal = (rRoll.nTotal or ActionsManager.total(rRoll)) + nAtkEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(nAtkEffectsBonus));
	end

	if nDefEffectsBonus ~= 0 then
		nDefenseVal = (nDefenseVal or 0) + nDefEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildDefEffectOutput(nDefEffectsBonus));
	end

	local nThrow = rRoll.nAttackThrow;
	if nThrow == nil and rSource then
		nThrow = AttackThrowManager.getAttackThrow(rSource);
	end
	nThrow = nThrow or DEFAULT_THROW;

	-- Keep BAB bridge coherent for anything that still reads nBaseAttack
	rRoll.nBaseAttack = AttackThrowManager.throwToBaseAttack(nThrow);
	rRoll.bAttackThrow = true;
	rRoll.nAttackThrow = nThrow;

	local nAcksAC = nil;
	local nNeed = nil;
	if nDefenseVal ~= nil then
		nAcksAC = AttackThrowManager.stockDefenseToAcks(nDefenseVal);
		nNeed = nThrow + nAcksAC;
		rRoll.nAcksAC = nAcksAC;
		rRoll.nAttackThrowNeed = nNeed;
	end

	if rTarget ~= nil and nDefenseVal and nDefenseVal ~= 0 then
		local nodeDefender = ActorManager.getCreatureNode(rTarget);
		local sRank = DB.getValue(nodeDefender, "speed.encumbrancerank", "");
		if sRank == "Heavy" or sRank == "Severe" or sRank == "MAX" then
			table.insert(rRoll.aMessages, "[ENC: " .. sRank .. "]");
		end
		table.insert(rRoll.aMessages,
			string.format("[ATKTHROW(%d+) vs AC %d need %d+]", nThrow, nAcksAC, nNeed));
	end

	table.insert(rRoll.aMessages, string.format("[ATKTHROW(%d+)]", nThrow));
	sExtendedText = sExtendedText .. string.format("[ATKTHROW(%d+)]", nThrow);
	if nNeed then
		sExtendedText = sExtendedText .. string.format("[need %d+]", nNeed);
	end

	local sCritThreshold = string.match(rRoll.sDesc or "", "%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end

	rRoll.nFirstDie = 0;
	if rRoll.aDice and #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end

	local nTotal = ActionsManager.total(rRoll);
	rRoll.nTotal = nTotal;

	if rRoll.nFirstDie >= nCritThreshold then
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CRITICAL HIT]");
	elseif rRoll.nFirstDie == 1 then
		rRoll.sResult = "fumble";
		table.insert(rRoll.aMessages, "[MISS-AUTOMATIC]");
		sExtendedText = sExtendedText .. "[MISS-AUTOMATIC]";
	elseif nNeed ~= nil then
		-- ACKS: natural 20 always hits; else total >= throw + AC
		local bHit = (rRoll.nFirstDie == 20) or (nTotal >= nNeed);
		if bHit then
			rRoll.sResult = "hit";
			local sHitText = (rRoll.nFirstDie == 20) and "[HIT-AUTOMATIC]" or "[HIT]";
			table.insert(rRoll.aMessages, sHitText);
			sExtendedText = sExtendedText .. sHitText;
		else
			rRoll.sResult = "miss";
			table.insert(rRoll.aMessages, "[MISS]");
			sExtendedText = sExtendedText .. "[MISS]";
		end
	end

	GameManager.callEventFunctions("onAttackPreResolve", rSource, rTarget, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");
	if not rTarget then
		rMessage.text = rMessage.text .. "\r" .. table.concat(rRoll.aMessages, "\r");
	end
	if (rRoll.sResult or "") == "hit" or (rRoll.sResult or "") == "crit" then
		rMessage.font = "hitfont";
		rMessage.icon = "action_attack_hit";
	elseif (rRoll.sResult or "") == "miss" then
		rMessage.font = "missfont";
		rMessage.icon = "action_attack_miss";
	elseif (rRoll.sResult or "") == "fumble" then
		rMessage.icon = "action_attack_miss";
	end

	-- Deliver results (stock onAttackResolve references an outer sExtendedText
	-- upvalue from its own onAttack; call the pieces directly with ours).
	Comm.deliverChatMessage(rMessage);
	if rTarget then
		local rResults = {};
		rResults.sDMResults = table.concat(rRoll.aMessages, "\r");
		rResults.sWeaponName = rRoll.sWeaponName;
		rResults.sWeaponType = rRoll.sRange;
		rResults.sPCExtendedText = sExtendedText;
		ActionAttack.notifyApplyAttack(rSource, rTarget, rMessage.secret, rRoll.sType, rRoll.sDesc, rRoll.nTotal, rResults);
	end
	if rRoll.sResult == "crit" then
		ActionAttackCore.setCritState(rSource, rTarget);
	end
	if rTarget and (rRoll.sResult == "miss" or rRoll.sResult == "fumble") and rRoll.bRemoveOnMiss then
		TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
	end

	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll);
	GameManager.callEventFunctions("onAttackPostResolve", rSource, rTarget, rRoll);
end

-- ---------------------------------------------------------------------------
-- Handlers: keep scores live as classes / HD change
-- ---------------------------------------------------------------------------

local function onClassFieldUpdated(node)
	-- node is classes.* or a child; walk up to charsheet
	local nodeChar = node;
	while nodeChar and not ActorManager.isPC(nodeChar) do
		nodeChar = DB.getParent(nodeChar);
	end
	if nodeChar then
		AttackThrowManager.syncNode(nodeChar);
	end
end

local function resolveNPCRoot(node)
	if not node then
		return nil;
	end
	local sName = DB.getName(node) or "";
	if sName == "hitDice" or sName == "hd" or sName == "attackthrow"
		or sName == "attackthrow_manual" or sName == "thaco" then
		return DB.getParent(node);
	end
	return node;
end

local function onNPCFieldUpdated(node)
	if bSyncing then
		return;
	end
	local nodeNPC = resolveNPCRoot(node);
	if not nodeNPC then
		return;
	end
	-- HD change drops manual override so the table re-applies
	local sName = DB.getName(node) or "";
	if sName == "hitDice" or sName == "hd" then
		if DB.getValue(nodeNPC, "attackthrow_manual", 0) == 1 then
			DB.setValue(nodeNPC, "attackthrow_manual", "number", 0);
		end
	end
	AttackThrowManager.syncNode(nodeNPC);
end

local function onNPCManualThrowUpdated(node)
	if bSyncing then
		return;
	end
	local nodeNPC = resolveNPCRoot(node);
	if not nodeNPC then
		return;
	end
	if DB.getValue(nodeNPC, "attackthrow_manual", 0) == 1 then
		local nThrow = DB.getValue(nodeNPC, "attackthrow", DEFAULT_THROW);
		bSyncing = true;
		DB.setValue(nodeNPC, "thaco", "number", AttackThrowManager.throwToTHACO(nThrow));
		bSyncing = false;
	else
		AttackThrowManager.syncNode(nodeNPC);
	end
end

local function registerHandlers()
	-- PCs: class level / name / active flag
	DB.addHandler("charsheet.*.classes.*.level", "onUpdate", onClassFieldUpdated);
	DB.addHandler("charsheet.*.classes.*.name", "onUpdate", onClassFieldUpdated);
	DB.addHandler("charsheet.*.classes.*.classactive", "onUpdate", onClassFieldUpdated);
	DB.addHandler("charsheet.*.classes", "onChildAdded", onClassFieldUpdated);
	DB.addHandler("charsheet.*.classes", "onChildDeleted", onClassFieldUpdated);
	DB.addHandler("charsheet.*.combat.attackthrow.manual", "onUpdate", onClassFieldUpdated);
	DB.addHandler("charsheet.*.combat.attackthrow.track", "onUpdate", onClassFieldUpdated);
	DB.addHandler("charsheet.*.combat.attackthrow.score", "onUpdate", function(node)
		if bSyncing then
			return;
		end
		local sPath = DB.getPath(node);
		local sChar = sPath and sPath:match("^(charsheet%.[^.]+)");
		local nodeChar = sChar and DB.findNode(sChar) or nil;
		if nodeChar and DB.getValue(nodeChar, "combat.attackthrow.manual", 0) == 1 then
			local nThrow = DB.getValue(nodeChar, "combat.attackthrow.score", DEFAULT_THROW);
			bSyncing = true;
			DB.setValue(nodeChar, "combat.thaco.score", "number", AttackThrowManager.throwToTHACO(nThrow));
			DB.setValue(nodeChar, "combat.bab.score", "number", AttackThrowManager.throwToBaseAttack(nThrow));
			bSyncing = false;
		end
	end);

	-- Campaign NPC library
	DB.addHandler("npc.*.hitDice", "onUpdate", onNPCFieldUpdated);
	DB.addHandler("npc.*.hd", "onUpdate", onNPCFieldUpdated);
	DB.addHandler("npc.*.attackthrow", "onUpdate", onNPCManualThrowUpdated);
	DB.addHandler("npc.*.attackthrow_manual", "onUpdate", onNPCManualThrowUpdated);
	DB.addHandler("npc", "onChildAdded", function(_, nodeNPC)
		AttackThrowManager.syncNode(nodeNPC);
	end);

	-- Combat Tracker entries (NPCs copy hitDice/thaco onto the CT node)
	DB.addHandler("combattracker.list.*.hitDice", "onUpdate", onNPCFieldUpdated);
	DB.addHandler("combattracker.list.*.hd", "onUpdate", onNPCFieldUpdated);
	DB.addHandler("combattracker.list.*.attackthrow", "onUpdate", onNPCManualThrowUpdated);
	DB.addHandler("combattracker.list.*.attackthrow_manual", "onUpdate", onNPCManualThrowUpdated);
	DB.addHandler("combattracker.list", "onChildAdded", function(_, nodeCT)
		AttackThrowManager.syncNode(nodeCT);
	end);
end

-- ---------------------------------------------------------------------------
-- Public status (for other extensions)
-- ---------------------------------------------------------------------------

function AttackThrowManager.isActive()
	return true;
end

function onInit()
	-- Patch ActionAttack after the ruleset has registered it
	if not ActionAttack then
		return;
	end

	Original_getTHACO = ActionAttack.getTHACO;
	Original_getBaseAttack = ActionAttack.getBaseAttack;
	ActionAttack.getTHACO = getTHACO_attackthrow;
	ActionAttack.getBaseAttack = getBaseAttack_attackthrow;

	-- Chain modAttack so description tags and nBaseAttack stay authoritative.
	-- Capture whatever is currently registered (another extension may already
	-- have wrapped stock) rather than hardcoding ActionAttack.modAttack.
	Original_modAttack = ActionsManager.getModHandler("attack") or ActionAttack.modAttack;
	ActionsManager.registerModHandler("attack", modAttack_attackthrow);

	-- ACKS AC resolution + messaging for normal attacks
	Original_onAttack = ActionsManager.getResultHandler("attack") or ActionAttack.onAttack;
	ActionAttack.onAttack = onAttack_attackthrow;
	ActionsManager.registerResultHandler("attack", onAttack_attackthrow);

	registerHandlers();

	-- Host writes replicate to clients
	if Session.IsHost then
		AttackThrowManager.syncAll();
		DB.addHandler("charsheet", "onChildAdded", function(_, nodeChar)
			AttackThrowManager.syncNode(nodeChar);
		end);
	end
end
