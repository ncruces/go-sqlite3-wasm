#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -rf sqlite-src-*' EXIT

curl -#OL "https://sqlite.org/2026/sqlite-src-3530200.zip"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-src-*.zip); then
  if ! [[ $hash =~ 490ec7af32a6bfa5f3e05dc279c04286cfe3f328def4a8b7344e3fa20be18a4c ]]; then
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
