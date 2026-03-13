#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

BINARYEN="tools/binaryen/bin/"
WASI_SDK="tools/wasi-sdk/bin/"

trap 'rm -f sqlite3.tmp sqlite3.wasm' EXIT

"$WASI_SDK/clang" --target=wasm32 -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o sqlite3.wasm main.c test_*.c -Ilibc -I. \
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
	-D_HAVE_SQLITE_CONFIG_H \
	-DSQLITE_CUSTOM_INCLUDE=sqlite_opt.h \
	$(awk '{print "-Wl,--export="$0}' exports.txt)

mv sqlite3.wasm sqlite3.tmp

"$BINARYEN/wasm-opt" -g sqlite3.tmp -o sqlite3.wasm \
	--gufa --generate-global-effects --low-memory-unused --converge -Oz \
	--enable-mutable-globals --enable-multivalue \
	--enable-bulk-memory --enable-reference-types \
	--enable-sign-ext --enable-nontrapping-float-to-int \
	--disable-simd --disable-extended-const \
	--strip --strip-producers

go tool wasm2go -endian big < sqlite3.wasm > ../sqlite3.go
go tool wasm2go -endian little < sqlite3.wasm > ../sqlite3_little.go
