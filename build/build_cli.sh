#!/bin/bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

CC="${CC:-cc}"
CFLAGS="${CFLAGS:--O2 -pipe}"

trap 'rm -r sqlite-autoconf-*' EXIT

# Get latest sqlite amalgamation version URL from main download script
download=$(grep -m1 curl download.sh)

# Add readline support if archive exists
if [[ -f "/usr/lib/libreadline.a" ]] && \
   [[ -f "/usr/lib/libncursesw.a" ]]; then
    CFLAGS+=" -DHAVE_READLINE=1 -lreadline -lncursesw"
fi

eval "$download"
tar xzf sqlite-autoconf-*.tar.gz

${CC} -o sqlite3 sqlite-autoconf-*/sqlite3.c sqlite-autoconf-*/shell.c \
   -DSQLITE_CUSTOM_INCLUDE=../sqlite_opt.h \
   -I. -I/usr/include ${CFLAGS} \
   -lc -lm -lz -static
