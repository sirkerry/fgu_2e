# 2E Ascending AC

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Turns on AD&D 2E's own Ascending AC house rule and fixes the character sheet displays that stock 2E leaves half-finished when that rule is used.

## What It Does

- Registers **House Rule: Ascending AC** under Options → House Rules (GM), on by default.
- With the option on: the PC combat-score box shows **BAB** instead of THAC0, the NPC sheet's AC/THAC0 fields display and accept ascending values (unarmored = 10, better armor = higher), and the PC's Attack Matrix switches to an ascending-AC column layout.
- With the option off, everything shows exactly as stock 2E always has (THAC0, descending AC).

Conversion used throughout: `ascending = 20 − descending` (for descending scores under 10), `BAB = 20 − THAC0`.

## How to Use

1. Enable the extension and load a 2E campaign.
2. Open **Options → House Rules (GM)** and toggle **Ascending AC** on or off as desired (on by default).
3. Character sheets, NPC sheets, and the Attack Matrix update their labels and values automatically based on the option.
4. When entering an NPC's AC or attack score by hand while the option is on, type the ascending value — it converts and stores correctly under the hood.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- **Do not load together with 2E Attack Throw** — that extension uses its own AC 0 = unarmored / Attack Throw system, a different and incompatible presentation. Both extensions warn in chat if the other is also loaded.
