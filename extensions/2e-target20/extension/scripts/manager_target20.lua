--
-- 2E Target 20
--
-- Converts 2E's roll-under ability/skill checks to a unified
-- d20 + bonus >= 20 system. Saves and attacks are untouched.
--
-- Ability checks (sType="check"): our own registerModHandler/
-- registerResultHandler ("check") replace the stock roll-under mod/
-- result handlers. We call the ORIGINAL modRoll first (this preserves
-- the existing CHECK-effect-tag bonus system, e.g. a spell granting
-- "+2 to Strength checks", for free) then undo its roll-under sign
-- flip and add our own terms. rRoll.nTarget still holds the character's
-- RAW ability score at this point (nothing has overwritten it yet),
-- which we use as the Table 44 lookup key before replacing it with 20.
--
-- Skill checks (sType="skill", ability-linked only - see below): unlike
-- checks, a mod handler never gets a reference to the skill's own DB
-- node, only the pre-summed "total" via rRoll.nTarget - not enough to
-- decompose back into individual Class/Stat/Racial/Armor/Skill/Misc
-- modifiers. So instead we monkey-patch ActionSkill.getRoll (which DOES
-- receive the skill node directly) to set nMod/nTarget correctly from
-- the start, then register a modRoll that's a no-op once that's already
-- happened (Known limitation: because of this, CHECK/SKILL magical
-- effect-tag bonuses are NOT folded into Target 20 skill checks in this
-- version, unlike ability checks - see README).
--
-- Percentile skills (stat=="percent") are left completely alone - roll
-- under their own base_check on d100, unmodified. AD&D Options and
-- House Rules' "Ability Check Dice" option (1d20/3d6/4d6) is also
-- respected: Target 20 only applies when the roll is a single d20 -
-- if that option has swapped in 3d6/4d6, this extension leaves it
-- alone rather than producing a nonsensical result.
--

-- Player's Option: Skills and Powers, Table 44 "Ability Modifiers to
-- Proficiency Scores" (p.89).
local TABLE44 = {
	{ max = 3,  mod = -5 },
	{ max = 4,  mod = -4 },
	{ max = 5,  mod = -3 },
	{ max = 6,  mod = -2 },
	{ max = 7,  mod = -1 },
	{ max = 13, mod = 0 },
	{ max = 14, mod = 1 },
	{ max = 15, mod = 2 },
	{ max = 16, mod = 3 },
	{ max = 17, mod = 4 },
	-- 18+ falls through to the final return below.
};

local function table44(nScore)
	for _, v in ipairs(TABLE44) do
		if nScore <= v.max then
			return v.mod;
		end
	end
	return 5;
end

local function isSingleD20(rRoll)
	return rRoll.aDice and #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20";
end

-- ── isActive() exposed as Target20Manager.isActive() ────────────────────────
-- (this script is registered as name="Target20Manager" in extension.xml,
-- so any bare global function here is externally reachable that way -
-- 2e-advdis already defensively checks for exactly this.)
function isActive()
	return true;
end

-- ── Ability checks ───────────────────────────────────────────────────────────

local Original_ActionCheck_modRoll = nil;
local Original_ActionCheck_onRoll = nil;

