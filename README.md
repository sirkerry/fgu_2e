# fgu_2e

Fantasy Grounds Unity extensions for the official 2E (AD&D 2nd Edition)
ruleset, by Kerry Harrison (sirkerry).

Each extension lives in its own folder under `extensions/`, fully
self-contained with its own workflow scripts (`backup.sh`/`deploy.sh`/
`sync-to-repo.sh`/`restore.sh`/`build-ext.sh`) and README — see
[[feedback_live_first_no_symlinks]]: all FGU dev happens live at
`~/.smiteworks/fgdata/extensions/<name>/`, never via symlink; these repo
folders are git-tracked backups synced with `sync-to-repo.sh`.

**Forge listing assets** (`forge/*.svg`, `forge/*.png`) live only in the
repo under each extension’s `forge/` folder. They must **not** be
deployed into the live FGU extensions directory or packaged into
`.ext` files — FG Forge rejects uploads that contain `.svg` inside the
extension package. `deploy.sh` only syncs `extension/`; `build-ext.sh`
also excludes `forge/` and `*.svg` as a safety net.

## Extensions

- **[2e-kpi](extensions/2e-kpi/README.md)** — Kits, Parcels, and Items.
  Replaces the unused Weapon tab on Kit records with a Parcels tab; drag
  Treasure Parcels onto a Kit to link them, applying the Kit to a
  character unpacks every linked Parcel onto them.
- **[2e-brs](extensions/2e-brs/README.md)** — Better Races & Subraces.
  Adds Proficiencies, Non-Weapon Proficiencies (Skills), and Advanced
  Effects sections to Subrace records (previously Traits-only), applied
  to a character automatically when that subrace is chosen. Also adds
  Non-Weapon Proficiencies to the base Race record itself.
- **[2e-advdis](extensions/2e-advdis/README.md)** — Advantage &
  Disadvantage. Roll 2d20 and keep the favorable one, applied to
  attacks, saves, ability checks, and skill checks — correctly inverted
  for 2E's roll-under ability/skill checks.
- **[2e-target20](extensions/2e-target20/README.md)** — Target 20.
  Converts roll-under ability/skill checks to a unified `d20 + bonus >= 20`
  system, using the Player's Option Table 44 ability modifier, character
  level, and (for skill checks) the skill's own existing modifiers.
  Composes with `2e-advdis` via a shared `Target20Manager` contract.
- **[2e-expdmg](extensions/2e-expdmg/README.md)** — Exploding Damage.
  Classic exploding-dice house rule for all damage rolls (weapons
  and spells): a die that rolls its maximum value rerolls and adds,
  chaining on further explosions, using FGU's native compound-explode die
  mode.
- **[2e-fracstats](extensions/2e-fracstats/README.md)** — Fractional
  Ability Scores. Extends stock 2E's 18/01-18/00 exceptional strength
  idea to every ability at every score 1-25: each whole score gets an
  `XX/01-50` and `XX/51-00` bracket driven by the existing percentile
  roll, HackMaster-style. Tables are derived from stock 2E's own
  ability-score tables, not ported from HackMaster.
- **[2e-skillthrow](extensions/2e-skillthrow/README.md)** — Skill Throw.
  Adds a "+" (Throw) option to the skill/proficiency Type cycler,
  alongside ability-linked skills and the existing "%" (percentile)
  option. Modeled on ACKS II's Proficiency Throw: roll `1d20 + modifiers`,
  success on `total >=` a flat Base Check target entered on the skill.
  Composes with `2e-target20` and `2e-advdis`.
- **[2e-attackthrow](extensions/2e-attackthrow/README.md)** — Attack
  Throw. Replaces THACO / to-hit matrices with ACKS II Attack Throw
  derived from class level (Fighter / Crusader-Thief / Mage tracks) or
  NPC Hit Dice. Roll `1d20 + mods >= throw + AC` (ACKS AC 0 = unarmored).
  Composes with `2e-advdis`. Mutually exclusive with `2e-ascendingac`.
- **[2e-ascendingac](extensions/2e-ascendingac/README.md)** — Ascending
  AC. Standard ascending Armor Class (10 = unarmored) and BAB display /
  resolution (`d20 + BAB >= AC`). Class THACO tables unchanged. Mutually
  exclusive with `2e-attackthrow`.
- **[2e-thematicsaves](extensions/2e-thematicsaves/README.md)** — Thematic
  Saves. Relabels the ten 2E saves (Hold, Poison, Death, Fear, Device,
  Ray, Stone, Curse, Blast, Spell) with tooltips; mechanics unchanged.

