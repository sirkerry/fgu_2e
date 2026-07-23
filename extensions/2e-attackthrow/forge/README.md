# 2E Attack Throw

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Replaces stock THAC0 and its to-hit matrices with **ACKS II Attack Throw** (ACKS II Revised Rulebook — Attack Throws by Level and HD, plus the per-class Fighter / Crusader-Thief / Mage progressions).

## The Rule

1. Look up the attacker's Attack Throw (the N in "N+") from class level or NPC Hit Dice.
2. Roll 1d20 plus modifiers (STR/DEX, weapon, effects, cover, etc).
3. Success if the total is at least Attack Throw + target's AC (ACKS ascending AC, where unarmored = 0).
4. A natural 1 always misses; a natural 20 always hits.

Armor Class is shown and used as ACKS ascending AC (0 = unarmored, higher is better) on both sheets and in attack chat, while inventory and modules continue storing standard 2E descending AC under the hood so existing armor/items keep working unchanged.

## How to Use

1. Enable the extension and load a 2E campaign.
2. Character and NPC sheets show a **Throw** field (the N in N+) instead of THAC0, and AC as ACKS ascending — both derived automatically from class/level or Hit Dice.
3. Make attack rolls as normal; chat shows the result as `[ATKTHROW(N+) vs AC X need Y+]`.
4. The Actions → Combat matrix shows target numbers across the full ACKS ascending AC range for quick reference.
5. To override a Throw value manually, type directly into the Throw field (PC) or NPC's Throw field — this locks it until Hit Dice/level changes are cleared.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Composes with 2E ADV/DIS, 2E Target 20, and 2E Skill Throw — none are required
