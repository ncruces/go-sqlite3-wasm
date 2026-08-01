#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -rf sqlite-src-*' EXIT

curl -#OL "https://sqlite.org/2026/sqlite-src-3530400.zip"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-src-*.zip); then
  if ! [[ $hash =~ b834d474b9b393d85a9e3ee4cc11f1329e007e9376a424ee740796f5c4bda3a8 ]]; then
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
