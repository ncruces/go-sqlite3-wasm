#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

trap 'rm -f vec1*' EXIT
curl -# "https://sqlite.org/vec1/raw/3e0b52fe43?at=vec1.c" > vec1.c

go tool libc-gen -pkg vec1 -deref-mem -o ../libc.go -c-out "$ROOT/libc" \
	memcmp strtod

"$WASI_SDK/clang" --target=wasm32 -nostdlib -std=c23 -g0 -Oz \
	-o vec1 vec1.c -I"$ROOT/libc" -I"$ROOT/build" \
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

"$BINARYEN/wasm-opt" -g vec1 -o vec1.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const \
	--strip --strip-producers

go tool wasm2go -unsafe -provided ../libc.go -o ../vec1.go vec1.wasm
