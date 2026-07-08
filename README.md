# fgu_2e

Fantasy Grounds Unity extensions for the official 2E (AD&D 2nd Edition)
ruleset, by Kerry Harrison (sirkerry).

Each extension lives in its own folder under `extensions/`, fully
self-contained with its own workflow scripts (`backup.sh`/`deploy.sh`/
`sync-to-repo.sh`/`restore.sh`/`build-ext.sh`) and README — see
[[feedback_live_first_no_symlinks]]: all FGU dev happens live at
`~/.smiteworks/fgdata/extensions/<name>/`, never via symlink; these repo
folders are git-tracked backups synced with `sync-to-repo.sh`.

## Extensions

- **[2e-kpi](extensions/2e-kpi/README.md)** — Kits, Parcels, and Items.
  Replaces the unused Weapon tab on Kit records with a Parcels tab; drag
  Treasure Parcels onto a Kit to link them, applying the Kit to a
  character unpacks every linked Parcel onto them.
- **[2e-better-subraces](extensions/2e-better-subraces/README.md)** —
  Adds Proficiencies, Non-Weapon Proficiencies (Skills), and Advanced
  Effects sections to Subrace records (previously Traits-only), applied
  to a character automatically when that subrace is chosen. Also adds
  Non-Weapon Proficiencies to the base Race record itself.
