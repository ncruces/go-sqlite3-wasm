#!/usr/bin/env bash
set -euo pipefail

cd -P -- "$(dirname -- "$0")"

VERSION="22.1.1"

case "$OSTYPE" in
"darwin"*)
    case "$(uname -m)" in
    "aarch64")
        TARBALL="LLVM-${VERSION}-macOS-ARM64.tar.xz"
        ;;
    esac
    ;;
"linux"*)
    case "$(uname -m)" in
    "x86_64")
        TARBALL="LLVM-${VERSION}-Linux-X64.tar.xz"
        ;;
    "aarch64")
        TARBALL="LLVM-${VERSION}-Linux-ARM64.tar.xz"
        ;;
    esac
    ;;
"msys"|"cygwin")
    case "$(uname -m)" in
    "x86_64")
        TARBALL="clang+llvm-${VERSION}-x86_64-pc-windows-msvc.tar.xz"
        ;;
    esac
    ;;
esac

if [ -z "$TARBALL" ]; then
    echo "Unsupported build platform: ${OSTYPE} $(uname -m)"
    exit 1
fi

# Download tools
mkdir -p "tools/"
rm -rf "tools/LLVM*"
curl -#L "https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/${TARBALL}" | tar -xJC "tools/"
mv "tools/LLVM"* "tools/LLVM"
