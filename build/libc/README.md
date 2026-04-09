# SQLite Libc

This is a minimal libc that offers just enough
to compile SQLite for wasm32 with nostdlib.

The allocator is either Doug Lea's malloc,
or a simple bump allocator.

There's an original `qsort` implementation,
SQLite provides `vfprintf`,
and Wasm SIMD is used to implement bits of `string.h`.

Everything else (I/O, math) is provided by the host side.
