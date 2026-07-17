# 2E Ascending AC

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Turns on AD&D 2E's own **Ascending AC** house rule and patches the two spots stock left unfinished.

**Do not load together with [2e-attackthrow](../2e-attackthrow/README.md)** (ACKS Attack Throw uses AC 0 = unarmored and its own Attack Throw progressions — a different, incompatible presentation). Both extensions warn in chat if the other is also loaded.

---

## Why this exists

Reading `CoreRPG.pak`/the 2E ruleset directly turned up something surprising: **stock 2E already has the plumbing for ascending AC**, checked throughout shared ADND-family code (`scripts/manager_action_attack.lua`, `campaign/scripts/char_main.lua`, `campaign/scripts/npc_main.lua`, `campaign/template_char.xml`) via `options.HouseRule_ASCENDING_AC`. But nothing ever **registers** that option as a toggle — confirmed by checking `scripts/data_options_adnd.lua`, where it's simply absent, and by checking OSRIC's copy of the same shared code, where the registration line is present but commented out with the developer's own note: `-- this is not a option in AD&D 2e?`. So in a shipped campaign there was no way to ever turn it on.

A throwaway spike extension (just the option registration, nothing else) confirmed live in a test campaign that once the option can actually be set:

- **PC Total AC** already displays correctly ascending (confirmed: leather armor showed AC 12, i.e. `20 - 8`)
- **Attack-roll chat** already shows `[BAB(N)]` instead of `[THACO(N)]`, for both PCs *and* NPCs, and the hit-value math is already computed in ascending terms (`nTotal + BAB`) — all via stock's own `onAttack`, zero custom code needed
- **PC's combat-score box** (the "THACO" box on the Main tab) never actually swaps to show BAB — `char_main.lua` only mirrors the underlying `combat.thaco.score`/`combat.bab.score` DB values, it never touches the visible label or displayed value
- **NPC sheet** has nothing at all: `npc_main.lua` sets `ac.setVisible(not bOptAscendingAC)` when the option is on, hiding the AC/THACO fields, but the `ac_ascending`/`bab` replacement controls it references are commented out and don't exist in `record_npc.xml`

So the attack pipeline needed **zero** reimplementation (an earlier version of this extension fully re-implemented `modAttack`/`onAttack`, which turned out to be unnecessary duplication of already-correct stock logic). What's actually needed is much smaller: register the option, and patch the two display gaps.

---

## What it does

- **Registers `HouseRule_ASCENDING_AC`** (Options → House Rules (GM)), defaulting to **on** — matches how 2E's own other house rules default (`HouseRule_InitEachRound`, `HouseRule_DeathsDoor`, `OPTIONAL_ENCUMBRANCE` are all `default = "on"`). Loading the extension is enough by itself; the option stays a real toggle if a GM wants to switch back without unloading it.
- **PC sheet**: adds a parallel BAB box in the same slot as the THAC0 combat score, visibility-swapped with it based on the option.
- **NPC sheet**: adds the `ac_ascending`/`bab` controls stock never finished wiring up, in the same slot as `ac`/`thaco`, visibility-swapped. `scripts/manager_ascendingac.lua` mirrors `ac`→`ac_ascending` (`20 - ac` when `ac < 10`) and `thaco`→`bab` (`20 - thaco`) globally via `DB.addHandler`, so it works for NPC library records and Combat Tracker entries whether or not a sheet is open — `ac`/`thaco` stay the source of truth (2E descending, matching modules/inventory); the new fields are read-only derived display.
- **Ascending AC Matrix**: adds a small matrix to the character sheet's combat strip (next to Initiative) showing d20-needed (`AC - BAB`) for AC 10–22. Not a stock feature at all — shown only when the option is on.

All of the above is gated on the option (`AscendingACManager.isOn()`), toggling live via `DB.addHandler("options.HouseRule_ASCENDING_AC", ...)` on each affected control — no reload needed.

### Known, scoped-out gap

There's a third spot on the PC sheet, the small "To Hit AC 0 (THACO)" weapon-penalty row (`window_thaco_section`), that still always shows THAC0 regardless of the option. Not touched — out of scope for this pass, listed here so it's not mistaken for an oversight.

---

## Conversion

```
ascending = 20 - descending   (when descending < 10; else leave as-is)
```

This matches stock `ActorManagerADND.convertToAscendingAC` — the same formula stock already uses internally for hit resolution, now also driving the display fields this extension adds.

| 2E (descending) | Ascending |
|----------------:|----------:|
| 10 (unarmored) | **10** |
| 8 (leather) | **12** |
| 5 | **15** |
| 0 | **20** |

---

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- No stock ruleset files edited — `merge="join"` + `super.onInit()`/`super.onClose()` chaining on existing controls, plus a full redefine of `combat_mini_section` (merge can't re-anchor cleanly, same lesson as `2e-attackthrow`)
- Mutually exclusive with `2e-attackthrow`; each warns in chat if the other is loaded
- Exposes `AscendingACManager.isActive()` (extension loaded) and `AscendingACManager.isOn()` (option currently on)

## Status

Registering the option and the PC AC/attack-chat side are confirmed working live via the spike test. The PC combat-score swap, NPC sheet fields, and the matrix's visibility toggle are new in this build and **not yet live-tested** — please verify all three (and check the Matrix's layout when toggled off, since the layout re-anchors to fill the gap) before trusting it in a real campaign.

---

## Installation

Drop `2e-ascendingac` into Fantasy Grounds Unity `extensions/` (or `./deploy.sh` from this folder) and enable it on a 2E campaign.

### Dev workflow

```bash
./deploy.sh
./sync-to-repo.sh
./backup.sh
./build-ext.sh
```
