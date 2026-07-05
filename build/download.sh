#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

trap 'rm -r sqlite-autoconf-*' EXIT

curl -#OL "https://sqlite.org/2026/sqlite-autoconf-3530300.tar.gz"

# Verify download.
if hash=$(openssl dgst -sha3-256 sqlite-autoconf-*.tar.gz); then
  if ! [[ $hash =~ 98f2b3f3c11be6a03ea32346937b032c2472ebbd7a716bed36ca2f5693e7ce8b ]]; then
    echo $hash
    exit 1
  fi
fi 2> /dev/null

tar xzf sqlite-autoconf-*.tar.gz

mv sqlite-autoconf-*/sqlite3.c .
mv sqlite-autoconf-*/sqlite3.h .
mv sqlite-autoconf-*/sqlite3ext.h .

GITHUB_TAG="https://github.com/sqlite/sqlite/raw/version-3.53.3"

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
