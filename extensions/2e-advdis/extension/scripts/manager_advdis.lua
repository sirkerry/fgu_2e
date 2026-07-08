--
-- 2E ADV/DIS - Advantage & Disadvantage
--
-- Hooks the generic wildcard extension points every 2E roll (attack,
-- save, ability check, skill check) already fires through
-- (CoreRPG's manager_actions.lua: onActionPreModRoll / onActionPreOnRoll,
-- dispatched via GameManager's "" wildcard subkey) - no stock 2E file
-- needs editing.
--
-- The actual "roll the die twice, keep the favorable one" mechanic is
-- generic CoreRPG code already (ActionD20.encodeAdvantage/decodeAdvantage),
-- not reimplemented here - it duplicates whatever aDice[1] is and
-- compares the two rolled results, with no dependency on die type, so
-- it works identically for d20 or d100 (percentile) rolls. (2E also has
-- percentile-style ability checks, e.g. Strength open-doors % - the
-- "reverse" ones just pre-transform the target via 100-value before
-- rolling; the actual roll comparison is still the same roll-under
-- test as everything else, so no special-casing needed for those.)
--
-- The one thing 2E needs that CoreRPG's own version doesn't provide:
-- ability/skill checks in 2E are roll-UNDER (a lower roll succeeds),
-- the opposite of every roll type CoreRPG/5E assume ("advantage" = keep
-- the higher die). For those two roll types, this keeps the LOWER of
-- the two dice on Advantage instead - regardless of whether the dice
-- involved are d20 or d100.
--

local ROLL_TYPES = { attack = true, save = true, check = true, skill = true };

function onInit()
	GameManager.setMultiKeyFunction("onActionPreModRoll", "", onPreModRoll);
	GameManager.setMultiKeyFunction("onActionPreOnRoll", "", onPreOnRoll);
end

-- ADV/DIS applies to any roll made of exactly one d20 or d100 die -
-- CoreRPG's encodeAdvantage/decodeAdvantage duplicate/compare whatever
-- die type is present, with no d20-specific assumption baked in.
local function isSingleAdvDisDie(rRoll)
	if not (rRoll.aDice and #(rRoll.aDice) == 1) then
		return false;
	end
	local sType = rRoll.aDice[1].type;
	return sType == "d20" or sType == "d100";
end

local function isRollUnderType(rRoll)
	return rRoll.sType == "check" or rRoll.sType == "skill";
end

-- Defensive check for a future, separately-installable "Target 20"
-- extension, which would convert ability/skill checks to roll-OVER vs a
-- flat 20 - if that's active, checks/skills no longer need the roll-under
-- inversion below. Harmless no-op today since Target20Manager doesn't
-- exist yet (same pattern steadfast5e_grr uses for S5E_LocationSystem).
local function isTarget20Active()
	return Target20Manager and Target20Manager.isActive and Target20Manager.isActive();
end

-- onActionPreModRoll is dispatched as (rSource, rTarget, rRoll) - see
-- manager_actions.lua's applyModifiers. Different signature than
-- onPreOnRoll below - don't assume they match.
function onPreModRoll(rSource, rTarget, rRoll)
	if not ROLL_TYPES[rRoll.sType] then
		return;
	end

	if not isSingleAdvDisDie(rRoll) then
		-- Some roll of one of our 4 types didn't come out as a single
		-- d20/d100 die (unexpected today, but keep this defensive rather
		-- than erroring). Still consume the ADV/DIS keys here (read-only,
		-- no die changes) so the button releases from its pressed state
		-- instead of getting stuck "on" - confirmed live 2026-07-08 for
		-- the (now-handled) percentile-skill case: without this, clicking
		-- ADV/DIS before a roll that didn't match left the button
		-- visually depressed forever, since nothing ever read the key to
		-- clear it. Deliberately NOT consumed for action types outside
		-- ROLL_TYPES (damage, heal, init, etc.) - the early return above
		-- already skips those - so a pending ADV/DIS click survives
		-- until an actual attack/save/check/skill roll happens.
		ModifierManager.getKey("ADV");
		ModifierManager.getKey("DIS");
		return;
	end

	if isRollUnderType(rRoll) and not isTarget20Active() then
		-- ModifierManager.getKey() is NOT idempotent - reading a key
		-- consumes/clears it. Read both raw keys exactly once here and
		-- swap them, then replicate ActionD20.encodeAdvantage's own
		-- die-duplication logic directly - do NOT also call
		-- ActionD20.encodeAdvantage(rRoll) afterward, since that would
		-- perform its own separate getKey() read and find the keys
		-- already consumed by this one, silently breaking the mechanic.
		local bRawADV = ModifierManager.getKey("ADV");
		local bRawDIS = ModifierManager.getKey("DIS");
		rRoll.bADV = bRawDIS;
		rRoll.bDIS = bRawADV;

		if (rRoll.bADV and not rRoll.bDIS) or (rRoll.bDIS and not rRoll.bADV) then
			if rRoll.aDice[1] then
				table.insert(rRoll.aDice, 2, UtilityManager.copyDeep(rRoll.aDice[1]));
				rRoll.aDice.expr = nil;
			end
		end
	else
		ActionD20.encodeAdvantage(rRoll);
	end
end

-- onActionPreOnRoll is dispatched as (rSource, rRoll) - NO rTarget, see
-- manager_actions.lua's handleResolution. Confirmed live 2026-07-08:
-- assuming the same 3-arg shape as onPreModRoll above put the real
-- rRoll into rTarget and left rRoll nil, throwing "attempt to index
-- local 'rRoll' (a nil value)" the first time this actually fired.
function onPreOnRoll(rSource, rRoll)
	if not ROLL_TYPES[rRoll.sType] then
		return;
	end

	local bInverted = isRollUnderType(rRoll) and not isTarget20Active();

	ActionD20.decodeAdvantage(rRoll);

	if bInverted then
		-- decodeAdvantage tagged the roll based on the swapped internal
		-- bADV/bDIS above, so its [ADV]/[DIS] chat text is backwards
		-- relative to what the player actually clicked - fix the visible
		-- text only (the dice/total are already correct).
		rRoll.sDesc = rRoll.sDesc:gsub("%[ADV%]", "\1"):gsub("%[DIS%]", "[ADV]"):gsub("\1", "[DIS]");
	end
end
