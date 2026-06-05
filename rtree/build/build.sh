#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

trap 'rm -f *rtree* geopoly*' EXIT

GITHUB_TAG="https://github.com/sqlite/sqlite/raw/version-3.53.2"

curl -#OL "$GITHUB_TAG/ext/rtree/rtree.h"
curl -#OL "$GITHUB_TAG/ext/rtree/rtree.c"
curl -#OL "$GITHUB_TAG/ext/rtree/geopoly.c"
curl -#OL "$GITHUB_TAG/ext/rtree/sqlite3rtree.h"

go tool libc-gen -c-out "$ROOT/libc"

"$WASI_SDK/clang" --target=wasm32 -ffreestanding -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o rtree main.c -I"$ROOT/libc" -I"$ROOT/build" \
	-DNDEBUG -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_ENABLE_GEOPOLY \
	-mexec-model=reactor -shared -fPIC \
	-mmutable-globals -mmultivalue \
	-mnontrapping-fptoint -msign-ext \
	-mreference-types -mbulk-memory \
	-mextended-const -mtail-call \
	-mwide-arithmetic \
	-Wl,--no-entry \
	-Wl,--stack-first \
	-Wl,--import-undefined \
	-Wl,--export=sqlite3_extension_init

"$BINARYEN/wasm-opt" -g rtree -o rtree.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const --enable-tail-call \
	--enable-wide-arithmetic \
	--strip --strip-producers

go tool libc-gen -wasm rtree.wasm -o ../libc.go
go tool wasm2go -unsafe -provided ../libc.go -o ../rtree.go rtree.wasm
