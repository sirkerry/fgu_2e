--
-- 2E Explosive Damage
--
-- Classic exploding-dice house rule: when a damage die rolls its maximum
-- value, reroll it and add the new result, repeating if it explodes
-- again. Applies to all damage rolls - weapons and spells alike.
--
-- Weapon damage (char_weapon.lua/npc_weapons_ct.lua/manager_weapons_adnd.lua)
-- calls ActionDamage.performRoll(draginfo, rActor, rAction) directly.
-- Spell/power damage does NOT go through performRoll at all - PowerManager
-- .performAction (manager_power.lua:600,607) calls ActionDamage.getRoll
-- directly and batches the result via ActionsManager.performMultiAction,
-- bypassing performRoll entirely. So both functions need patching. Both
-- build rAction.clauses before running; we flag every clause with
-- bExplodeCompound = true before delegating to the original - this is
-- read by CoreRPG's own ActionDamageD20.getRoll (via
-- DiceRollManager.addDamageDice) and sets each die's native "e!"
-- (compound explode) mode, the same ruleset-agnostic mechanism 4E's
-- "Vorpal" weapon property uses. No custom reroll/recursion logic needed
-- - FGU's dice engine handles it.
--
-- Known limitation: 2E's default critical-hit dice-doubling
-- (ActionDamageD20.applyModCriticalDoubleDice) does not thread
-- bExplodeCompound through to the doubled dice, so on a critical hit the
-- extra doubled dice won't themselves explode - only the original dice
-- will. This is a gap in that stock CoreRPG function, not something
-- fixable here without editing a shared CoreRPG file.
--

local Original_ActionDamage_performRoll = nil;
local Original_ActionDamage_getRoll = nil;

local function flagClausesExplodeCompound(rAction)
	for _, tClause in ipairs(rAction.clauses or {}) do
		tClause.bExplodeCompound = true;
	end
end

local function performRoll(draginfo, rActor, rAction)
	flagClausesExplodeCompound(rAction);
	Original_ActionDamage_performRoll(draginfo, rActor, rAction);
end

local function getRoll(rActor, rAction)
	flagClausesExplodeCompound(rAction);
	return Original_ActionDamage_getRoll(rActor, rAction);
end

function onInit()
	Original_ActionDamage_performRoll = ActionDamage.performRoll;
	ActionDamage.performRoll = performRoll;

	Original_ActionDamage_getRoll = ActionDamage.getRoll;
	ActionDamage.getRoll = getRoll;
end
