#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

trap 'rm -f vec1*' EXIT
curl -# "https://sqlite.org/vec1/raw/7b8bc78f89?at=vec1.c" > vec1.c

go tool libc-gen -c-out "$ROOT/libc"

"$WASI_SDK/clang" --target=wasm32 -ffreestanding -nostdlib -std=c23 -g0 -Oz \
	-o vec1 vec1.c -I"$ROOT/libc" -I"$ROOT/build" \
	-DSQLITE_OMIT_LOAD_EXTENSION \
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

"$BINARYEN/wasm-opt" -g vec1 -o vec1.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const --enable-tail-call \
	--enable-wide-arithmetic \
	--strip --strip-producers

go tool libc-gen -wasm vec1.wasm -o ../libc.go
go tool wasm2go -unsafe -provided ../libc.go -o ../vec1.go vec1.wasm
