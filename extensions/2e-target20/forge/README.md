# 2E Target 20

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Converts 2E's roll-under ability and skill checks to a unified **d20 + bonus ≥ 20** system. Saving throws and attack rolls are completely untouched.

## The Two Formulas

- **Ability checks**: d20 + Table 44 ability modifier + character level ≥ 20
- **Skill/proficiency checks** (ability-linked only, not percentile): d20 + Table 44 ability modifier + character level + the skill's own Class/Stat/Racial/Armor/Skill/Miscellaneous modifiers ≥ 20

Table 44 ("Ability Modifiers to Proficiency Scores," *Player's Option: Skills and Powers*, p.89) converts a raw 3–18 ability score into a small modifier from −5 to +5. Character level is added in full, uncapped.

## How to Use

No setup needed — just enable the extension and load a 2E campaign. Ability checks and ability-linked skill checks are automatically rolled and resolved under the new d20-vs-20 system; everything else (saves, attacks, percentile skills) works exactly as before.

## What's Left Alone

- Percentile skills (thief skills, etc.) still roll d100 against their own Base Check, unaffected.
- Saving throws and attack rolls are never touched.
- With "AD&D Options and House Rules" set to roll ability checks on 3d6/4d6 instead of 1d20, this extension leaves those checks alone and lets that option's own mechanic run.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Composes with 2E ADV/DIS and 2E Skill Throw if also installed — neither is required
