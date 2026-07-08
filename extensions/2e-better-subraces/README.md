# 2E Better Subraces

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

**FG Forge Listing:** not yet published

Adds **Proficiencies**, **Non-Weapon Proficiencies (Skills)**, and **Advanced Effects** sections to Subrace records — previously Traits-only — and applies them to a character automatically when that subrace is chosen. Also adds a **Non-Weapon Proficiencies** section to the base Race record itself, activating existing stock character-creation logic that had no UI to author it before now.

---

## Why

In the stock 2E ruleset, a Subrace is a full nested copy of another Race record, embedded in a Race's "Subraces" list. The base Race record has several sections — Subraces, Traits, Proficiencies, and Advanced Effects — but the Subrace record itself only got Traits. That means any weapon/non-weapon proficiency bonus or automated effect that's specific to one subrace (a Mountain Dwarf's extra proficiency, a Drow's innate spell-like effects) had to either live on the *base* Race and apply to every subrace indiscriminately, or be written as unenforced trait text with no mechanical teeth.

Separately, the base Race record was *also* missing a working Non-Weapon Proficiencies (Skills) section — even though `CharManager.addRaceSelect` in the stock ruleset already reads a `nonweaponprof` child list off the Race and applies it to the character. That code path was simply dead: nothing in the stock UI ever let you author `nonweaponprof` entries on a Race record at all.

This extension closes both gaps.

## How It Works

**The UI side** (`campaign/record_race_plus.xml`) patches two stock windowclasses:

- `reference_race_main` (the base Race) gets a new Non-Weapon Proficiencies section, reusing `ref_nonweapon_proficiency` — the exact row class the Class record's own working Non-Weapon Proficiencies section already uses, which links `reference_skill` records. It deliberately does *not* copy the Class record's slot/earn-rate number fields (Initial/Rate) — those represent a level-up spending budget, which doesn't apply here; a Race just grants specific named proficiencies directly, the same way its existing weapon Proficiencies section already works.
- `reference_subrace_main` (Subrace) gets all three missing sections: Proficiencies (`ref_racial_proficiencies` rows, linking `reference_racialproficiency`), the same new Non-Weapon Proficiencies section, and Advanced Effects (`advanced_effects_entry2` rows, sourced from a plain `effectlist` child).

All of these reuse the base Race's/Class's existing record types rather than minting new "subracial" variants — a proficiency, skill, or effect is functionally identical regardless of what grants it, so there's nothing to gain from a parallel type. No new strings were needed either; every header reuses an existing stock string resource (`race_header_proficiencies`, `class_header_nonweaponproficiencies`, `char_abilities_label_advancedeffects`).

**The character-apply side is two different stories:**

- **Base Race**: nothing to do. `CharManager.addRaceSelect` already loops the race's `nonweaponprof` list and applies it — it just had no data to read before this extension added the UI to author it.
- **Subrace**: `scripts/manager_subrace_plus.lua` wraps `CharManager.addRaceSelect`. The original function already applies the base race's own proficiencies, non-weapon proficiencies, and effects, but for the subrace it only ever looped its `traits` list. The wrap calls the original function first (unchanged base-race and subrace-trait behavior), then re-derives which subrace was picked using the same selection data the original function already builds internally, and applies that subrace's own `proficiencies`, `nonweaponprof`, and `effectlist` using `CharManager`'s own generic helpers — `addWeaponProficiencies`, `addClassProficiencyDB`, and `addEffectFeature` — the same functions the stock code already uses for the base race. No proficiency/effect-granting logic was reimplemented; this only feeds the subrace's data through machinery that already exists.

## Usage

1. Open any Race or Subrace record with the extension loaded.
2. Race records now show a **Non-Weapon Proficiencies** section below the existing weapon Proficiencies. Subrace records now show all three: Proficiencies, Non-Weapon Proficiencies, and Advanced Effects, below Traits.
3. Drag a Skill reference record into Non-Weapon Proficiencies, a proficiency reference into Proficiencies, or author Advanced Effects entries directly — same as you already would on a Race.
4. When a character is given that Race and picks a specific subrace (or it's auto-selected, if the race has only one), everything authored on both the base race and the chosen subrace applies together.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- Purely additive — doesn't remove or replace any stock functionality, only wraps `CharManager.addRaceSelect` and appends to `reference_race_main`/`reference_subrace_main`'s existing sheetdata
- No new strings — every new section header reuses an existing stock 2E string resource

## Installation

Drop the `2e-better-subraces` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
