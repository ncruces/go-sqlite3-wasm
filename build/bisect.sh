#!/usr/bin/env bash
# Usage: BINDINGS=/path/to/bindings build/bisect.sh <good-tag> <bad-tag>
# e.g.:  BINDINGS=~/src/go-sqlite3 build/bisect.sh version-3.53.3 version-3.53.4
#
# Optional env:
#   TEST_RUN   go test -run pattern (default: run everything)
#   TEST_PKGS  packages to test in $BINDINGS (default: ./...)
#   TEST_COUNT how many times to run the tests (default: 1; raise if flaky)
#   BISECT_DIR where to keep the SQLite clone (default: $TMPDIR/sqlite-bisect)
set -euo pipefail

ROOT=$(cd -P -- "$(dirname -- "$0")/.." && pwd)
WORK=${BISECT_DIR:-${TMPDIR:-/tmp}/sqlite-bisect}
SRC=$WORK/sqlite
BINDINGS=${BINDINGS:?set BINDINGS to your Go bindings checkout (the module with the go.mod replace)}

if [ "${1:-}" != "--step" ]; then
  GOOD=${1:?usage: $0 <good-tag> <bad-tag>}
  BAD=${2:?usage: $0 <good-tag> <bad-tag>}

  for t in tclsh make go git patch; do
    command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }
  done
  for d in tools/wasi-sdk/bin tools/binaryen/bin; do
    [ -d "$ROOT/$d" ] || { echo "missing $ROOT/$d" >&2; exit 1; }
  done

  mkdir -p "$WORK"
  if [ ! -d "$SRC/.git" ]; then
    git clone --filter=blob:none https://github.com/sqlite/sqlite.git "$SRC"
  else
    git -C "$SRC" fetch --tags origin
  fi

  cd "$SRC"
  git bisect reset >/dev/null 2>&1 || true
  trap 'git -C "$SRC" bisect reset >/dev/null 2>&1 || true' EXIT
  git bisect start "$BAD" "$GOOD"
  git bisect run env BISECT_DIR="$WORK" BINDINGS="$BINDINGS" "$ROOT/build/bisect.sh" --step
  git bisect log
  exit 0
fi

# ---- Per-commit step. Exit: 0 = good, 1 = bad, 125 = skip. ----
OUT=$WORK/out
rm -rf "$OUT" && mkdir -p "$OUT"

# 1. Build the amalgamation out of tree from the checked-out commit.
(
  cd "$OUT"
  "$SRC/configure" >/dev/null
  make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" sqlite3.c sqlite3.h >/dev/null
) || exit 125

# 2. Put files where download.sh puts them (all inside build/).
cd "$ROOT/build"
cp "$OUT/sqlite3.c" "$OUT/sqlite3.h" . || exit 125
cp "$SRC/src/sqlite3ext.h" . || exit 125
mkdir -p ext test
for f in decimal ieee754 regexp series uint; do
  cp "$SRC/ext/misc/$f.c" ext/ || exit 125
done
cp "$SRC/mptest/mptest.c" "$SRC/test/speedtest1.c" test/ || exit 125

# 3. Patches; if they don't apply, we can't judge this commit.
(cat *.patch | patch -p0 --no-backup-if-mismatch >/dev/null) || exit 125

# 4. Build: clang -> wasm-opt -> Go translation (writes ../libc.go, ../sqlite3.go).
./build.sh || exit 125

# 5. Test in the bindings module (its go.mod replaces this repo).
#    Subshell so cwd/env don't leak. A compile failure skips; a test failure is bad.
(
  cd "$BINDINGS"
  go build ./... >/dev/null 2>&1 || exit 125
  go test -count="${TEST_COUNT:-1}" ${TEST_RUN:+-run "$TEST_RUN"} ${TEST_PKGS:-./...}
) && exit 0 || exit 1