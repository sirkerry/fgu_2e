# 2E KPI — Kits, Parcels, and Items

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Replaces the unused Weapon tab on Kit records (Warrior Kits / Backgrounds)
with a **Parcels** tab. Kit designers drag real Treasure Parcel library
records onto the Kit (drag the same Parcel on twice for multiple copies —
no count field, kept deliberately simple). Dropping the Kit onto a
character unpacks each linked Parcel onto the character — granting its
items and coin — using the exact same generic parcel-expansion mechanism
CoreRPG itself uses for NPCs, the party sheet, and other parcels.

## Design history

The original design (see git history) tried to let Kits hold items and
coin directly, mirroring a real inventory. That took nine rounds of live
FGU testing to get partially working (tab merge semantics, `list_column`
vs `list_content_labeled_alternating`, `sub_content` layout, item-count
double-counting, an `idelete` anchor-chain rendering bug) and even then
individual item drag-and-drop stayed unreliably flaky. The user pointed out
(2026-07-07) that Treasure Parcels already solve this exact problem and
drag-and-drop onto them is rock solid — so a Kit just needs to hold *links*
to Parcels, not a flattened copy of their contents. This is simpler, more
reliable, and arguably a better semantic fit (a Parcel already *is* "a
bundle of starting gear"). All the item/coin-list machinery was removed.

## How it works

- `extension/campaign/record_background_parcels.xml` — removes the
  `weaponactions` tab from `reference_background`, adds a `kpiparcels` tab
  (`kpi_background_parcels`) with a plain `list_column` (`.parcellist`,
  link only). The Kit's own `onDrop` routes `treasureparcel` shortcut
  drops to `KPIManager.addParcelLink`, falling back to the ruleset's
  original Ctrl+drag story-text drop handling for anything else.
- `extension/scripts/manager_kpi.lua`:
  - `addParcelLink` — creates a new link-only row when a Parcel is dropped
    on the Kit (does not unpack it yet), and also caches a plain-text
    `coinsummary`/`itemsummary` on that row for the preview button (see
    below) by reading the parcel via `DB.getChildList(node, "coinlist"/"itemlist")`
    — the function `ItemManager.handleParcelTransfer` itself uses.
    `DB.getChildren`/`DB.getChild` do NOT see these same children at all
    (confirmed: they find the list node correctly but report zero
    children, in every context tested) — use `DB.getChildList` for this
    specific data shape, not `DB.getChildren`.
  - wraps `CharManager.addBackgroundRef` so applying a Kit to a character
    also calls `addKitParcels`, which loops the Kit's Parcel links and
    calls `ItemManager.handleParcel(nodeChar, sParcelRecord)` for each —
    the character is already registered as inventory/currency capable by
    CoreRPG itself, so no special registration is needed on our side at
    all (unlike the old itemlist/coinlist design).
- The Kit's `link` control (`linkc_listitem_left`) is `<invisible/>` and
  exists only so its stored value can be read for the real unpack; the
  visible icon is a separate plain `buttoncontrol` (`viewicon`) that opens
  a custom `kpi_parcel_preview` window instead of the real record. Two
  real FGU limitations forced this shape (see [[fgu-lua-xml-constraints]]
  for the general lessons): a `treasureparcel` window opened via a stored
  link from another record (rather than the sidebar) doesn't render its
  contents correctly, and `onClickDown` returning `true` doesn't suppress
  FGU's native "follow this link" click behavior, so the real broken
  window would open alongside anything you build unless the link control
  itself is hidden.

## Workflow

Same pattern as `fgu_aa2e/`: the live extension folder is the truth, this
repo is a git-tracked backup. **No symlinks.**

- Live: `~/.smiteworks/fgdata/extensions/2e-kpi/`
- Before editing further: `./backup.sh` (snapshots live → `backups/TIMESTAMP/`)
- Edit files directly in the live folder (that's what FGU loads)
- After a dev session: `./sync-to-repo.sh` then `git add -A && git commit`
- To push the repo's baseline back out to live: `./deploy.sh`
- Restore: `./restore.sh <timestamp>` or `./restore.sh baseline`

## Status

**Working end-to-end, confirmed live (2026-07-07).** Dropping a Parcel
onto a Kit adds a correctly-named, deletable link row; applying the Kit to
a character unpacks every linked Parcel onto them via the same generic
`ItemManager.handleParcel` call CoreRPG uses everywhere else — verified by
dragging a Kit with two linked Parcels onto a character and confirming
both the chat log (`Parcel [X] -> [Character]`) and the character's actual
Inventory/Treasure reflected the combined contents correctly.

The Parcel-preview button (click the icon on a Kit's Parcel row) also now
shows a correct read-only summary ("5 PP" / "1x Chainmail", etc.) — this
took several rounds to get right (see [[project_2e_kpi]] memory for the
full diagnostic trail) since the real `treasureparcel` window can't be
opened correctly from this context, and even direct database reads of a
parcel's own coin/item lists needed the right API function
(`DB.getChildList`, not `DB.getChildren`).

## Known limitations

FGU's `<tab merge="delete">` removes the *entire* inherited tab list on a
windowclass, not just one named tab — so this extension has to rebuild the
Kit/Background record's full tab set (Notes/Main/Skills/Parcels/Powers)
rather than surgically swapping in just the Parcels tab. If a user also has
another extension enabled that adds/modifies tabs on `reference_background`,
whichever extension has the higher `<loadorder>` wins and the other's tab
changes are silently dropped. This is an inherent FGU engine limitation, not
fixable from either extension's side — worth a line in the Forge listing so
buyers aren't surprised if they combine this with another Kit-tab-modifying
extension. (Checked against `2ePlayerOption.ext`, a common 2E companion
extension — it doesn't touch `reference_background` at all, so no conflict
there.)
