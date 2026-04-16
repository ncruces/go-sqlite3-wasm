#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

curl -#OL "https://sqlite.org/2026/sqlite-autoconf-3530000.tar.gz"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-autoconf-*.tar.gz); then
  if ! [[ $hash =~ 60c4b08c6729761e488d185e0d52411da10b14c72b53ada6936dc5eea225cefe ]]; then
    echo $hash
    exit 1
  fi
fi 2> /dev/null

tar xzf sqlite-autoconf-*.tar.gz

mv sqlite-*/sqlite3.c .
mv sqlite-*/sqlite3.h .
mv sqlite-*/sqlite3ext.h .
rm -r sqlite-*

GITHUB_TAG="https://github.com/sqlite/sqlite/raw/version-3.53.0"

mkdir -p ext/
cd ext/
curl -#OL "$GITHUB_TAG/ext/misc/decimal.c"
curl -#OL "$GITHUB_TAG/ext/misc/ieee754.c"
curl -#OL "$GITHUB_TAG/ext/misc/regexp.c"
curl -#OL "$GITHUB_TAG/ext/misc/series.c"
curl -#OL "$GITHUB_TAG/ext/misc/uint.c"
cd ~-

mkdir -p test/
cd test/
curl -#OL "$GITHUB_TAG/mptest/mptest.c"
curl -#OL "$GITHUB_TAG/test/speedtest1.c"
cd ~-

cat *.patch | patch -p0 --no-backup-if-mismatch
