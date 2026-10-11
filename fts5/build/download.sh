#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -rf sqlite-src-*' EXIT

curl -#fOL "https://sqlite.org/2026/sqlite-src-3540000.zip"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-src-*.zip); then
  if ! [[ $hash =~ a5c29342ca185abcda332448fbb27c536661245be27e20199b46c49099b0e15e ]]; then
    echo $hash
    exit 1
  fi
fi 2> /dev/null

unzip sqlite-src-*.zip

# Create FST5 amalgamation.
pushd sqlite-src-*/
./configure
make fts5.c
popd

mv sqlite-src-*/fts5.? .
