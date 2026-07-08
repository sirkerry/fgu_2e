# 2E ADV/DIS - Advantage & Disadvantage

![2E ADV/DIS](forge/2e-advdis.png)

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

**FG Forge Listing:** not yet published

Adds Advantage/Disadvantage roll mechanics — roll the die twice, keep the favorable result — to all four 2E roll types: attacks, saves, ability checks, and skill checks, including percentile (d100) ability/skill checks. Also restyles 2E's stock 10-button modifier stack (+1..+5/-1..-5) into an 8-button layout: ADV/DIS, +1/-1, +2/-2, +3/-3, +5/-5 (5E-style wider buttons; +4/-4 dropped by choice).

---

## Why a Separate Extension from Target 20

This was originally considered as one combined extension with a planned "Target 20" companion (which converts ability/skill checks from 2E's native roll-under mechanic to a unified roll-over-vs-20 system). They were kept separate so each is independently installable — you shouldn't have to adopt one house rule to get the other. Instead, this extension defensively checks whether Target 20 is active (a `Target20Manager.isActive()` check, harmless if that extension isn't installed) and adjusts its own behavior accordingly — same cross-extension pattern already used between `steadfast5e_grr` and `steadfast5e_ls`.

## How It Works

**The mechanic itself is not reimplemented** — CoreRPG already has a fully generic "roll the die twice, keep the favorable one" implementation (`ActionD20.encodeAdvantage`/`decodeAdvantage` in `manager_action_d20.lua`), the same code 5E's own Advantage/Disadvantage runs on. It duplicates whatever `aDice[1]` happens to be and compares the two rolled results — no dependency on die type baked in — so it works identically for d20 or d100 rolls. It's available to any ruleset built on CoreRPG, including 2E, with zero 5E dependency.

**Percentile (d100) rolls are supported too**, deliberately using this same "roll twice, keep favorable" method rather than d100-specific alternatives like Tens-Die-Only substitution or digit flipping — simplest to reason about and consistent with how every other roll type here works. This also covers 2E's "reverse" percentile ability checks (e.g. Strength open-doors %) correctly without any special-casing: those pre-transform the target via `100 - value` before rolling, but the actual roll comparison is still the same roll-under test as everything else, so they fall under the same roll-under handling described below.

**The hook point is also already generic.** Every 2E roll type (attack, save, ability check, skill check) funnels through the same CoreRPG roll engine (`ActionsManager.performAction`), which fires wildcard extension hooks (`onActionPreModRoll`/`onActionPreOnRoll` via `GameManager.setMultiKeyFunction(..., "", fn)`) before/after every single roll of every type, regardless of ruleset. This extension registers exactly two such hooks in `onInit` — nothing in any stock 2E file needs to be touched at all.

**The one thing 2E actually needs that doesn't come for free:** ability and skill checks in 2E are roll-UNDER (rolling lower succeeds), the opposite of every roll type 5E/CoreRPG assume ("advantage" always means "keep the higher die" in the stock implementation). For those two roll types specifically (d20 or d100 alike), this extension keeps the **lower** die on Advantage instead — mechanically correct, but with one real gotcha:

> `ModifierManager.getKey(sKey)` is **not idempotent** — reading it consumes/clears the toggle. This extension can't just read the ADV/DIS keys, swap them, and then also call the stock `ActionD20.encodeAdvantage()` — that function does its own separate `getKey()` read, which would find the keys already cleared by the first read and silently do nothing. Instead, for roll-under checks/skills, this extension reads both raw keys itself exactly once, swaps them, and replicates `encodeAdvantage`'s small amount of die-duplication logic directly. If this code is ever "simplified" back to calling `encodeAdvantage()` unconditionally, Advantage/Disadvantage will silently stop working on ability/skill checks specifically — this is the one thing to be careful about if touching `manager_advdis.lua` later.

Because `decodeAdvantage()` (the resolution half) only reads the already-set `bADV`/`bDIS` flags and never touches `ModifierManager` again, it can always be called unmodified — the only cleanup needed is a one-time text swap on the chat message (`[ADV]`↔`[DIS]`) for the inverted case, since `decodeAdvantage` labels the roll based on the internal (swapped) flags, which would otherwise show the opposite of what the player actually clicked.

## Usage

1. Open the Modifier Stack panel — it now shows 8 buttons total, in this order: **ADV**/**DIS**, **+1**/**-1**, **+2**/**-2**, **+3**/**-3**, **+5**/**-5**. Only **+4**/**-4** is removed from 2E's original 10 (`merge="delete"` on those two named controls — confirmed surgical against several stock examples, unlike `<tab merge="delete">`, which wipes an entire tab list instead of one tab).
2. Click ADV or DIS before making a roll (or drag the button to your hotkey bar, same as the existing modifier buttons).
3. Make any attack, save, ability check, or skill check roll as normal — including percentile (d100) ability/skill checks. The chat log will show both dice, with the dropped one greyed out and the kept one tagged `[ADV]` or `[DIS]`.
4. For ability/skill checks specifically, Advantage keeps the *lower* roll (since lower succeeds in 2E) — the chat tag still correctly reads `[ADV]`, matching what you clicked, even though internally a different die is kept than it would be for an attack roll.

### Layout Notes

ADV/DIS use 5E's own wider button size (30px, vs 2E's original 22px, which didn't have room for 3-letter text) and sit first, before the numeric modifier buttons, since it's the most commonly used pair. +1/-1 needed a small anchor fix beyond just re-adding it: its stock horizontal offset (17px) was tuned specifically for sitting right next to the wide "Modifier" number field — now that ADV/DIS occupies that spot instead, +1/-1 needed the same offset (6px) every other numeric button pair already uses. +2/+3/+5 needed no changes at all — their anchors cascade based on document/render order, not the literal control name they reference, so re-ordering the sheetdata was enough on its own.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Purely additive — no stock ruleset file is edited; hooks are registered via CoreRPG's own generic wildcard extension points
- Compatible with `AD&D Options and House Rules.ext`'s "Ability Check Dice" option (1d20/3d6/4d6): this extension only affects rolls with exactly one `d20` or `d100` die, so it automatically and safely does nothing when that option is set to 3d6/4d6 for ability checks — no special-case code needed
- **Deliberately scoped to d20/d100 only — 3d6/4d6-mode checks are not supported.** `ActionD20.encodeAdvantage`/`decodeAdvantage` work by duplicating exactly one die and comparing the two individual results; a 3d6/4d6 check already has 3-4 dice in its pool, so naively removing the single-die restriction would produce a broken result (duplicating and comparing just one of the three/four dice while the others pass through unmodified — not a real "advantage on the check"). Supporting this properly would need different logic entirely: duplicate the *whole* dice pool (3d6 → 6d6, two groups of 3), sum each group separately, and keep the better-summing group — conceptually the same "roll twice, keep favorable" idea, just at the pool level instead of the single-die level, and genuinely more code than reusing `ActionD20`. Not built — clicking ADV/DIS before a 3d6/4d6-mode check just does nothing (the button still releases normally; see the dice-shape guard in `manager_advdis.lua`).
- Designed to compose with a future Target 20 extension via a defensive `Target20Manager.isActive()` check (not required to be installed)

## Installation

Drop the `2e-advdis` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
