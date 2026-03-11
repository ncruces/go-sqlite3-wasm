#include "main.c"

#define sqlite3_enable_load_extension(...)
#define sqlite3_trace(...)
#define unlink(...) (0)
#define getpid() (0)

#include "mptest.c"
