#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

trap 'rm -f sql3parse_table*' EXIT

curl -#OL "https://github.com/ncruces/sqlite-createtable-parser/raw/master/LICENSE"
curl -#OL "https://github.com/ncruces/sqlite-createtable-parser/raw/master/sql3parse_table.c"
curl -#OL "https://github.com/ncruces/sqlite-createtable-parser/raw/master/sql3parse_table.h"

mv LICENSE ../LICENSE

go tool libc-gen -pkg sql3parse_table -o ../libc.go -c-out "$ROOT/libc" strlen

"$WASI_SDK/clang" --target=wasm32 -ffreestanding -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o sql3parse_table main.c -I"$ROOT/libc" \
	-mexec-model=reactor \
	-mmutable-globals -mmultivalue \
	-mnontrapping-fptoint -msign-ext \
	-mreference-types -mbulk-memory \
	-mextended-const \
	-Wl,--no-entry \
	-Wl,--stack-first \
	-Wl,--import-undefined \
	-Wl,--export=malloc \
	-Wl,--export=sql3parse_table

"$BINARYEN/wasm-opt" -g sql3parse_table -o sql3parse_table.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --zero-filled-memory \
	--converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const \
	--strip --strip-producers

go tool wasm2go -provided ../libc.go < sql3parse_table.wasm > ../parser.go
