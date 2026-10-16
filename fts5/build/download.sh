#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -rf sqlite-src-*' EXIT

curl -#fOL "https://sqlite.org/2026/sqlite-src-3540100.zip"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-src-*.zip); then
  if ! [[ $hash =~ 877c6f4996ce7adb368686bce21638de9e3d91534832ad3d9d119037d1bc22ad ]]; then
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
