#!/usr/bin/env bash
# Zips the mod folder for ModHub / GitHub Releases (files at the zip root, as FS expects).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p dist
python - <<'PY'
import zipfile, pathlib
src = pathlib.Path("FS25_GroundedTractors")
with zipfile.ZipFile("dist/FS25_GroundedTractors.zip", "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(src.rglob("*")):
        if f.is_file():
            z.write(f, f.relative_to(src))
print("dist/FS25_GroundedTractors.zip")
PY
