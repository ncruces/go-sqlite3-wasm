#include "sqlite3ext.h"

// Need this for functions for which the address is taken.
static void local_sqlite3_free(void* p) { sqlite3_free(p); }

#define sqlite3_rtree_init sqlite3_extension_init
#define sqlite3_free local_sqlite3_free

#include "rtree.c"
#include "libc.c"
