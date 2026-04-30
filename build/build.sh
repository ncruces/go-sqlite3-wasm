#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

ROOT=../
BINARYEN="$ROOT/tools/binaryen/bin/"
WASI_SDK="$ROOT/tools/wasi-sdk/bin/"

trap 'rm -f sqlite3 sqlite3.wasm' EXIT

go tool libc-gen -pkg sqlite3_wasm -deref-mem \
	-o ../libc.go -c-out ../libc \
	$(awk '{print $0}' libc.txt)

"$WASI_SDK/clang" --target=wasm32 -ffreestanding -nostdlib -std=c23 -g0 -Oz \
	-Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
	-o sqlite3.wasm main.c test_*.c -I. -I../libc \
	-mexec-model=reactor \
	-mmutable-globals -mmultivalue \
	-mnontrapping-fptoint -msign-ext \
	-mreference-types -mbulk-memory \
	-mextended-const \
	-Wl,--stack-first \
	-Wl,--export-table \
	-Wl,--import-memory \
	-Wl,--import-undefined \
	-D_HAVE_SQLITE_CONFIG_H \
	-DSQLITE_CUSTOM_INCLUDE=sqlite_opt.h \
	$(awk '{print "-Wl,--export="$0}' exports.txt)

mv sqlite3.wasm sqlite3

"$BINARYEN/wasm-opt" -g sqlite3 -o sqlite3.wasm \
	--gufa-optimizing --generate-global-effects \
	--low-memory-unused --zero-filled-memory \
	--converge -O4 \
	--enable-mutable-globals --enable-multivalue \
	--enable-nontrapping-float-to-int --enable-sign-ext \
	--enable-reference-types --enable-bulk-memory \
	--enable-extended-const \
	--strip --strip-producers

go tool wasm2go -embed -unsafe -provided ../libc.go -o ../sqlite3.go sqlite3.wasm
