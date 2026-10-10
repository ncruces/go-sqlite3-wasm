#define SIMDE_FLOAT16_API SIMDE_FLOAT16_API_FP16_NO_ABI
#define SIMDE_ENABLE_NATIVE_ALIASES

#include "arm/neon.h"

#define VEC1_HAVE_NEON 1
#define VEC1_SIMD_WIDTH 4

#include "vec1.c"
