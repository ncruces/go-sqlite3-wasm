#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -rf sqlite-src-*' EXIT

curl -#OL "https://sqlite.org/2026/sqlite-src-3530300.zip"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-src-*.zip); then
  if ! [[ $hash =~ 2daecfa16e3b19e058dc2e2cb717b80ade361e0315aa5376c3619f66aa81e181 ]]; then
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
