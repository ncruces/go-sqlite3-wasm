#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../../build
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

curl -#OL "https://github.com/ncruces/sqlite-createtable-parser/raw/master/LICENSE"
curl -#OL "https://github.com/ncruces/sqlite-createtable-parser/raw/master/sql3parse_table.c"
curl -#OL "https://github.com/ncruces/sqlite-createtable-parser/raw/master/sql3parse_table.h"

mv LICENSE ../LICENSE

trap 'rm -f sql3parse_table.*' EXIT

"$WASI_SDK/clang" --target=wasm32 -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o sql3parse_table main.c -I"$ROOT/libc" \
	-mexec-model=reactor \
	-mmutable-globals -mmultivalue \
	-mbulk-memory -mreference-types \
	-msign-ext -mnontrapping-fptoint \
	-fno-stack-protector \
	-Wl,--no-entry \
	-Wl,--stack-first \
	-Wl,--import-undefined \
	-Wl,--export=malloc \
	-Wl,--export=sql3parse_table

mv sql3parse_table sql3parse_table.tmp

"$BINARYEN/wasm-opt" -g sql3parse_table.tmp -o sql3parse_table.wasm \
	--gufa --generate-global-effects --low-memory-unused --converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-bulk-memory --enable-reference-types \
	--enable-sign-ext --enable-nontrapping-float-to-int \
	--strip --strip-producers

go tool wasm2go < sql3parse_table.wasm > ../parser.go
