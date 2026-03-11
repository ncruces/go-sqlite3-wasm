#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../build
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

curl -#OL "https://github.com/sqlite/sqlite/raw/version-3.52.0/mptest/mptest.c"
curl -#OL "https://github.com/Photosounder/MinQND-libc/raw/refs/heads/main/minqnd_sprintf.c"

trap 'rm -f sqlite3.tmp mptest.c minqnd_sprintf.c unistd.h' EXIT
touch unistd.h

"$WASI_SDK/clang" --target=wasm32 -nostdlib -std=c23 -g0 -Oz \
	-o sqlite3.wasm test.c -I"$ROOT/libc" -I"$ROOT" -I. \
	-mexec-model=reactor \
	-mmutable-globals -mmultivalue \
	-mbulk-memory -mreference-types \
	-msign-ext -mnontrapping-fptoint \
	-mno-simd128 -mno-extended-const \
	-fno-stack-protector \
	-Wl,--stack-first \
	-Wl,--import-memory \
	-Wl,--import-undefined \
	-Wl,--initial-memory=327680 \
	-D_HAVE_SQLITE_CONFIG_H -DSQLITE_USE_URI \
	-DSQLITE_EXPERIMENTAL_PRAGMA_20251114 \
	-DSQLITE_CUSTOM_INCLUDE=sqlite_opt.h \
	-Wl,--export=errno \
	-Wl,--export=__main_argc_argv \
	$(awk '{print "-Wl,--export="$0}' "$ROOT/exports.txt")

mv sqlite3.wasm sqlite3.tmp

"$BINARYEN/wasm-opt" -g sqlite3.tmp -o sqlite3.wasm \
	--gufa --generate-global-effects --low-memory-unused --converge -Oz \
	--enable-mutable-globals --enable-multivalue \
	--enable-bulk-memory --enable-reference-types \
	--enable-sign-ext --enable-nontrapping-float-to-int \
	--disable-simd --disable-extended-const \
	--strip --strip-producers
