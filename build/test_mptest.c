#include "sqlite_cfg.h"
#include "sqlite_opt.h"
//
#include "sqlite3.h"

#pragma clang diagnostic ignored "-Weverything"

#define main(...) main_mptest(__VA_ARGS__)
#define sqlite3_enable_load_extension(...)
#define sqlite3_trace(...)
#define unlink(...) (0)
#define getpid() (0)

#include "test/mptest.c"
