#!/usr/bin/env bash
# Package the live extension into a distributable .ext file (a zip with
# extension.xml at its root, not nested in a folder) for FG Forge / manual
# install. Run ./sync-to-repo.sh first if you want the repo mirror updated
# too - this builds straight from the live folder, the source of truth.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FGDATA="${FGDATA:-$HOME/.smiteworks/fgdata}"
LIVE="$FGDATA/extensions/2e-kpi"
DIST="$REPO/dist"

if [ ! -d "$LIVE" ]; then
	echo "error: live extension not found at $LIVE" >&2
	exit 1
fi

OUT="$DIST/2e-kpi.ext"

mkdir -p "$DIST"
rm -f "$OUT"

( cd "$LIVE" && zip -r -X "$OUT" . -x '.*' )

echo "Built $OUT"
unzip -l "$OUT"
