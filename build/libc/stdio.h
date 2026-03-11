#pragma once

#include <stdarg.h>

typedef void FILE;

#define stdin (FILE*)(0)
#define stdout (FILE*)(1)
#define stderr (FILE*)(2)

int printf(const char* restrict, ...);
int fprintf(FILE* restrict, const char* restrict, ...);
int vfprintf(FILE* restrict, const char* restrict, va_list);

int fclose(FILE*);
FILE* fopen(const char*, const char*);
size_t fwrite(const void* restrict, size_t, size_t, FILE* restrict);
int fflush(FILE*);
