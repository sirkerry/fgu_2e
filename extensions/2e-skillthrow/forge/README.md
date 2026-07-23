# 2E Skill Throw

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Adds a third option, **"+" (Throw)**, to the Type cycler on every skill/proficiency row, alongside the stock ability abbreviations (str/dex/con/int/wis/cha) and the existing "%" (percentile) option. Modeled on ACKS II's Proficiency Throw: roll 1d20 + modifiers, success if the total is at least the target.

## How to Use

1. Open a skill/proficiency record and set its **Type** to **+**.
2. Enter the proficiency's target number (as written in its source material) into the **Base Check** field — the same field percentile skills already use.
3. Roll the skill as normal: it rolls 1d20 plus the usual Class/Stat/Racial/Armor/Skill/Miscellaneous adjustments, and succeeds if the total meets or beats the Base Check target.

Per-level scaling written into a proficiency's description (e.g. "18+, reduces 1/level") is not automated — adjust Base Check by hand as a character levels, if the specific proficiency calls for it.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Composes with 2E Target 20 and 2E ADV/DIS if also installed — neither is required
- Percentile ("%") and ability-linked skills are completely unaffected
