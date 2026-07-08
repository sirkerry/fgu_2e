# 2E Target 20

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

**FG Forge Listing:** not yet published

Converts 2E's roll-under ability and skill checks to a unified **d20 + bonus >= 20** system. Saving throws and attacks are completely untouched.

---

## The Two Formulas

- **Ability checks**: `d20 + Table 44 ability modifier + character level >= 20`
- **Skill/proficiency checks** (ability-linked only, not percentile): `d20 + Table 44 ability modifier + character level + (Class + Stat + Racial + Armor + Skill + Miscellaneous modifiers) >= 20`

**Table 44** ("Ability Modifiers to Proficiency Scores", *Player's Option: Skills and Powers*, p.89) replaces the raw 3-18 ability score with a small, bounded modifier:

| Score | Mod | | Score | Mod |
|---|---|---|---|---|
| 3 | −5 | | 14 | +1 |
| 4 | −4 | | 15 | +2 |
| 5 | −3 | | 16 | +3 |
| 6 | −2 | | 17 | +4 |
| 7 | −1 | | 18+ | +5 |
| 8–13 | 0 | | | |

**Character level** is flat and uncapped — a character's full level is added directly, no fraction or cap. This is a deliberate choice: high-level characters become very reliable at checks tied to their trained abilities, similar in spirit to how 5E's proficiency bonus scales, just steeper.

The six skill modifiers (Class/Stat/Racial/Armor/Skill/Miscellaneous) are exactly the fields already visible on every skill's own record in the stock ruleset — Target 20 doesn't invent new ones, it just adds them to a different formula.

## Why Ability Checks and Skill Checks Need Different Implementation Approaches

**Ability checks** are simple to override: at the point this extension's mod handler runs, `rRoll.nTarget` still holds the character's raw ability score (nothing has touched it yet — the stock UI just passes the raw score straight through). We read it, look it up in Table 44, add character level, and set `nTarget` to a flat 20.

**Skill checks** need one more step. Unlike ability checks, the roll structure (`rRoll`) that reaches a mod handler never carries a reference back to the skill's own database record — only a single pre-summed number (2E's stock code already adds Class/Stat/Racial/Armor/Skill/Misc plus the raw ability score into one cached `total` field before the roll even starts). There's no way to decompose that sum back into its parts from a mod handler alone. So instead, this extension patches `ActionSkill.getRoll` directly — the one function that *does* receive the skill's own database node — and computes the correct bonus there, reading each of the six modifier fields individually alongside the ability score and level.

**Known limitation from this difference:** ability checks preserve 2E's existing CHECK-effect-tag bonus system (a temporary spell or condition granting "+2 to Strength checks" still applies, since this extension calls the stock modifier logic first and only adjusts the result afterward). Skill checks do **not** get this treatment in this version — a magical effect granting a bonus to a specific skill won't currently apply under Target 20. This wasn't a deliberate design goal to skip, just a real complexity tradeoff for this first version, given skill effect-bonus gathering happens in a different function than the one with database access. Worth revisiting if it turns out to matter in play.

## What's Left Alone

- **Percentile skills** (thief skills, etc. — anything with `stat == "percent"`) roll exactly as before, under their own `base_check` on d100. Table 20 doesn't have a natural mapping onto a 0–100 scale, so this extension doesn't attempt one.
- **Saving throws and attack rolls** are never touched at all.
- **`AD&D Options and House Rules.ext` compatibility**: that extension's "Ability Check Dice" option can swap ability checks to a 3d6 or 4d6 pool instead of 1d20. Target 20 only activates on rolls made of exactly one `d20` die — if that option has switched to 3d6/4d6, this extension leaves the roll alone and lets that extension's own mechanic run unmodified, rather than producing a nonsensical mixed result.

## Composing with `2e-advdis`

This extension exposes a global `Target20Manager.isActive()` (always `true` while installed — no toggle). `2e-advdis` (Advantage/Disadvantage) already defensively checks for this exact function: if Target 20 is active, ability/skill checks are roll-over just like everything else, so `2e-advdis` skips its own roll-under inversion logic (which otherwise keeps the *lower* of two d20s on Advantage) and behaves like a normal "keep the higher roll" mechanic instead. Neither extension requires the other to be installed.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- No stock ruleset file is edited — hooks are registered via `ActionsManager.registerModHandler`/`registerResultHandler` (re-registering after the base ruleset's own `onInit` cleanly overwrites the stock handlers, standard extension load order) and one direct monkey-patch of `ActionSkill.getRoll`

## Installation

Drop the `2e-target20` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
