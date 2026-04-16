#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../build
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

GITHUB_TAG="https://github.com/sqlite/sqlite/raw/version-3.53.0"

curl -#OL "$GITHUB_TAG/ext/misc/spellfix.c"

trap 'rm -f spellfix.*' EXIT

"$WASI_SDK/clang" --target=wasm32 -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o spellfix main.c -I"$ROOT" -I"$ROOT/libc" \
	-DNDEBUG -DSQLITE_OMIT_LOAD_EXTENSION \
	-mexec-model=reactor -shared -fPIC \
	-mmutable-globals -mmultivalue \
	-mnontrapping-fptoint -msign-ext \
	-mreference-types -mbulk-memory \
	-mextended-const \
	-Wl,--no-entry \
	-Wl,--stack-first \
	-Wl,--import-undefined \
	-Wl,--export=sqlite3_extension_init

mv spellfix spellfix.tmp

"$BINARYEN/wasm-opt" -g spellfix.tmp -o spellfix.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --zero-filled-memory \
	--converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const \
	--strip --strip-producers

go tool wasm2go -unsafe -o ../spellfix.go spellfix.wasm
