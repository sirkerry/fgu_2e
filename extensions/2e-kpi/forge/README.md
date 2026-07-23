# 2E KPI — Kits, Parcels, and Items

FGU extension for the official 2E (AD&D 2nd Edition) ruleset.

Replaces the unused Weapon tab on Kit records (Warrior Kits / Backgrounds) with a **Parcels** tab. Kit designers link Treasure Parcel library records to a Kit; dropping the Kit onto a character unpacks every linked Parcel onto them, granting its items and coin.

## How to Use

1. Open a Kit (Background) record with the extension loaded — it now has a **Parcels** tab in place of the old Weapon tab.
2. Drag a Treasure Parcel library record onto the Parcels tab to link it. Drag the same Parcel again to link a second copy (there's no count field — each drag adds one linked copy).
3. Click a linked Parcel's icon to preview a read-only summary of its coin and items.
4. Apply the Kit to a character as normal — every linked Parcel is unpacked onto the character automatically, granting its items and coin.

## Compatibility

- Official 2E (AD&D 2nd Edition) ruleset
- If another extension also modifies tabs on the Background/Kit record, whichever extension has the higher load order wins — this is an FGU engine limitation affecting any extension that changes a record's tab list, not specific to this one
