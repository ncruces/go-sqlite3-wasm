#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

WASI_SDK="../tools/wasi-sdk/bin"

shopt -s extglob
"$WASI_SDK/clang-format" --style=Google -i !(malloc).@(c|h)
