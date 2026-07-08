# 2E ADV/DIS - Advantage & Disadvantage

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

**FG Forge Listing:** not yet published

Adds Advantage/Disadvantage roll mechanics — roll 2d20, keep the favorable one — to all four 2E d20 roll types: attacks, saves, ability checks, and skill checks. No stock ruleset file is modified.

---

## Why a Separate Extension from Target 20

This was originally considered as one combined extension with a planned "Target 20" companion (which converts ability/skill checks from 2E's native roll-under mechanic to a unified roll-over-vs-20 system). They were kept separate so each is independently installable — you shouldn't have to adopt one house rule to get the other. Instead, this extension defensively checks whether Target 20 is active (a `Target20Manager.isActive()` check, harmless if that extension isn't installed) and adjusts its own behavior accordingly — same cross-extension pattern already used between `steadfast5e_grr` and `steadfast5e_ls`.

## How It Works

**The mechanic itself is not reimplemented** — CoreRPG already has a fully generic "roll 2d20, keep the favorable one" implementation (`ActionD20.encodeAdvantage`/`decodeAdvantage` in `manager_action_d20.lua`), the same code 5E's own Advantage/Disadvantage runs on. It's available to any ruleset built on CoreRPG, including 2E, with zero 5E dependency.

**The hook point is also already generic.** Every 2E roll type (attack, save, ability check, skill check) funnels through the same CoreRPG roll engine (`ActionsManager.performAction`), which fires wildcard extension hooks (`onActionPreModRoll`/`onActionPreOnRoll` via `GameManager.setMultiKeyFunction(..., "", fn)`) before/after every single roll of every type, regardless of ruleset. This extension registers exactly two such hooks in `onInit` — nothing in any stock 2E file needs to be touched at all.

**The one thing 2E actually needs that doesn't come for free:** ability and skill checks in 2E are roll-UNDER (rolling lower succeeds), the opposite of every roll type 5E/CoreRPG assume ("advantage" always means "keep the higher die" in the stock implementation). For those two roll types specifically, this extension keeps the **lower** of the two d20s on Advantage instead — mechanically correct, but with one real gotcha:

> `ModifierManager.getKey(sKey)` is **not idempotent** — reading it consumes/clears the toggle. This extension can't just read the ADV/DIS keys, swap them, and then also call the stock `ActionD20.encodeAdvantage()` — that function does its own separate `getKey()` read, which would find the keys already cleared by the first read and silently do nothing. Instead, for roll-under checks/skills, this extension reads both raw keys itself exactly once, swaps them, and replicates `encodeAdvantage`'s small amount of die-duplication logic directly. If this code is ever "simplified" back to calling `encodeAdvantage()` unconditionally, Advantage/Disadvantage will silently stop working on ability/skill checks specifically — this is the one thing to be careful about if touching `manager_advdis.lua` later.

Because `decodeAdvantage()` (the resolution half) only reads the already-set `bADV`/`bDIS` flags and never touches `ModifierManager` again, it can always be called unmodified — the only cleanup needed is a one-time text swap on the chat message (`[ADV]`↔`[DIS]`) for the inverted case, since `decodeAdvantage` labels the roll based on the internal (swapped) flags, which would otherwise show the opposite of what the player actually clicked.

## Usage

1. Open the Modifier Stack panel — it now has **ADV**/**DIS** buttons alongside the existing +1..+5/-1..-5 ones.
2. Click ADV or DIS before making a roll (or drag the button to your hotkey bar, same as the existing modifier buttons).
3. Make any attack, save, ability check, or skill check roll as normal. The chat log will show both d20s, with the dropped one greyed out and the kept one tagged `[ADV]` or `[DIS]`.
4. For ability/skill checks specifically, Advantage keeps the *lower* roll (since lower succeeds in 2E) — the chat tag still correctly reads `[ADV]`, matching what you clicked, even though internally a different die is kept than it would be for an attack roll.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Purely additive — no stock ruleset file is edited; hooks are registered via CoreRPG's own generic wildcard extension points
- Compatible with `AD&D Options and House Rules.ext`'s "Ability Check Dice" option (1d20/3d6/4d6): this extension only affects rolls with exactly one `d20` die, so it automatically and safely does nothing when that option is set to 3d6/4d6 for ability checks — no special-case code needed
- Designed to compose with a future Target 20 extension via a defensive `Target20Manager.isActive()` check (not required to be installed)

## Installation

Drop the `2e-advdis` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
