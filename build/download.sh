#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

curl -#OL "https://sqlite.org/2026/sqlite-autoconf-3520000.tar.gz"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-autoconf-*.tar.gz); then
  if ! [[ $hash =~ 45a4911475950ab5fd486afb776102eb29d69e7569b48947f21e3c8501b51822 ]]; then
    echo $hash
    exit 1
  fi
fi 2> /dev/null

tar xzf sqlite-autoconf-*.tar.gz

mv sqlite-*/sqlite3.c .
mv sqlite-*/sqlite3.h .
mv sqlite-*/sqlite3ext.h .
rm -r sqlite-*

GITHUB_TAG="https://github.com/sqlite/sqlite/raw/version-3.52.0"

mkdir -p ext/
cd ext/
curl -#OL "$GITHUB_TAG/ext/misc/anycollseq.c"
curl -#OL "$GITHUB_TAG/ext/misc/base64.c"
curl -#OL "$GITHUB_TAG/ext/misc/decimal.c"
curl -#OL "$GITHUB_TAG/ext/misc/ieee754.c"
curl -#OL "$GITHUB_TAG/ext/misc/regexp.c"
curl -#OL "$GITHUB_TAG/ext/misc/series.c"
curl -#OL "$GITHUB_TAG/ext/misc/spellfix.c"
curl -#OL "$GITHUB_TAG/ext/misc/uint.c"
cd ~-

mkdir -p test/
cd test/
curl -#OL "$GITHUB_TAG/mptest/mptest.c"
curl -#OL "$GITHUB_TAG/test/speedtest1.c"
cd ~-

cat *.patch | patch -p0 --no-backup-if-mismatch
