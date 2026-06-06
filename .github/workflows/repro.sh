#!/usr/bin/env bash
set -euo pipefail

./tools.sh

build/download.sh
fts5/build/download.sh

build/build.sh
fts5/build/build.sh
parser/build/build.sh
rtree/build/build.sh
spellfix/build/build.sh
vec1/build/build.sh

# Check diffs
git diff --exit-code
