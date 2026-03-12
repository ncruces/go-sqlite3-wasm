#include "sqlite_cfg.h"
#include "sqlite_opt.h"
//
#include "sqlite3.h"

#pragma clang diagnostic ignored "-Weverything"

#define main(...) main_speedtest1(__VA_ARGS__)
#define unlink(...) (0)
#define SPEEDTEST_OMIT_HASH

#include "test/speedtest1.c"
