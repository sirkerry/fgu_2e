# 2E - Exploding Damage

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

**FG Forge Listing:** not yet published

Classic exploding-dice house rule for **all** damage rolls — weapons and spells alike. When a damage die rolls its maximum possible value, it rerolls and adds the new result to the total, repeating if the reroll also explodes.

---

## The Mechanic

Every damage roll (weapon or spell) has each of its dice flagged to use FGU's own native **compound-explode** die mode before the roll happens. Concretely: a `2d6` damage roll becomes, mechanically, the equivalent of rolling `2d6!` — any die that lands on its maximum value (a 6 on a d6, a 4 on a d4, etc.) is automatically rerolled and the new result is added to that die's total, chaining for as long as it keeps exploding.

This isn't custom reroll logic built for this extension — it's a real, existing FGU/CoreRPG dice-engine feature (the same one 4E's "Vorpal" weapon property and Shadowdark's "Momentum" feature use), just switched on for every 2E damage roll instead of gated behind a specific weapon property.

## How It Works

Weapon damage (PC and NPC) calls `ActionDamage.performRoll(draginfo, rActor, rAction)` directly. Spell/power damage does **not** go through that function at all — `PowerManager.performAction` calls `ActionDamage.getRoll` directly instead and batches the result through a multi-action roll, bypassing `performRoll` entirely. So this extension monkey-patches both functions: before delegating to the original, each walks `rAction.clauses` (the list of damage components — base weapon dice, Strength bonus, magic weapon bonus, etc.) and sets `bExplodeCompound = true` on each one. CoreRPG's own damage-roll builder (`ActionDamageD20.getRoll`) already reads that flag per clause and, via `DiceRollManager`, sets each die's native `"e!"` (compound explode) mode — the extension never touches dice results directly or reimplements the reroll-and-add logic itself.

## What This Means in Practice

- **Weapon damage** — melee and ranged, PC and NPC — explodes.
- **Spell damage** — any power/spell dealing damage via the standard damage action — explodes.
- **Normal (non-max) rolls** are completely unaffected — no extra dice, no message changes, until a die actually lands on its maximum.

## Known Limitation: Critical Hits

2E's default critical-hit rule (dice-doubling) is implemented in a shared CoreRPG function (`ActionDamageD20.applyModCriticalDoubleDice`) that builds a fresh set of doubled dice but does not carry the `bExplodeCompound` flag over to them. In practice this means: on a critical hit, the **original** dice in a damage roll will still explode normally, but the **extra doubled dice** added by the critical-hit rule will not themselves explode. This is a gap in that stock CoreRPG function, not something this extension can fix without editing a shared CoreRPG file — which this project avoids on principle. Worth revisiting if it turns out to matter in play.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- No stock ruleset file is edited — monkey-patches of `ActionDamage.performRoll` and `ActionDamage.getRoll`, reusing FGU's own native exploding-dice die mode rather than any custom logic

## Installation

Drop the `2e-expdmg` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
