#include "sqlite3ext.h"

// Need this for functions for which the address is taken.
static void local_sqlite3_free(void* p) { sqlite3_free(p); }

#define sqlite3_free local_sqlite3_free

#include "fts5.c"
#include "libc.c"

fts5_api* pFts5Api;

// Callbacks.

typedef void* go_handle;
void go_destroy(go_handle);

int go_fts5_create(go_handle app, const char** azArg, int nArg,
                   go_handle* pOut);

int go_fts5_tokenize(go_handle app, void* pCtx, int flags, const char* pText,
                     int nText, const char* pLocale, int nLocale,
                     int (*xToken)(void*, int, const char*, int, int, int));

void go_fts5_function(go_handle app, Fts5Context* pFts, sqlite3_context* pCtx,
                      int nArg, sqlite3_value** apVal);

// Callback wrappers.

static void go_destroy_wrapper(void* app) { go_destroy(app); }

static int go_fts5_create_wrapper(void* app, const char** azArg, int nArg,
                                  Fts5Tokenizer** ppOut) {
  return go_fts5_create(app, azArg, nArg, (go_handle*)ppOut);
}

static int go_fts5_tokenize_wrapper(Fts5Tokenizer* pTokenizer, void* pCtx,
                                    int flags, const char* pText, int nText,
                                    const char* pLocale, int nLocale,
                                    int (*xToken)(void*, int, const char*, int,
                                                  int, int)) {
  return go_fts5_tokenize(pTokenizer, pCtx, flags, pText, nText, pLocale,
                          nLocale, xToken);
}

static void go_fts5_delete_wrapper(Fts5Tokenizer* pTokenizer) {
  go_destroy(pTokenizer);
}

static void go_fts5_function_wrapper(const Fts5ExtensionApi* pApi,
                                     Fts5Context* pFts, sqlite3_context* pCtx,
                                     int nArg, sqlite3_value** apVal) {
  go_fts5_function(pApi->xUserData(pFts), pFts, pCtx, nArg, apVal);
}

// Public API.

int sqlite3_extension_init(sqlite3* db, char**, const sqlite3_api_routines*) {
  int rc = fts5Init(db);
  if (rc) return rc;

  sqlite3_stmt* pStmt = NULL;
  rc = sqlite3_prepare_v2(db, "SELECT fts5(?1)", -1, &pStmt, 0);
  if (rc) return rc;

  if (!sqlite3_bind_pointer(pStmt, 1, &pFts5Api, "fts5_api_ptr", NULL)) {
    sqlite3_step(pStmt);
  }
  return sqlite3_finalize(pStmt);
}

int fts5_xCreateTokenizer_v2(const char* name, go_handle app) {
  static fts5_tokenizer_v2 tokenizer = {
      .iVersion = 2,
      .xCreate = go_fts5_create_wrapper,
      .xDelete = go_fts5_delete_wrapper,
      .xTokenize = go_fts5_tokenize_wrapper,
  };
  int rc = pFts5Api->xCreateTokenizer_v2(pFts5Api, name, app, &tokenizer,
                                         go_destroy_wrapper);
  if (rc) go_destroy(app);
  return rc;
}

int fts5_xCreateFunction(const char* name, go_handle app) {
  int rc = pFts5Api->xCreateFunction(
      pFts5Api, name, app, go_fts5_function_wrapper, go_destroy_wrapper);
  if (rc) go_destroy(app);
  return rc;
}

int fts5_xToken(int (*xToken)(void*, int, const char*, int, int, int),
                void* pCtx, int tflags, const char* pToken, int nToken,
                int iStart, int iEnd) {
  return xToken(pCtx, tflags, pToken, nToken, iStart, iEnd);
}

int fts5_xColumnCount(Fts5Context* pCtx) { return sFts5Api.xColumnCount(pCtx); }

int fts5_xRowCount(Fts5Context* pCtx, int64_t* pnRow) {
  return sFts5Api.xRowCount(pCtx, pnRow);
}

int fts5_xColumnTotalSize(Fts5Context* pCtx, int iCol, int64_t* pnToken) {
  return sFts5Api.xColumnTotalSize(pCtx, iCol, pnToken);
}

int fts5_xPhraseCount(Fts5Context* pCtx) { return sFts5Api.xPhraseCount(pCtx); }

int fts5_xPhraseSize(Fts5Context* pCtx, int iPhrase) {
  return sFts5Api.xPhraseSize(pCtx, iPhrase);
}

int fts5_xInstCount(Fts5Context* pCtx, int* pnInst) {
  return sFts5Api.xInstCount(pCtx, pnInst);
}

int fts5_xInst(Fts5Context* pCtx, int iIdx, int* piPhrase, int* piCol,
               int* piOff) {
  return sFts5Api.xInst(pCtx, iIdx, piPhrase, piCol, piOff);
}

sqlite3_int64 fts5_xRowid(Fts5Context* pCtx) { return sFts5Api.xRowid(pCtx); }

int fts5_xColumnText(Fts5Context* pCtx, int iCol, const char** pz, int* pn) {
  return sFts5Api.xColumnText(pCtx, iCol, pz, pn);
}

int fts5_xColumnSize(Fts5Context* pCtx, int iCol, int* pnToken) {
  return sFts5Api.xColumnSize(pCtx, iCol, pnToken);
}

int fts5_xQueryToken(Fts5Context* pCtx, int iPhrase, int iToken,
                     const char** ppToken, int* pnToken) {
  return sFts5Api.xQueryToken(pCtx, iPhrase, iToken, ppToken, pnToken);
}

int fts5_xInstToken(Fts5Context* pCtx, int iIdx, int iToken,
                    const char** ppToken, int* pnToken) {
  return sFts5Api.xInstToken(pCtx, iIdx, iToken, ppToken, pnToken);
}

int fts5_xColumnLocale(Fts5Context* pCtx, int iCol, const char** pz, int* pn) {
  return sFts5Api.xColumnLocale(pCtx, iCol, pz, pn);
}