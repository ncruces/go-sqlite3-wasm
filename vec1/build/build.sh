#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../build
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

curl -# "https://sqlite.org/vec1/raw/8ffe11d887?at=vec1.c" > vec1.c

trap 'rm -f vec1.*' EXIT

"$WASI_SDK/clang" --target=wasm32 -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o vec1 vec1.c -I"$ROOT" -I"$ROOT/libc" \
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

mv vec1 vec1.tmp

"$BINARYEN/wasm-opt" -g vec1.tmp -o vec1.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --zero-filled-memory \
	--converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const \
	--strip --strip-producers

go tool wasm2go -unsafe -o ../vec1.go vec1.wasm
