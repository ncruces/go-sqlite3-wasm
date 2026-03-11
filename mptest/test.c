#include <stdlib.h>
#include <stdio.h>

// SQLite.
#include "main.c"

// Printf.

static inline uint64_t double_as_int(double d) {
  uint64_t u;
  memcpy(&u, &d, sizeof(u));
  return u;
}

#include "minqnd_sprintf.c"

int vfprintf(FILE* restrict stream, const char* restrict format, va_list vlist) {
  va_list vlist_copy;
  va_copy(vlist_copy, vlist);
  int len = vsnprintf(NULL, 0, format, vlist_copy);
  va_end(vlist_copy);

  if (len < 0) return len;

  char buf[len + 1];
  vsnprintf(buf, len + 1, format, vlist);

  size_t written = fwrite(buf, 1, len, stream);
  return (int)written;
}

int fprintf(FILE* restrict stream, const char* restrict format, ...) {
  va_list args;
  va_start(args, format);
  int ret = vfprintf(stream, format, args);
  va_end(args);
  return ret;
}

int printf(const char* restrict format, ...) {
  va_list args;
  va_start(args, format);
  int ret = vfprintf(stdout, format, args);
  va_end(args);
  return ret;
}

// Test.

#define sqlite3_enable_load_extension(...)
#define sqlite3_trace(...)
#define unlink(...) (0)
#define getpid() (0)
#undef UNUSED_PARAMETER

#include "mptest.c"
