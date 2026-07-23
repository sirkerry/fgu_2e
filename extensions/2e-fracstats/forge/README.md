# 2E Fractional Ability Scores

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Extends stock 2E's "exceptional strength" idea (18/01–18/00) to every ability score, at every value from 1–25: each whole score gets an `XX/01-50` and `XX/51-00` bracket, driven by the same percentile roll already entered on the character sheet. Inspired by HackMaster 4E's half-step ability tables.

## How to Use

No setup needed — just enable the extension and load a 2E campaign:

1. Enter an ability score and its percentile value on the character sheet exactly as you already would (this is stock 2E's existing percentile field, used for every ability now instead of just Strength).
2. All derived stats for that ability — hit/damage adjustments, weight allowance, system shock, spell level, loyalty, reaction, and so on — automatically shift between the lower-half and upper-half bracket based on whether the percentile is 50 or below, or above 50.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Not compatible with other extensions that also override ability-score derived-stat calculations (e.g. a "HackMaster Stats" toggle in another extension) — whichever loads last wins
