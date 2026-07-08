# 2E Better Subraces

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

**FG Forge Listing:** not yet published

Adds **Proficiencies** and **Advanced Effects** sections to Subrace records — previously Traits-only — and makes them actually apply to a character automatically when that subrace is chosen, matching what already happens for a base Race.

---

## Why

In the stock 2E ruleset, a Subrace is a full nested copy of another Race record, embedded in a Race's "Subraces" list. The base Race record has four sections — Subraces, Traits, Proficiencies, and Advanced Effects — but the Subrace record itself only got Traits. That means any weapon/non-weapon proficiency bonus or automated effect that's specific to one subrace (a Mountain Dwarf's extra proficiency, a Drow's innate spell-like effects) had to either:

- live on the *base* Race and apply to every subrace indiscriminately, or
- be written as unenforced trait text with no mechanical teeth.

This extension closes that gap by giving Subraces the same two missing sections, and wiring character creation to actually read them.

## How It Works

**The UI side** (`campaign/record_subrace_plus.xml`) patches the stock `reference_subrace_main` windowclass, appending a Proficiencies section (`ref_racial_proficiencies` rows, linking `reference_racialproficiency` records — the exact same record type the base Race's own Proficiencies list uses) and an Advanced Effects section (`advanced_effects_entry2` rows, the same generic effects-list widget the base Race uses, sourced from a plain `effectlist` child). Both reuse the base Race's existing record types rather than minting new "subracial" variants — a proficiency or effect is functionally identical regardless of whether it's granted by a race or a subrace, so there's nothing to gain from a parallel type.

**The character-apply side** (`scripts/manager_subrace_plus.lua`) wraps `CharManager.addRaceSelect` — the stock function that actually applies a chosen race+subrace to a character. The original function always applied the base race's own proficiencies and effects, but for the subrace it only ever looped the subrace's `traits` list; there was no data to read for proficiencies/effects because no UI existed to author them. The wrap calls the original function first (unchanged base-race and subrace-trait behavior), then re-derives which subrace was picked using the same selection data the original function already builds internally, and applies that subrace's own `proficiencies` and `effectlist` using `CharManager`'s own generic helpers — `addWeaponProficiencies` and `addEffectFeature` — the same two functions the stock code already uses for the base race. No proficiency/effect-granting logic was reimplemented; this only feeds the subrace's data through machinery that already exists.

## Usage

1. Open any Subrace record (either standalone in the library, or nested inside a Race's Subraces list) with the extension loaded.
2. You'll now see **Proficiencies** and **Advanced Effects** sections below Traits, identical in layout to the base Race's own.
3. Drag proficiency reference records or author Advanced Effects entries the same way you would on a Race.
4. When a character is given that Race and picks that specific subrace (or it's auto-selected, if it's the race's only subrace), the subrace's proficiencies and effects are applied on top of the base race's — same as traits already were.

## Known Limitation

The stock `addRaceSelect` also reads a `nonweaponprof` child list off the base race, but no UI anywhere in the stock ruleset ever authors that data — it's dead code for a shape nothing produces. This extension doesn't mirror it on subraces for the same reason; there'd be nothing to read.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Purely additive — doesn't remove or replace any stock functionality, only wraps `CharManager.addRaceSelect` and appends to `reference_subrace_main`'s existing sheetdata
- No new strings — both new section headers reuse the stock ruleset's own existing string resources (`race_header_proficiencies`, `char_abilities_label_advancedeffects`)

## Installation

Drop the `2e-better-subraces` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
