# 2E ADV/DIS — Advantage & Disadvantage

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Adds Advantage/Disadvantage roll mechanics — roll the die twice, keep the favorable result — to all four 2E roll types: attacks, saving throws, ability checks, and skill checks, including percentile (d100) checks. Also restyles the stock 10-button modifier stack into an 8-button layout: ADV/DIS, +1/-1, +2/-2, +3/-3, +5/-5.

## How to Use

1. Open the Modifier Stack panel — it now shows 8 buttons: **ADV**/**DIS**, **+1**/**-1**, **+2**/**-2**, **+3**/**-3**, **+5**/**-5**.
2. Click ADV or DIS before making a roll (or drag the button to a hotkey), same as any other modifier button.
3. Make any attack, save, ability check, or skill check as normal, including percentile checks. The chat log shows both dice rolled, with the discarded one greyed out and the kept one tagged `[ADV]` or `[DIS]`.
4. For ability/skill checks specifically, Advantage keeps the *lower* roll (since those succeed on a roll under the target) — the chat tag still correctly reads `[ADV]`, matching what you clicked.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Compatible with "AD&D Options and House Rules" — when its "Ability Check Dice" option is set to 3d6/4d6, ADV/DIS has no effect on ability checks (deliberately out of scope for that mode)
- Composes automatically with the Target 20 and Skill Throw extensions if also installed — neither is required
