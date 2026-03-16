#!/bin/bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"
BUILD=$(pwd -P)
CLANG="${BUILD}/tools/LLVM/bin/"

export CC="${CLANG}/clang"
export LD="${CLANG}/ld.lld"
export CFLAGS="${CFLAGS:--O2 -pipe}"

# Get latest sqlite amalgamation version URL from main download script
url=$(grep -o '"https://sqlite\.org/.*\.tar\.gz' download.sh | cut -d'"' -f2)
curl -o /tmp/sqlite.tgz "$url"

# Parse sqlite_opt.h for configured
# sqlite opts and convert to CLI args
SQLITE_CONF=$(while read -r line; do
    case "$line" in
    "") ;;
    "//"*) ;;
    *)
        line="${line#\#define }"
        line="${line/ /=}"
        echo -n "-D${line} "
        ;;
    esac
done < sqlite_opt.h)

# Add readline support if archive exists
if [[ -f "/usr/lib/libreadline.a" ]] && \
   [[ -f "/usr/lib/libncursesw.a" ]]; then
    CFLAGS+=" -DHAVE_READLINE=1 -lreadline -lncursesw"
fi

# On exit, remove sqlite build assets
trap 'rm -rf /tmp/sqlite{-*,.tgz}' exit

(
    cd /tmp
    tar -xf /tmp/sqlite.tgz
    cd sqlite-*
    LD=${LD} ${CC} -o sqlite3 sqlite3.c shell.c -I. ${SQLITE_CONF} -I/usr/include -lc -lm ${CFLAGS} -static
    mv -v sqlite3 "$BUILD"
)
