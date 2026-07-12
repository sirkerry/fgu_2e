# 2E Fractional Ability Scores

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Extends stock 2E's "exceptional strength" idea (18/01-18/00) to **every ability score, at every value 1-25**: each whole score gets an `XX/01-50` and `XX/51-00` bracket, driven by the same percentile roll players already enter on the character sheet. Inspired by HackMaster 4E's Table 1A/1B, which apply this half-step bracket to Strength and Dexterity across their full 1-25 range rather than just at 18.

---

## What this does

Stock 2E already tracks a 0-100 percentile value (`abilities.<name>.percenttotal`) for all six abilities and already shows a percentile field for each on the character sheet — but only `getStrengthProperties()` reads it, and only to trigger the classic 18/xx exceptional-strength rule. This extension overrides all six `AbilityScoreADND.getXProperties()` functions so every ability's derived stats (hit/damage adjustments, weight allowance, system shock, spell level, loyalty, etc.) shift between a "lower half" and "upper half" row at every whole score, not just 18.

**Bracket math:** `index = (score * 2) - 1`, `+1` if `percenttotal > 50`. Score 1-25 maps to table index 1-50.

## Where the tables came from

- **Strength, Dexterity**: HackMaster 4E's own books provide this exact half-step table (Table 1A/1B), but this extension does **not** port HackMaster's numbers — it keeps things native to 2E by deriving the 50-row tables from stock 2E's own `aStrength`/`aDexterity[1-25]` (`reference/rulesets/2E/scripts/data_common_adnd.lua`), with the halfway row being the floor-average of each pair of neighboring whole scores' hit/damage/weight/open-doors/bend-bars values.
- **Constitution, Intelligence, Wisdom, Charisma**: no HackMaster (or stock 2E) precedent exists for these, so their halfway rows are generated the same way from stock 2E's own tables. Numeric columns (system shock %, resurrection survival %, poison save, loyalty base, reaction adj, etc.) are floor-averaged between neighboring scores. String/threshold columns that are already step functions in 2E's own tables — Constitution's hit point adjustment, Wisdom's bonus spell list, Intelligence's max spells learnable/illusion immunity — hold at the lower score's value for the `51-00` bracket, since there's no natural "half a bonus spell" to interpolate.
- Score 25's `51-00` bracket duplicates its `01-50` row (no score-26 data to interpolate toward), same as how HackMaster's own Table 1A/1B have no row past a plain "25".
- **Known upstream data quirk, corrected here:** stock `aCharisma[22]` (reaction adjustment) is `1` in `data_common_adnd.lua`, an apparent transcription typo that breaks an otherwise smooth 10→11→12 progression across scores 21-23. This extension's Charisma table uses `11` instead so the interpolated brackets around it don't inherit the dip.

Generated via a one-off script rather than hand-typed, to avoid transcription errors across ~600 values; see `scripts/data_fracstats.lua`'s header comment for the full column layout per ability.

## What's Left Alone

- The character sheet UI itself — every ability's percentile field already existed in stock 2E and was already enterable; this extension only changes what's *done* with that value.
- Ability score ranges/effects handling (`BSTR`/`STR`-style effect tags, `abilityScoreSanity`'s 1-25 clamp) — reused as-is from stock's own logic inside each override.
- Wisdom/Intelligence's high-score tooltip text (bonus spell / illusion immunity descriptions for scores 17+/19+) — these still read from stock's own `DataCommonADND.aWisdom/aIntelligence[score+100]` lookup, since they're just descriptive tooltips, unrelated to the bracket tables here.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- No stock ruleset file is edited — `AbilityScoreADND.getStrengthProperties`/`getDexterityProperties`/`getConstitutionProperties`/`getIntelligenceProperties`/`getWisdomProperties`/`getCharismaProperties` are monkey-patched at `onInit`, each fully reimplemented (not delegating to the original) so the fractional-bracket lookup replaces the old logic outright.
- Not compatible with other extensions that also override these six functions (e.g. `2ePlayerOption`'s optional "Hackmaster Stats" toggle) — whichever loads last wins.

## Installation

Drop the `2e-fracstats` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
