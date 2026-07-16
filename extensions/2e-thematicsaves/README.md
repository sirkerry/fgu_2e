# 2E Thematic Saves

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Relabels the ten expanded saving throws with shorter **thematic** names and adds tooltips. Mechanics and database keys are unchanged.

---

## Name map

| Stock (DB key) | Thematic | Notes |
|----------------|----------|--------|
| Paralyzation | **Hold** | |
| Poison | **Poison** | unchanged |
| Death | **Death** | unchanged |
| Rod | **Fear** | RSW group |
| Staff | **Device** | RSW group |
| Wand | **Ray** | RSW group |
| Petrification | **Stone** | |
| Polymorph | **Curse** | |
| Breath | **Blast** | |
| Spell | **Spell** | unchanged |

Grouped labels (where the 5-save set still appears):

- Hold, Poison or Death  
- Fear, Device or Ray  
- Stone, Curse  
- Blast  
- Spell  

---

## What changes

- Character sheet save column labels + tooltips  
- Class advancement short headers (`Ho`, `Po`, `De`, …)  
- Chat roll labels (`DataCommon.saves_stol`)  
- Composite group strings  

## What does not change

- Save scores, modifiers, or resolution math  
- Database paths (`saves.paralyzation.score`, etc.)  
- Modules / class tables that reference stock save keys  

---

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset  
- Safe with `2e-attackthrow`, `2e-ascendingac`, `2e-target20`, etc. (UI/strings only)  

---

## Installation

Drop `2e-thematicsaves` into FGU `extensions/` or run `./deploy.sh` from this folder.

```bash
./deploy.sh
./sync-to-repo.sh
./build-ext.sh
```
