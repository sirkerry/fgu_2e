# 2E Skill Throw

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Adds a third option, **"+" (Throw)**, to the Type cycler on every skill/proficiency row, alongside the stock ability abbreviations (str/dex/con/int/wis/cha) and the existing "%" (percentile) option. Modeled on ACKS II's **Proficiency Throw**: roll `1d20 + modifiers`, success on `total >= target`.

---

## Why a Flat Target, Not a Formula

ACKS II's Proficiency Throw isn't a single unified formula the way 2E Target 20's Table 44 is - each proficiency in the ACKS II book hardcodes its own target number directly in its writeup (e.g. "Alchemy: identify substance 11+", "Acrobatics: 18+, reduces 1/level"), and only a handful ever apply an ability bonus at all. There's nothing to derive.

So this extension doesn't try to compute a target - it reuses the exact same "Base Check" field the stock ruleset already gives percentile skills for the same reason (a flat, GM-entered number). Set a skill's Type to "+", type the book's target into Base Check, and it behaves exactly like ACKS: `1d20 + Class/Stat/Racial/Armor/Skill/Misc adjustments >= Base Check`.

Per-level scaling (proficiencies written as "18+, reduces 1/level") is intentionally **not** automated in this version - adjust Base Check by hand as a character levels, if the specific proficiency calls for it.

## How It Works

- **Base Check field**: shown for "+" skills exactly as it already is for "%" skills (`char_skill_editor_main`'s stat-cycler visibility script was extended to check for both).
- **Total**: `number_charskill_skillthrow.lua` (a copy of the stock `number_charskill.lua` with one added condition) computes a "+" skill's total from Base Check instead of an ability score, then adds the usual Class/Armor/Racial/Stat/Misc adjustments on top - unchanged from how every other skill type already works.
- **The roll**: `ActionSkill.getRoll` is patched so "+" skills roll `1d20`, keep the pre-summed total as the target, and skip the ability-name lookup stock code performs for every other stat value (see the code comment in `manager_skillthrow.lua` for why that lookup would otherwise crash on a custom stat value).
- **Resolution**: `total >= target` = success, the opposite comparison from 2E's native roll-under.

## Composing with `2e-target20` and `2e-advdis`

Both were updated alongside this extension:

- **2e-target20** only converts ability-linked skills (str/dex/con/int/wis/cha) - it previously did this by *blacklisting* `""` and `"percent"`, which would have let a new "throw" stat fall through into its Table 44 logic (using a nonexistent "throw" ability score). It now *whitelists* the six real ability names instead, so any non-ability stat - "percent", "throw", or anything added later - is left alone automatically.
- **2e-advdis** previously decided "is this roll roll-over" by checking whether the Target20 extension was merely *installed* (`Target20Manager.isActive()`), not whether *this specific roll* was converted. That mismatched percentile skills even before this extension existed. It now checks `rRoll.bTarget20`/`rRoll.bSkillThrow` directly on the roll itself, which both extensions stamp at roll-build time - accurate per-roll, and works with either extension installed alone, together, or neither.
- Because `modRoll`/`onRoll` dispatch through a single-slot registry (last registration wins, not a chain), both this extension and Target20 now capture whatever's *currently* registered via `ActionsManager.getModHandler`/`getResultHandler` and delegate to it, rather than hardcoding "the stock function" - so the two compose correctly regardless of which one loads first.

Neither extension is required to be installed for this one to work.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- No stock ruleset file is edited - one template redefinition (the stat cycler's value list), two `merge="join"` windowclass extensions (Base Check visibility, the total field's attached script), and standard `ActionsManager` hook registration
- Percentile ("%") and ability-linked skills are completely unaffected

## Installation

Drop the `2e-skillthrow` folder into your Fantasy Grounds Unity `extensions/` directory and enable it when loading a 2E campaign.