local function deliverTarget20Message(rSource, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nTotal = ActionsManager.total(rRoll);
	local nTargetDC = tonumber(rRoll.nTarget) or 20;
	local nDifference = math.abs(nTotal - nTargetDC);

	rMessage.text = rMessage.text .. " (vs. Target " .. nTargetDC .. ")";
	if nTotal >= nTargetDC then
		rMessage.font = "successfont";
		rMessage.icon = "chat_success";
		rMessage.text = rMessage.text .. " [SUCCESS by " .. nDifference .. "]";
	else
		rMessage.font = "failfont";
		rMessage.icon = "chat_fail";
		rMessage.text = rMessage.text .. " [FAILURE by " .. nDifference .. "]";
	end

	Comm.deliverChatMessage(rMessage);
end

local function modRoll_check(rSource, rTarget, rRoll)
	Original_ActionCheck_modRoll(rSource, rTarget, rRoll);

	if not isSingleD20(rRoll) then
		-- e.g. AD&D Options' Ability Check Dice set to 3d6/4d6 - leave
		-- that extension's own mechanic completely alone.
		return;
	end

	-- Undo the stock roll-under sign flip (see manager_action_check.lua's
	-- own modRoll) so a positive bonus adds normally instead.
	rRoll.nMod = -(rRoll.nMod);

	local nRawAbilityScore = tonumber(rRoll.nTarget) or 0;
	local nAbilityMod = table44(nRawAbilityScore);

	local nodeChar = ActorManager.getCreatureNode(rSource);
	local nLevel = nodeChar and CharManager.getActiveClassMaxLevel(nodeChar) or 0;

	rRoll.nMod = rRoll.nMod + nAbilityMod + nLevel;
	rRoll.nTarget = 20;
	rRoll.bTarget20 = true;
end

local function onRoll_check(rSource, rTarget, rRoll)
	if not rRoll.bTarget20 then
		Original_ActionCheck_onRoll(rSource, rTarget, rRoll);
		return;
	end
	deliverTarget20Message(rSource, rRoll);
end

-- ── Skill checks ──────────────────────────────────────────────────────────

local Original_ActionSkill_getRoll = nil;
local Original_ActionSkill_modRoll = nil;
local Original_ActionSkill_onRoll = nil;

local function getRoll_skill(rActor, nodeSkill, nTargetDC, bSecretRoll)
	local rRoll = Original_ActionSkill_getRoll(rActor, nodeSkill, nTargetDC, bSecretRoll);

	local sAbility = DB.getValue(nodeSkill, "stat", "");
	if sAbility == "" or sAbility == "percent" then
		return rRoll;
	end
	if not isSingleD20(rRoll) then
		return rRoll;
	end

	local nodeChar = DB.getChild(nodeSkill, "...");
	local nAbilityScore = DB.getValue(nodeChar, "abilities." .. sAbility .. ".score", 0);
	local nAbilityMod = table44(nAbilityScore);
	local nLevel = CharManager.getActiveClassMaxLevel(nodeChar) or 0;

	local nAdjSum = DB.getValue(nodeSkill, "adj_class", 0)
		+ DB.getValue(nodeSkill, "adj_armor", 0)
		+ DB.getValue(nodeSkill, "adj_racial", 0)
		+ DB.getValue(nodeSkill, "adj_stat", 0)
		+ DB.getValue(nodeSkill, "adj_mod", 0)
		+ DB.getValue(nodeSkill, "misc", 0);

	rRoll.nMod = nAbilityMod + nLevel + nAdjSum;
	rRoll.nTarget = 20;
	rRoll.bTarget20 = true;

	return rRoll;
end

local function modRoll_skill(rSource, rTarget, rRoll)
	if rRoll.bTarget20 then
		-- getRoll_skill already set the final nMod/nTarget - don't let
		-- the stock modRoll's effect-bonus gathering + roll-under sign
		-- flip touch it.
		return;
	end
	Original_ActionSkill_modRoll(rSource, rTarget, rRoll);
end

local function onRoll_skill(rSource, rTarget, rRoll)
	if not rRoll.bTarget20 then
		Original_ActionSkill_onRoll(rSource, rTarget, rRoll);
		return;
	end
	deliverTarget20Message(rSource, rRoll);
end

-- ── Init ──────────────────────────────────────────────────────────────────

function onInit()
	Original_ActionCheck_modRoll = ActionCheck.modRoll;
	Original_ActionCheck_onRoll = ActionCheck.onRoll;
	Original_ActionSkill_getRoll = ActionSkill.getRoll;
	Original_ActionSkill_modRoll = ActionSkill.modRoll;
	Original_ActionSkill_onRoll = ActionSkill.onRoll;

	ActionsManager.registerModHandler("check", modRoll_check);
	ActionsManager.registerResultHandler("check", onRoll_check);

	ActionSkill.getRoll = getRoll_skill;
	ActionsManager.registerModHandler("skill", modRoll_skill);
	ActionsManager.registerResultHandler("skill", onRoll_skill);
end
