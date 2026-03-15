#!/bin/bash
set -e

# Get latest sqlite amalgamation version URL from main download script
url=$(grep -o '"https://sqlite\.org/.*\.tar\.gz' download.sh | cut -d'"' -f2)
curl -o /tmp/sqlite.tgz "$url"

# Parse sqlite_opt.h for configured
# sqlite opts and convert to CLI args
CFLAGS=$(while read -r line; do
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

# On exit, ensure sqlite build assets are removed
trap 'rm -rf /tmp/sqlite.tgz /tmp/sqlite-*' exit
DESTDIR=$(pwd -P)

(
    cd /tmp
    tar -xf /tmp/sqlite.tgz
    cd sqlite-*

    # Configure with parsed CFLAGS, but explicitly set
    # disable-threadsafe as configure tries to re-set it.
    CFLAGS="$CFLAGS" ./configure --disable-threadsafe \
                                 --disable-shared \
                                 --disable-static \
                                 --static-cli-shell

    # Make static binary and move to
    # origin directory before exit
    make -j$(nproc) LDFLAGS=-static
    mv -v sqlite3 "$DESTDIR"
)
