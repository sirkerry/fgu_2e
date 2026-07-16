# 2E Attack Throw

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Replaces stock **THACO** / to-hit **matrices** with **ACKS II Attack Throw** (ACKS II Revised Rulebook — *Attack Throws by Level and HD*, and the per-class Fighter / Crusader-Thief / Mage tables).

---

## The Rule

| Step | What happens |
|------|----------------|
| 1 | Look up the attacker's **Attack Throw** (the N in `N+`) from class level or NPC HD |
| 2 | Roll `1d20` + modifiers (STR/DEX, weapon, effects, cover, …) |
| 3 | Success if **total ≥ Attack Throw + target AC** (ACKS ascending AC: unarmored = 0) |
| 4 | Natural **1** always misses; natural **20** always hits |

**Example (ACKS II):** A 10th-level fighter has Attack Throw `4+`. Unarmored (AC 0) needs 4+; plate (AC 6) needs 10+.

### Armor Class (ACKS ascending)

Sheets and attack chat use **ACKS AC** (0 = unarmored, higher is better).  
Under the hood, inventory/modules still store **2E descending** AC so leather/plate items keep working:

```
ACKS_AC = 10 - 2E_descending_AC
```

| 2E (descending) | ACKS (ascending) |
|----------------:|-----------------:|
| 10 (unarmored) | 0 |
| 8 (leather) | 2 |
| 5 | 5 |
| 2 (plate-ish) | 8 |

PC **AC** total and NPC **AC** field show ACKS values. Editing an NPC's AC is entered as ACKS and converted back for storage.

### Hit resolution

Attacks resolve explicitly as ACKS:

```
need = AttackThrow + target_ACKS_AC
hit if total >= need  (nat 1 miss / nat 20 hit)
```

Chat shows e.g. `[ATKTHROW(10+) vs AC 2 need 12+]`.

---

## Progressions (ACKS II)

| Attack Throw | Fighter level | Crusader / Thief level | Mage level | Monster HD |
|-------------:|:-------------:|:----------------------:|:----------:|:----------:|
| 12+ | 0* (non-proficient) | 0* | 0* | ½ or less |
| 11+ | 0 | 0 | 0 | 1−1 |
| 10+ | 1 | 1–2 | 1–3 | 1 |
| 9+ | 2–3 | 3–4 | 4–6 | 2 |
| 8+ | 4 | 5–6 | 7–9 | 3 |
| 7+ | 5–6 | 7–8 | 10–12 | 4 |
| 6+ | 7 | 9–10 | 13–14 | 5 |
| 5+ | 8–9 | 11–12 | — | 6 |
| 4+ | 10 | 13–14 | — | 7 |
| 3+ | 11–12 | — | — | 8 |
| 2+ | 13 | — | — | 9 |
| 1+ | 14 | — | — | 10 |
| 0+ … −9+ | — | — | — | 11 … 20+ |

\* Non-proficient 0-level (peasants, etc.) use 12+.

### 2E class → track mapping

| Track | 2E classes (name match) |
|-------|-------------------------|
| **Fighter** | fighter, ranger, paladin, barbarian, cavalier, … |
| **Thief** (mid) | thief, rogue, bard, assassin, monk, cleric, druid, priest, … |
| **Mage** | mage, wizard, magic-user, illusionist, sorcerer, warlock, … |

- **Multiclass / multi-class entries:** best (lowest) throw among **active** classes.
- **Unknown class names:** mid (thief) track.
- **NPCs:** Monster HD column (`hitDice` / `hd`); `N+M` HD rounds up for the throw (ACKS hobgoblin 1+1 → 2 HD → 9+).

### Manual override (DB)

| Path | Meaning |
|------|---------|
| `combat.attackthrow.manual` = 1 | PC: use `combat.attackthrow.score` as-is |
| `combat.attackthrow.score` | PC: the N in N+ (also what the sheet shows) |
| `combat.attackthrow.track` | PC: force `"fighter"`, `"thief"`, or `"mage"` for all classes |
| `attackthrow_manual` = 1 | NPC / CT: keep manual throw |
| `attackthrow` | NPC / CT: the N in N+ (sheet field labeled **Throw**) |

Editing an NPC’s Throw field sets `attackthrow_manual`. Changing **Hit Dice** clears manual and recomputes from the Monster HD table.

---

## What Changes in FGU

- **`ActionAttack.getTHACO` / `getBaseAttack`** — derived from Attack Throw
- **`modAttack`** — stamps `[ATKTHROW(N+)]` on the roll (replaces `[THACO]/` / `[BAB]`)
- **Character sheet combat score** — labeled **Throw**, shows N (e.g. `10`)
- **AC (PC + NPC)** — shown as ACKS ascending (0 = unarmored); 2E descending kept in DB for items/modules
- **NPC sheet** — THACO field relabeled **Throw**, bound to `attackthrow`, derived from **Hit Dice** (ACKS Monster HD column); Combat Tracker entries sync the same way
- **Actions → Combat matrix** — full replacement of the stock THACO matrix:
  - **Base** line shows the character's Attack Throw as `N+`
  - Columns are **ACKS ascending AC** from 0 … 12 (unarmored on the left)
  - Each cell is the target as `N+` (`need = Base + AC`)
  - Hint notes 2E conversion: ACKS AC = `10 - 2E AC` (2E AC 10 = ACKS AC 0)
- **Psionics (MTHACO)** — untouched
- **Class advancement THACO fields** — ignored while this extension is active (overwritten on sync)

### Example matrix (Fighter 1, Base `10+`)

| AC (ACKS) | 0 | 1 | 2 | 3 | ... | 6 | 7 | ... |
|----------:|--:|--:|--:|--:|----|--:|--:|-----|
| Need      |10+|11+|12+|13+| ... |16+|17+| ... |

(unarmored = 0, leather = 2, plate+shield = 7 per ACKS II Compatibility Guide)

---

## Composition

- **`2e-advdis`** — no change required; attacks already roll high
- **`2e-target20` / `2e-skillthrow`** — independent (they don't touch attacks)
- **`modAttack` chaining** — captures the currently registered attack mod handler and delegates, so another attack-mod extension can still compose if it loads first

Exposes `AttackThrowManager.isActive()` for other extensions.

---

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- No stock ruleset file is edited — standard extension load order, `ActionsManager` handler registration, template overrides, and `merge="join"` windowclass patches

---

## Installation

Drop the `2e-attackthrow` folder into your Fantasy Grounds Unity `extensions/` directory (or run `./deploy.sh` from this folder after developing in-repo) and enable it when loading a 2E campaign.

### Dev workflow (same as other fgu_2e extensions)

```bash
./deploy.sh        # extension/ → ~/.smiteworks/fgdata/extensions/2e-attackthrow/
./sync-to-repo.sh  # live → extension/ after a session
./backup.sh        # snapshot live before risky edits
./build-ext.sh     # package dist/2e-attackthrow.ext
```
