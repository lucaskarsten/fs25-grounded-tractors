#!/bin/sh
# Local syntax check of every Lua file, same as CI. Uses a local luajit if there is one,
# otherwise any Docker image that ships luajit.
set -e
for f in FS25_GroundedTractors/*.lua; do
  if command -v luajit >/dev/null; then
    luajit -bl "$f" >/dev/null
  else
    MSYS_NO_PATHCONV=1 docker run --rm -v "$(pwd -W 2>/dev/null || pwd):/w" ghcr.io/pathofbuildingcommunity/pathofbuilding-tests:latest luajit -bl "/w/$f" >/dev/null
  fi
  echo "ok $f"
done
