#include <ctype.h>
#include <math.h>

#include "sqlite3ext.h"

// Need this for functions for which the address is taken.
static void local_sqlite3_free(void* p) { sqlite3_free(p); }

#define sqlite3_rtree_init sqlite3_extension_init
#define sqlite3_free local_sqlite3_free

#include "libc.c"
#include "rtree.c"

sqlite3_int64 sqlite3GetToken(const unsigned char* p, int*) {
  if (p[0] == 0) return 0;

  // Quoted token: "...", `...`, '...'
  if (p[0] == '"' || p[0] == '`' || p[0] == '\'') {
    int delim = p[0];
    int i = 1;
    while (p[i]) {
      if (p[i++] != delim) continue;
      if (p[i] != delim) return i;  // Closing quote.
      i++;
    }
    return i;  // Unterminated quote.
  }

  // Quoted token: [...]
  if (p[0] == '[') {
    int i = 1;
    while (p[i] && p[i] != ']') i++;
    return p[i] != ']' ? i : i + 1;
  }

  // Quoted token: x'...' or X'...'
  if ((p[0] == 'x' || p[0] == 'X') && p[1] == '\'') {
    int i = 2;
    while (p[i] && p[i] != '\'') i++;
    return p[i] != '\'' ? i : i + 1;
  }

  // Unquoted token.
  int i = 0;
  while (isalnum(p[i]) || p[i] == '_' || p[i] == '$' || p[i] > 0x7f) i++;
  return i;
}

int sqlite3IntFloatCompare(i64 i, double r) {
  // All integers are larger than NaN.
  if (isnan(r)) return 1;
  // Out of range.
  if (r < -0x1p63) return +1;
  if (r >= 0x1p63) return -1;
  // Compare as ints.
  sqlite3_int64 y = (sqlite3_int64)r;
  if (i > y) return +1;
  if (i < y) return -1;
  // Compare as floats.
  double x = (double)i;
  if (x > r) return +1;
  if (x < r) return -1;
  // Equal.
  return 0;
}
