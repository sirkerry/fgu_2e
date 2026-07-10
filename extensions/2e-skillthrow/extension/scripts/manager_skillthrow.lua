--
-- 2E Skill Throw
--
-- Adds a "+" (Throw) option to the 2E skill/proficiency Type cycler,
-- alongside the stock ability-linked options and the existing "%"
-- (percentile) option. Modeled on ACKS II's Proficiency Throw: roll 1d20
-- + modifiers, success on total >= a flat target number entered directly
-- on the skill (the "Base Check" field, reused from the percentile UI -
-- see campaign/record_char_skills_skillthrow.xml). ACKS proficiency
-- throw targets are hardcoded per-proficiency in the book rather than
-- derived from a formula, so unlike 2E Target 20 there's no ability-
-- score/level computation here - the character's own Base Check plus the
-- usual adjustment fields (already summed into "total" by
-- number_charskill_skillthrow.lua) ARE the target, verbatim.
--
-- COMPATIBILITY
-- =============
-- 2E Target 20: its getRoll_skill only converts ability-linked skills.
-- It was patched to whitelist strength/dexterity/.../charisma explicitly
-- (previously it blacklisted only "" and "percent"), so a "throw" skill
-- no longer falls through into its Table 44 lookup using a nonexistent
-- "throw" ability score. See that extension's manager_target20.lua.
--
-- 2E ADV/DIS: needs to know a throw skill rolls high (not roll-under)
-- even when Target 20 isn't installed. Rather than probing for another
-- extension's presence, this stamps rRoll.bSkillThrow = true on
-- conversion (mirroring Target20's own rRoll.bTarget20 flag), and advdis
-- was updated to check both flags directly on the roll instead of asking
-- "is Target20Manager active". See that extension's manager_advdis.lua.
--
-- CHAINING
-- ========
-- getRoll: plain global reassignment (ActionSkill.getRoll = ...), the
-- same technique Target20 uses - each wrapper captures whatever
-- ActionSkill.getRoll currently is before overwriting it, so this chains
-- correctly regardless of install order.
--
-- modRoll/onRoll: these dispatch from a single-slot registry
-- (ActionsManager.registerModHandler/registerResultHandler - the last
-- registration wins, it does NOT chain automatically) rather than a
-- plain global, so instead of hardcoding "the stock function" as
-- Original, this captures whatever is CURRENTLY registered via
-- ActionsManager.getModHandler/getResultHandler at onInit time and
-- always delegates to that for rolls it doesn't own. That's the piece
-- Target20 was missing (it hardcoded ActionSkill.modRoll/onRoll
-- directly, silently orphaning whichever of the two extensions loaded
-- first) - patched there too, so the two extensions compose correctly no
-- matter which one loads first.
--

local Original_ActionSkill_getRoll = nil;

local function deliverSkillThrowMessage(rSource, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nTotal = ActionsManager.total(rRoll);
	local nTargetDC = tonumber(rRoll.nTarget) or 0;
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

-- Bypasses Original_ActionSkill_getRoll entirely for "throw" skills,
-- rather than calling it and patching the result (the way Target20 does
-- for ability-linked skills) - stock getRoll assumes any non-"",
-- non-"percent" stat is a real ability name and indexes
-- DataCommon.ability_ltos[sAbility] unguarded while building sDesc, which
-- is nil (and therefore a concat error) for "throw".
local function getRoll_skillthrow(rActor, nodeSkill, nTargetDC, bSecretRoll)
	local sAbility = DB.getValue(nodeSkill, "stat", "");
	if sAbility ~= "throw" then
		return Original_ActionSkill_getRoll(rActor, nodeSkill, nTargetDC, bSecretRoll);
	end

	local sSkill = DB.getValue(nodeSkill, "name", "");
	return {
		sType = "skill",
		sDesc = ActionCore.encodeActionText({ label = sSkill }, "action_skill_tag"),
		aDice = DiceRollManager.getActorDice({ "d20" }, rActor),
		nMod = 0,
		-- nTargetDC arrives already summed (Base Check + Class/Armor/
		-- Racial/Stat/Misc adjustments) from number_charskill_skillthrow.
		-- lua's "total" - nothing left to add here.
		nTarget = nTargetDC,
		bSecret = bSecretRoll,
		bSkillThrow = true,
	};
end

function onInit()
	Original_ActionSkill_getRoll = ActionSkill.getRoll;
	ActionSkill.getRoll = getRoll_skillthrow;

	local fPrevModHandler = ActionsManager.getModHandler("skill");
	ActionsManager.registerModHandler("skill", function(rSource, rTarget, rRoll)
		if fPrevModHandler then
			fPrevModHandler(rSource, rTarget, rRoll);
		end
		if rRoll.bSkillThrow then
			-- Whatever we just delegated to (stock, or Target20's own
			-- chained handler) applied 2E's roll-under sign flip
			-- unconditionally - undo it here. Throw skills roll HIGH, so
			-- a positive bonus should add to the roll normally. This
			-- still picks up SKILL-tag effect bonuses (e.g. a magic item
			-- granting "+2 Lockpicking") along the way, since those are
			-- gathered by the same delegated call before the flip.
			rRoll.nMod = -(rRoll.nMod);
		end
	end);

	local fPrevResultHandler = ActionsManager.getResultHandler("skill");
	ActionsManager.registerResultHandler("skill", function(rSource, rTarget, rRoll)
		if rRoll.bSkillThrow then
			deliverSkillThrowMessage(rSource, rRoll);
			return;
		end
		if fPrevResultHandler then
			fPrevResultHandler(rSource, rTarget, rRoll);
		end
	end);
end
