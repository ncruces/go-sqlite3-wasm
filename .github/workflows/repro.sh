#!/usr/bin/env bash
set -euo pipefail

./tools.sh
build/download.sh
build/build.sh
parser/build/build.sh
spellfix/build/build.sh
vec1/build/build.sh

# Check diffs
git diff --exit-code
