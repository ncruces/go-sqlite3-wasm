// Amalgamation
#include "sqlite3.c"
// Extensions
#include "ext/decimal.c"
#include "ext/ieee754.c"
#include "ext/regexp.c"
#include "ext/series.c"
#include "ext/uint.c"
// Bindings
#include "func.c"
#include "hooks.c"
#include "pointer.c"
#include "stmt.c"
#include "text.c"
#include "time.c"
#include "vfs.c"
#include "vtab.c"
// Libc
#include "libc.c"
#include "malloc_tlsf.c"

static int malloc_good_size_(int size) { return malloc_good_size(size); }

void _initialize() {
  init_allocator();

  static sqlite3_mem_methods mem_methods;
  sqlite3_config(SQLITE_CONFIG_GETMALLOC, &mem_methods);

  mem_methods.xRoundup = malloc_good_size_;
  sqlite3_config(SQLITE_CONFIG_MALLOC, &mem_methods);

  sqlite3_initialize();
  sqlite3_auto_extension((void (*)(void))sqlite3_decimal_init);
  sqlite3_auto_extension((void (*)(void))sqlite3_ieee_init);
  sqlite3_auto_extension((void (*)(void))sqlite3_regexp_init);
  sqlite3_auto_extension((void (*)(void))sqlite3_series_init);
  sqlite3_auto_extension((void (*)(void))sqlite3_uint_init);
  sqlite3_auto_extension((void (*)(void))sqlite3_time_init);
}
