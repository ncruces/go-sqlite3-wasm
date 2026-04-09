#!/usr/bin/env bash
set -euo pipefail

# Download and build SQLite
build/libc/download.sh
build/download.sh
build/tools.sh
build/build.sh

# Download and build SQLite CREATE and ALTER TABLE parser
parser/build/build.sh

# Check diffs
git diff --exit-code
