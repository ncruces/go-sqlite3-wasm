#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -r sqlite-autoconf-*' EXIT

curl -#fOL "https://sqlite.org/2026/sqlite-autoconf-3540000.tar.gz"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-autoconf-*.tar.gz); then
  if ! [[ $hash =~ f5e3e724e9c9b3b5d512c76b02082091a59eeea9becd169a9fbf4d376403acce ]]; then
    echo $hash
    exit 1
  fi
fi 2> /dev/null

tar xzf sqlite-autoconf-*.tar.gz

mv sqlite-autoconf-*/sqlite3.c .
mv sqlite-autoconf-*/sqlite3.h .
mv sqlite-autoconf-*/sqlite3ext.h .

GITHUB_TAG="https://github.com/sqlite/sqlite/raw/version-3.54.0"

mkdir -p ext/
cd ext/
curl -#fOL "$GITHUB_TAG/ext/misc/decimal.c"
curl -#fOL "$GITHUB_TAG/ext/misc/ieee754.c"
curl -#fOL "$GITHUB_TAG/ext/misc/regexp.c"
curl -#fOL "$GITHUB_TAG/ext/misc/series.c"
curl -#fOL "$GITHUB_TAG/ext/misc/uint.c"
cd ~-

mkdir -p test/
cd test/
curl -#fOL "$GITHUB_TAG/mptest/mptest.c"
curl -#fOL "$GITHUB_TAG/test/speedtest1.c"
cd ~-

cat *.patch | patch -p0 --no-backup-if-mismatch
