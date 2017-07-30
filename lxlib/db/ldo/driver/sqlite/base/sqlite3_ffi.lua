--[[
** 2001 September 15
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
--]]


local ffi = require "ffi"
local bit = require "bit"
local lshift = bit.lshift
local bor = bit.bor

local codes = require("lxlib.db.driver.sqlite.base.codes");
--[[
    Created from this version:

    #define SQLITE_VERSION        "3.7.12.1"
    #define SQLITE_VERSION_NUMBER 3007012
    #define SQLITE_SOURCE_ID      "2012-05-22 02:45:53 6d326d44fd1d626aae0e8456e5fa2049f1ce0789"
--]]


ffi.cdef[[

const char sqlite3_version[];
const char *sqlite3_libversion(void);
const char *sqlite3_sourceid(void);
int sqlite3_libversion_number(void);



int sqlite3_threadsafe(void);


typedef struct sqlite3 sqlite3;


typedef int64_t sqlite3_int64;
typedef uint64_t sqlite3_uint64;



 int sqlite3_close(sqlite3 *);



 int sqlite3_exec(
  sqlite3*,                                  /* An open database */
  const char *sql,                           /* SQL to be evaluated */
  int (*callback)(void*,int,char**,char**),  /* Callback function */
  void *,                                    /* 1st argument to callback */
  char **errmsg                              /* Error msg written here */
);


typedef struct sqlite3_file sqlite3_file;
struct sqlite3_file {
  const struct sqlite3_io_methods *pMethods;
};


typedef struct sqlite3_io_methods sqlite3_io_methods;
struct sqlite3_io_methods {
  int iVersion;
  int (*xClose)(sqlite3_file*);
  int (*xRead)(sqlite3_file*, void*, int iAmt, sqlite3_int64 iOfst);
  int (*xWrite)(sqlite3_file*, const void*, int iAmt, sqlite3_int64 iOfst);
  int (*xTruncate)(sqlite3_file*, sqlite3_int64 size);
  int (*xSync)(sqlite3_file*, int flags);
  int (*xFileSize)(sqlite3_file*, sqlite3_int64 *pSize);
  int (*xLock)(sqlite3_file*, int);
  int (*xUnlock)(sqlite3_file*, int);
  int (*xCheckReservedLock)(sqlite3_file*, int *pResOut);
  int (*xFileControl)(sqlite3_file*, int op, void *pArg);
  int (*xSectorSize)(sqlite3_file*);
  int (*xDeviceCharacteristics)(sqlite3_file*);
  int (*xShmMap)(sqlite3_file*, int iPg, int pgsz, int, void volatile**);
  int (*xShmLock)(sqlite3_file*, int offset, int n, int flags);
  void (*xShmBarrier)(sqlite3_file*);
  int (*xShmUnmap)(sqlite3_file*, int deleteFlag);
};








typedef struct sqlite3_mutex sqlite3_mutex;


typedef struct sqlite3_vfs sqlite3_vfs;
typedef void (*sqlite3_syscall_ptr)(void);
struct sqlite3_vfs {
  int iVersion;
  int szOsFile;
  int mxPathname;
  sqlite3_vfs *pNext;
  const char *zName;
  void *pAppData;
  int (*xOpen)(sqlite3_vfs*, const char *zName, sqlite3_file*,
               int flags, int *pOutFlags);
  int (*xDelete)(sqlite3_vfs*, const char *zName, int syncDir);
  int (*xAccess)(sqlite3_vfs*, const char *zName, int flags, int *pResOut);
  int (*xFullPathname)(sqlite3_vfs*, const char *zName, int nOut, char *zOut);
  void *(*xDlOpen)(sqlite3_vfs*, const char *zFilename);
  void (*xDlError)(sqlite3_vfs*, int nByte, char *zErrMsg);
  void (*(*xDlSym)(sqlite3_vfs*,void*, const char *zSymbol))(void);
  void (*xDlClose)(sqlite3_vfs*, void*);
  int (*xRandomness)(sqlite3_vfs*, int nByte, char *zOut);
  int (*xSleep)(sqlite3_vfs*, int microseconds);
  int (*xCurrentTime)(sqlite3_vfs*, double*);
  int (*xGetLastError)(sqlite3_vfs*, int, char *);

  int (*xCurrentTimeInt64)(sqlite3_vfs*, sqlite3_int64*);

  int (*xSetSystemCall)(sqlite3_vfs*, const char *zName, sqlite3_syscall_ptr);
  sqlite3_syscall_ptr (*xGetSystemCall)(sqlite3_vfs*, const char *zName);
  const char *(*xNextSystemCall)(sqlite3_vfs*, const char *zName);

};






 int sqlite3_initialize(void);
 int sqlite3_shutdown(void);
 int sqlite3_os_init(void);
 int sqlite3_os_end(void);


 int sqlite3_config(int, ...);


 int sqlite3_db_config(sqlite3*, int op, ...);


typedef struct sqlite3_mem_methods sqlite3_mem_methods;
struct sqlite3_mem_methods {
  void *(*xMalloc)(int);         /* Memory allocation function */
  void (*xFree)(void*);          /* Free a prior allocation */
  void *(*xRealloc)(void*,int);  /* Resize an allocation */
  int (*xSize)(void*);           /* Return the size of an allocation */
  int (*xRoundup)(int);          /* Round up request size to allocation size */
  int (*xInit)(void*);           /* Initialize the memory allocator */
  void (*xShutdown)(void*);      /* Deinitialize the memory allocator */
  void *pAppData;                /* Argument to xInit() and xShutdown() */
};







 int sqlite3_extended_result_codes(sqlite3*, int onoff);


 sqlite3_int64 sqlite3_last_insert_rowid(sqlite3*);


 int sqlite3_changes(sqlite3*);


 int sqlite3_total_changes(sqlite3*);


 void sqlite3_interrupt(sqlite3*);


 int sqlite3_complete(const char *sql);
 int sqlite3_complete16(const void *sql);


 int sqlite3_busy_handler(sqlite3*, int(*)(void*,int), void*);


 int sqlite3_busy_timeout(sqlite3*, int ms);

/*
// Legacy, don't want to use this in new code
 int sqlite3_get_table(
  sqlite3 *db,          // An open database
  const char *zSql,     // SQL to be evaluated
  char ***pazResult,    // Results of the query
  int *pnRow,           // Number of result rows written here
  int *pnColumn,        // Number of result columns written here
  char **pzErrmsg       // Error msg written here
);
 void sqlite3_free_table(char **result);
*/

 char *sqlite3_mprintf(const char*,...);
 char *sqlite3_vmprintf(const char*, va_list);
 char *sqlite3_snprintf(int,char*,const char*, ...);
 char *sqlite3_vsnprintf(int,char*,const char*, va_list);


 void *sqlite3_malloc(int);
 void *sqlite3_realloc(void*, int);
 void sqlite3_free(void*);


 sqlite3_int64 sqlite3_memory_used(void);
 sqlite3_int64 sqlite3_memory_highwater(int resetFlag);


 void sqlite3_randomness(int N, void *P);


int sqlite3_set_authorizer(sqlite3*,
  int (*xAuth)(void*,int,const char*,const char*,const char*,const char*),
  void *pUserData
);



 void *sqlite3_trace(sqlite3*, void(*xTrace)(void*,const char*), void*);
 void *sqlite3_profile(sqlite3*,
 void(*xProfile)(void*,const char*,sqlite3_uint64), void*);


 void sqlite3_progress_handler(sqlite3*, int, int(*)(void*), void*);

 int sqlite3_open(
  const char *filename,   /* Database filename (UTF-8) */
  sqlite3 **ppDb          /* OUT: SQLite db handle */
);
int sqlite3_open16(
  const void *filename,   /* Database filename (UTF-16) */
  sqlite3 **ppDb          /* OUT: SQLite db handle */
);
int sqlite3_open_v2(
  const char *filename,   /* Database filename (UTF-8) */
  sqlite3 **ppDb,         /* OUT: SQLite db handle */
  int flags,              /* Flags */
  const char *zVfs        /* Name of VFS module to use */
);


const char *sqlite3_uri_parameter(const char *zFilename, const char *zParam);
int sqlite3_uri_boolean(const char *zFile, const char *zParam, int bDefault);
sqlite3_int64 sqlite3_uri_int64(const char*, const char*, sqlite3_int64);



int sqlite3_errcode(sqlite3 *db);
int sqlite3_extended_errcode(sqlite3 *db);
const char *sqlite3_errmsg(sqlite3*);
const void *sqlite3_errmsg16(sqlite3*);


typedef struct sqlite3_stmt sqlite3_stmt;


int sqlite3_limit(sqlite3*, int id, int newVal);




int sqlite3_prepare(
  sqlite3 *db,            /* Database handle */
  const char *zSql,       /* SQL statement, UTF-8 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const char **pzTail     /* OUT: Pointer to unused portion of zSql */
);
 int sqlite3_prepare_v2(
  sqlite3 *db,            /* Database handle */
  const char *zSql,       /* SQL statement, UTF-8 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const char **pzTail     /* OUT: Pointer to unused portion of zSql */
);
 int sqlite3_prepare16(
  sqlite3 *db,            /* Database handle */
  const void *zSql,       /* SQL statement, UTF-16 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const void **pzTail     /* OUT: Pointer to unused portion of zSql */
);
 int sqlite3_prepare16_v2(
  sqlite3 *db,            /* Database handle */
  const void *zSql,       /* SQL statement, UTF-16 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const void **pzTail     /* OUT: Pointer to unused portion of zSql */
);


const char *sqlite3_sql(sqlite3_stmt *pStmt);
int sqlite3_stmt_readonly(sqlite3_stmt *pStmt);
int sqlite3_stmt_busy(sqlite3_stmt*);


typedef struct Mem sqlite3_value;


typedef struct sqlite3_context sqlite3_context;


 int sqlite3_bind_blob(sqlite3_stmt*, int, const void*, int n, void(*)(void*));
 int sqlite3_bind_double(sqlite3_stmt*, int, double);
 int sqlite3_bind_int(sqlite3_stmt*, int, int);
 int sqlite3_bind_int64(sqlite3_stmt*, int, sqlite3_int64);
 int sqlite3_bind_null(sqlite3_stmt*, int);
 int sqlite3_bind_text(sqlite3_stmt*, int, const char*, int n, void(*)(void*));
 int sqlite3_bind_text16(sqlite3_stmt*, int, const void*, int, void(*)(void*));
 int sqlite3_bind_value(sqlite3_stmt*, int, const sqlite3_value*);
 int sqlite3_bind_zeroblob(sqlite3_stmt*, int, int n);
 int sqlite3_bind_parameter_count(sqlite3_stmt*);
 const char *sqlite3_bind_parameter_name(sqlite3_stmt*, int);
 int sqlite3_bind_parameter_index(sqlite3_stmt*, const char *zName);
 int sqlite3_clear_bindings(sqlite3_stmt*);
 int sqlite3_column_count(sqlite3_stmt *pStmt);
 const char *sqlite3_column_name(sqlite3_stmt*, int N);
 const void *sqlite3_column_name16(sqlite3_stmt*, int N);
 const char *sqlite3_column_database_name(sqlite3_stmt*,int);
 const void *sqlite3_column_database_name16(sqlite3_stmt*,int);
 const char *sqlite3_column_table_name(sqlite3_stmt*,int);
 const void *sqlite3_column_table_name16(sqlite3_stmt*,int);
 const char *sqlite3_column_origin_name(sqlite3_stmt*,int);
 const void *sqlite3_column_origin_name16(sqlite3_stmt*,int);
 const char *sqlite3_column_decltype(sqlite3_stmt*,int);
 const void *sqlite3_column_decltype16(sqlite3_stmt*,int);
 int sqlite3_step(sqlite3_stmt*);
 int sqlite3_data_count(sqlite3_stmt *pStmt);
 const void *sqlite3_column_blob(sqlite3_stmt*, int iCol);
 int sqlite3_column_bytes(sqlite3_stmt*, int iCol);
 int sqlite3_column_bytes16(sqlite3_stmt*, int iCol);
 double sqlite3_column_double(sqlite3_stmt*, int iCol);
 int sqlite3_column_int(sqlite3_stmt*, int iCol);
 sqlite3_int64 sqlite3_column_int64(sqlite3_stmt*, int iCol);
 const unsigned char *sqlite3_column_text(sqlite3_stmt*, int iCol);
 const void *sqlite3_column_text16(sqlite3_stmt*, int iCol);
 int sqlite3_column_type(sqlite3_stmt*, int iCol);
 sqlite3_value *sqlite3_column_value(sqlite3_stmt*, int iCol);
 int sqlite3_finalize(sqlite3_stmt *pStmt);
 int sqlite3_reset(sqlite3_stmt *pStmt);


 int sqlite3_create_function(
  sqlite3 *db,
  const char *zFunctionName,
  int nArg,
  int eTextRep,
  void *pApp,
  void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
  void (*xStep)(sqlite3_context*,int,sqlite3_value**),
  void (*xFinal)(sqlite3_context*)
);
 int sqlite3_create_function16(
  sqlite3 *db,
  const void *zFunctionName,
  int nArg,
  int eTextRep,
  void *pApp,
  void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
  void (*xStep)(sqlite3_context*,int,sqlite3_value**),
  void (*xFinal)(sqlite3_context*)
);
 int sqlite3_create_function_v2(
  sqlite3 *db,

  const char *zFunctionName,
  int nArg,
  int eTextRep,
  void *pApp,
  void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
  void (*xStep)(sqlite3_context*,int,sqlite3_value**),
  void (*xFinal)(sqlite3_context*),
  void(*xDestroy)(void*)
);






 const void *sqlite3_value_blob(sqlite3_value*);
 int sqlite3_value_bytes(sqlite3_value*);
 int sqlite3_value_bytes16(sqlite3_value*);
 double sqlite3_value_double(sqlite3_value*);
 int sqlite3_value_int(sqlite3_value*);
 sqlite3_int64 sqlite3_value_int64(sqlite3_value*);
 const unsigned char *sqlite3_value_text(sqlite3_value*);
 const void *sqlite3_value_text16(sqlite3_value*);
 const void *sqlite3_value_text16le(sqlite3_value*);
 const void *sqlite3_value_text16be(sqlite3_value*);
 int sqlite3_value_type(sqlite3_value*);
 int sqlite3_value_numeric_type(sqlite3_value*);


 void *sqlite3_aggregate_context(sqlite3_context*, int nBytes);


 void *sqlite3_user_data(sqlite3_context*);


 sqlite3 *sqlite3_context_db_handle(sqlite3_context*);


 void *sqlite3_get_auxdata(sqlite3_context*, int N);
 void sqlite3_set_auxdata(sqlite3_context*, int N, void*, void (*)(void*));





 void sqlite3_result_blob(sqlite3_context*, const void*, int, void(*)(void*));
 void sqlite3_result_double(sqlite3_context*, double);
 void sqlite3_result_error(sqlite3_context*, const char*, int);
 void sqlite3_result_error16(sqlite3_context*, const void*, int);
 void sqlite3_result_error_toobig(sqlite3_context*);
 void sqlite3_result_error_nomem(sqlite3_context*);
 void sqlite3_result_error_code(sqlite3_context*, int);
 void sqlite3_result_int(sqlite3_context*, int);
 void sqlite3_result_int64(sqlite3_context*, sqlite3_int64);
 void sqlite3_result_null(sqlite3_context*);
 void sqlite3_result_text(sqlite3_context*, const char*, int, void(*)(void*));
 void sqlite3_result_text16(sqlite3_context*, const void*, int, void(*)(void*));
 void sqlite3_result_text16le(sqlite3_context*, const void*, int,void(*)(void*));
 void sqlite3_result_text16be(sqlite3_context*, const void*, int,void(*)(void*));
 void sqlite3_result_value(sqlite3_context*, sqlite3_value*);
 void sqlite3_result_zeroblob(sqlite3_context*, int n);


 int sqlite3_create_collation(
  sqlite3*,
  const char *zName,
  int eTextRep,
  void *pArg,
  int(*xCompare)(void*,int,const void*,int,const void*)
);
 int sqlite3_create_collation_v2(
  sqlite3*,
  const char *zName,
  int eTextRep,
  void *pArg,
  int(*xCompare)(void*,int,const void*,int,const void*),
  void(*xDestroy)(void*)
);
 int sqlite3_create_collation16(
  sqlite3*,
  const void *zName,
  int eTextRep,
  void *pArg,
  int(*xCompare)(void*,int,const void*,int,const void*)
);


 int sqlite3_collation_needed(
  sqlite3*,
  void*,
  void(*)(void*,sqlite3*,int eTextRep,const char*)
);
 int sqlite3_collation_needed16(
  sqlite3*,
  void*,
  void(*)(void*,sqlite3*,int eTextRep,const void*)
);




 int sqlite3_sleep(int);


  char *sqlite3_temp_directory;


 int sqlite3_get_autocommit(sqlite3*);


 sqlite3 *sqlite3_db_handle(sqlite3_stmt*);


 const char *sqlite3_db_filename(sqlite3 *db, const char *zDbName);

 int sqlite3_db_readonly(sqlite3 *db, const char *zDbName);


 sqlite3_stmt *sqlite3_next_stmt(sqlite3 *pDb, sqlite3_stmt *pStmt);


 void *sqlite3_commit_hook(sqlite3*, int(*)(void*), void*);
 void *sqlite3_rollback_hook(sqlite3*, void(*)(void *), void*);


 void *sqlite3_update_hook(
  sqlite3*,
  void(*)(void *,int ,char const *,char const *,sqlite3_int64),
  void*
);


 int sqlite3_enable_shared_cache(int);


 int sqlite3_release_memory(int);


 int sqlite3_db_release_memory(sqlite3*);


 sqlite3_int64 sqlite3_soft_heap_limit64(sqlite3_int64 N);


 int sqlite3_table_column_metadata(
  sqlite3 *db,                /* Connection handle */
  const char *zDbName,        /* Database name or NULL */
  const char *zTableName,     /* Table name */
  const char *zColumnName,    /* Column name */
  char const **pzDataType,    /* OUTPUT: Declared data type */
  char const **pzCollSeq,     /* OUTPUT: Collation sequence name */
  int *pNotNull,              /* OUTPUT: True if NOT NULL constraint exists */
  int *pPrimaryKey,           /* OUTPUT: True if column part of PK */
  int *pAutoinc               /* OUTPUT: True if column is auto-increment */
);


 int sqlite3_load_extension(
  sqlite3 *db,          /* Load the extension into this database connection */
  const char *zFile,    /* Name of the shared library containing extension */
  const char *zProc,    /* Entry point.  Derived from zFile if 0 */
  char **pzErrMsg       /* Put error message here if not 0 */
);


 int sqlite3_enable_load_extension(sqlite3 *db, int onoff);


 int sqlite3_auto_extension(void (*xEntryPoint)(void));


 void sqlite3_reset_auto_extension(void);




typedef struct sqlite3_vtab sqlite3_vtab;
typedef struct sqlite3_index_info sqlite3_index_info;
typedef struct sqlite3_vtab_cursor sqlite3_vtab_cursor;
typedef struct sqlite3_module sqlite3_module;


struct sqlite3_module {
  int iVersion;
  int (*xCreate)(sqlite3*, void *pAux,
               int argc, const char *const*argv,
               sqlite3_vtab **ppVTab, char**);
  int (*xConnect)(sqlite3*, void *pAux,
               int argc, const char *const*argv,
               sqlite3_vtab **ppVTab, char**);
  int (*xBestIndex)(sqlite3_vtab *pVTab, sqlite3_index_info*);
  int (*xDisconnect)(sqlite3_vtab *pVTab);
  int (*xDestroy)(sqlite3_vtab *pVTab);
  int (*xOpen)(sqlite3_vtab *pVTab, sqlite3_vtab_cursor **ppCursor);
  int (*xClose)(sqlite3_vtab_cursor*);
  int (*xFilter)(sqlite3_vtab_cursor*, int idxNum, const char *idxStr,
                int argc, sqlite3_value **argv);
  int (*xNext)(sqlite3_vtab_cursor*);
  int (*xEof)(sqlite3_vtab_cursor*);
  int (*xColumn)(sqlite3_vtab_cursor*, sqlite3_context*, int);
  int (*xRowid)(sqlite3_vtab_cursor*, sqlite3_int64 *pRowid);
  int (*xUpdate)(sqlite3_vtab *, int, sqlite3_value **, sqlite3_int64 *);
  int (*xBegin)(sqlite3_vtab *pVTab);
  int (*xSync)(sqlite3_vtab *pVTab);
  int (*xCommit)(sqlite3_vtab *pVTab);
  int (*xRollback)(sqlite3_vtab *pVTab);
  int (*xFindFunction)(sqlite3_vtab *pVtab, int nArg, const char *zName,
                       void (**pxFunc)(sqlite3_context*,int,sqlite3_value**),
                       void **ppArg);
  int (*xRename)(sqlite3_vtab *pVtab, const char *zNew);
  /* The methods above are in version 1 of the sqlite_module object. Those
  ** below are for version 2 and greater. */
  int (*xSavepoint)(sqlite3_vtab *pVTab, int);
  int (*xRelease)(sqlite3_vtab *pVTab, int);
  int (*xRollbackTo)(sqlite3_vtab *pVTab, int);
};


struct sqlite3_index_info {
  /* Inputs */
  int nConstraint;           /* Number of entries in aConstraint */
  struct sqlite3_index_constraint {
    int iColumn;              /* Column on left-hand side of constraint */
    unsigned char op;         /* Constraint operator */
    unsigned char usable;     /* True if this constraint is usable */
    int iTermOffset;          /* Used internally - xBestIndex should ignore */
  } *aConstraint;            /* Table of WHERE clause constraints */
  int nOrderBy;              /* Number of terms in the ORDER BY clause */
  struct sqlite3_index_orderby {
    int iColumn;              /* Column number */
    unsigned char desc;       /* True for DESC.  False for ASC. */
  } *aOrderBy;               /* The ORDER BY clause */
  /* Outputs */
  struct sqlite3_index_constraint_usage {
    int argvIndex;           /* if >0, constraint is part of argv to xFilter */
    unsigned char omit;      /* Do not code a test for this constraint */
  } *aConstraintUsage;
  int idxNum;                /* Number used to identify the index */
  char *idxStr;              /* String, possibly obtained from sqlite3_malloc */
  int needToFreeIdxStr;      /* Free idxStr using sqlite3_free() if true */
  int orderByConsumed;       /* True if output is already ordered */
  double estimatedCost;      /* Estimated cost of using this index */
};





 int sqlite3_create_module(
  sqlite3 *db,               /* SQLite connection to register module with */
  const char *zName,         /* Name of the module */
  const sqlite3_module *p,   /* Methods for the module */
  void *pClientData          /* Client data for xCreate/xConnect */
);
 int sqlite3_create_module_v2(
  sqlite3 *db,               /* SQLite connection to register module with */
  const char *zName,         /* Name of the module */
  const sqlite3_module *p,   /* Methods for the module */
  void *pClientData,         /* Client data for xCreate/xConnect */
  void(*xDestroy)(void*)     /* Module destructor function */
);


struct sqlite3_vtab {
  const sqlite3_module *pModule;  /* The module for this virtual table */
  int nRef;                       /* NO LONGER USED */
  char *zErrMsg;                  /* Error message from sqlite3_mprintf() */
  /* Virtual table implementations will typically add additional fields */
};


struct sqlite3_vtab_cursor {
  sqlite3_vtab *pVtab;      /* Virtual table of this cursor */
  /* Virtual table implementations will typically add additional fields */
};


 int sqlite3_declare_vtab(sqlite3*, const char *zSQL);


 int sqlite3_overload_function(sqlite3*, const char *zFuncName, int nArg);




typedef struct sqlite3_blob sqlite3_blob;


 int sqlite3_blob_open(
  sqlite3*,
  const char *zDb,
  const char *zTable,
  const char *zColumn,
  sqlite3_int64 iRow,
  int flags,
  sqlite3_blob **ppBlob
);


  int sqlite3_blob_reopen(sqlite3_blob *, sqlite3_int64);


 int sqlite3_blob_close(sqlite3_blob *);


 int sqlite3_blob_bytes(sqlite3_blob *);


 int sqlite3_blob_read(sqlite3_blob *, void *Z, int N, int iOffset);


 int sqlite3_blob_write(sqlite3_blob *, const void *z, int n, int iOffset);


 sqlite3_vfs *sqlite3_vfs_find(const char *zVfsName);
 int sqlite3_vfs_register(sqlite3_vfs*, int makeDflt);
 int sqlite3_vfs_unregister(sqlite3_vfs*);


 sqlite3_mutex *sqlite3_mutex_alloc(int);
 void sqlite3_mutex_free(sqlite3_mutex*);
 void sqlite3_mutex_enter(sqlite3_mutex*);
 int sqlite3_mutex_try(sqlite3_mutex*);
 void sqlite3_mutex_leave(sqlite3_mutex*);


typedef struct sqlite3_mutex_methods sqlite3_mutex_methods;
struct sqlite3_mutex_methods {
  int (*xMutexInit)(void);
  int (*xMutexEnd)(void);
  sqlite3_mutex *(*xMutexAlloc)(int);
  void (*xMutexFree)(sqlite3_mutex *);
  void (*xMutexEnter)(sqlite3_mutex *);
  int (*xMutexTry)(sqlite3_mutex *);
  void (*xMutexLeave)(sqlite3_mutex *);
  int (*xMutexHeld)(sqlite3_mutex *);
  int (*xMutexNotheld)(sqlite3_mutex *);
};





 sqlite3_mutex *sqlite3_db_mutex(sqlite3*);

 int sqlite3_file_control(sqlite3*, const char *zDbName, int op, void*);


 int sqlite3_test_control(int op, ...);



 int sqlite3_status(int op, int *pCurrent, int *pHighwater, int resetFlag);


 int sqlite3_db_status(sqlite3*, int op, int *pCur, int *pHiwtr, int resetFlg);





 int sqlite3_stmt_status(sqlite3_stmt*, int op,int resetFlg);





typedef struct sqlite3_pcache sqlite3_pcache;


typedef struct sqlite3_pcache_page sqlite3_pcache_page;
struct sqlite3_pcache_page {
  void *pBuf;        /* The content of the page */
  void *pExtra;      /* Extra information associated with the page */
};


typedef struct sqlite3_pcache_methods2 sqlite3_pcache_methods2;
struct sqlite3_pcache_methods2 {
  int iVersion;
  void *pArg;
  int (*xInit)(void*);
  void (*xShutdown)(void*);
  sqlite3_pcache *(*xCreate)(int szPage, int szExtra, int bPurgeable);
  void (*xCachesize)(sqlite3_pcache*, int nCachesize);
  int (*xPagecount)(sqlite3_pcache*);
  sqlite3_pcache_page *(*xFetch)(sqlite3_pcache*, unsigned key, int createFlag);
  void (*xUnpin)(sqlite3_pcache*, sqlite3_pcache_page*, int discard);
  void (*xRekey)(sqlite3_pcache*, sqlite3_pcache_page*,
      unsigned oldKey, unsigned newKey);
  void (*xTruncate)(sqlite3_pcache*, unsigned iLimit);
  void (*xDestroy)(sqlite3_pcache*);
  void (*xShrink)(sqlite3_pcache*);
};




typedef struct sqlite3_backup sqlite3_backup;


 sqlite3_backup *sqlite3_backup_init(
  sqlite3 *pDest,                        /* Destination database handle */
  const char *zDestName,                 /* Destination database name */
  sqlite3 *pSource,                      /* Source database handle */
  const char *zSourceName                /* Source database name */
);
 int sqlite3_backup_step(sqlite3_backup *p, int nPage);
 int sqlite3_backup_finish(sqlite3_backup *p);
 int sqlite3_backup_remaining(sqlite3_backup *p);
 int sqlite3_backup_pagecount(sqlite3_backup *p);


 int sqlite3_unlock_notify(
  sqlite3 *pBlocked,                          /* Waiting connection */
  void (*xNotify)(void **apArg, int nArg),    /* Callback function to invoke */
  void *pNotifyArg                            /* Argument to pass to xNotify */
);



 int sqlite3_stricmp(const char *, const char *);
 int sqlite3_strnicmp(const char *, const char *, int);


 void sqlite3_log(int iErrCode, const char *zFormat, ...);


 void *sqlite3_wal_hook(
  sqlite3*,
  int(*)(void *,sqlite3*,const char*,int),
  void*
);


 int sqlite3_wal_autocheckpoint(sqlite3 *db, int N);


 int sqlite3_wal_checkpoint(sqlite3 *db, const char *zDb);


 int sqlite3_wal_checkpoint_v2(
  sqlite3 *db,                    /* Database handle */
  const char *zDb,                /* Name of attached database (or NULL) */
  int eMode,                      /* SQLITE_CHECKPOINT_* value */
  int *pnLog,                     /* OUT: Size of WAL log in frames */
  int *pnCkpt                     /* OUT: Total number of frames checkpointed */
);


 int sqlite3_vtab_config(sqlite3*, int op, ...);

 int sqlite3_vtab_on_conflict(sqlite3 *);






// RTree Geometry Queries
typedef struct sqlite3_rtree_geometry sqlite3_rtree_geometry;


 int sqlite3_rtree_geometry_callback(
  sqlite3 *db,
  const char *zGeom,
  int (*xGeom)(sqlite3_rtree_geometry*, int n, double *a, int *pRes),
  void *pContext
);


struct sqlite3_rtree_geometry {
  void *pContext;
  int nParam;
  double *aParam;
  void *pUser;
  void (*xDelUser)(void *);
};
]]

function findrchar(s, c)
    local p = ffi.cast("const char *", s);
    local offset = strlen(p);

    while offset >= 0 do
        if p[offset] == c then
            return offset +1
        end
        offset = offset - 1;
    end

    return 0
end


local Lib = ffi.load( "sqlite3")

-- initialize the library
Lib.sqlite3_initialize();

local sqlite3 = {
    sqlite3_aggregate_context = Lib.sqlite3_aggregate_context,
--    sqlite3_aggregate_count = Lib.sqlite3_aggregate_count,
    sqlite3_auto_extension = Lib.sqlite3_auto_extension,
    sqlite3_backup_finish = Lib.sqlite3_backup_finish,
    sqlite3_backup_init = Lib.sqlite3_backup_init,
    sqlite3_backup_pagecount = Lib.sqlite3_backup_pagecount,
    sqlite3_backup_remaining = Lib.sqlite3_backup_remaining,
    sqlite3_backup_step = Lib.sqlite3_backup_step,
    sqlite3_bind_blob = Lib.sqlite3_bind_blob,
    sqlite3_bind_double = Lib.sqlite3_bind_double,
    sqlite3_bind_int = Lib.sqlite3_bind_int,
    sqlite3_bind_int64 = Lib.sqlite3_bind_int64,
    sqlite3_bind_null = Lib.sqlite3_bind_null,
    sqlite3_bind_parameter_count = Lib.sqlite3_bind_parameter_count,
    sqlite3_bind_parameter_index = Lib.sqlite3_bind_parameter_index,
    sqlite3_bind_parameter_name = Lib.sqlite3_bind_parameter_name,
    sqlite3_bind_text = Lib.sqlite3_bind_text,
    sqlite3_bind_text16 = Lib.sqlite3_bind_text16,
    sqlite3_bind_value = Lib.sqlite3_bind_value,
    sqlite3_bind_zeroblob = Lib.sqlite3_bind_zeroblob,
    sqlite3_blob_bytes = Lib.sqlite3_blob_bytes,
    sqlite3_blob_close = Lib.sqlite3_blob_close,
    sqlite3_blob_open = Lib.sqlite3_blob_open,
    sqlite3_blob_read = Lib.sqlite3_blob_read,
    sqlite3_blob_reopen = Lib.sqlite3_blob_reopen,
    sqlite3_blob_write = Lib.sqlite3_blob_write,
    sqlite3_busy_handler = Lib.sqlite3_busy_handler,
    sqlite3_busy_timeout = Lib.sqlite3_busy_timeout,
    sqlite3_changes = Lib.sqlite3_changes,
    sqlite3_clear_bindings = Lib.sqlite3_clear_bindings,
    sqlite3_close = Lib.sqlite3_close,
    sqlite3_collation_needed = Lib.sqlite3_collation_needed,
    sqlite3_collation_needed16 = Lib.sqlite3_collation_needed16,
    sqlite3_column_blob = Lib.sqlite3_column_blob,
    sqlite3_column_bytes = Lib.sqlite3_column_bytes,
    sqlite3_column_bytes16 = Lib.sqlite3_column_bytes16,
    sqlite3_column_count = Lib.sqlite3_column_count,
    sqlite3_column_database_name = Lib.sqlite3_column_database_name,
    sqlite3_column_database_name16 = Lib.sqlite3_column_database_name16,
    sqlite3_column_decltype = Lib.sqlite3_column_decltype,
    sqlite3_column_decltype16 = Lib.sqlite3_column_decltype16,
    sqlite3_column_double = Lib.sqlite3_column_double,
    sqlite3_column_int = Lib.sqlite3_column_int,
    sqlite3_column_int64 = Lib.sqlite3_column_int64,
    sqlite3_column_name = Lib.sqlite3_column_name,
    sqlite3_column_name16 = Lib.sqlite3_column_name16,
    sqlite3_column_origin_name = Lib.sqlite3_column_origin_name,
    sqlite3_column_origin_name16 = Lib.sqlite3_column_origin_name16,
    sqlite3_column_table_name = Lib.sqlite3_column_table_name,
    sqlite3_column_table_name16 = Lib.sqlite3_column_table_name16,
    sqlite3_column_text = Lib.sqlite3_column_text,
    sqlite3_column_text16 = Lib.sqlite3_column_text16,
    sqlite3_column_type = Lib.sqlite3_column_type,
    sqlite3_column_value = Lib.sqlite3_column_value,
    sqlite3_commit_hook = Lib.sqlite3_commit_hook,
--    sqlite3_compileoption_get = Lib.sqlite3_compileoption_get,
--    sqlite3_compileoption_used = Lib.sqlite3_compileoption_used,
    sqlite3_complete = Lib.sqlite3_complete,
    sqlite3_complete16 = Lib.sqlite3_complete16,
    sqlite3_config = Lib.sqlite3_config,
    sqlite3_context_db_handle = Lib.sqlite3_context_db_handle,
    sqlite3_create_collation = Lib.sqlite3_create_collation,
    sqlite3_create_collation16 = Lib.sqlite3_create_collation16,
    sqlite3_create_collation_v2 = Lib.sqlite3_create_collation_v2,
    sqlite3_create_function = Lib.sqlite3_create_function,
    sqlite3_create_function16 = Lib.sqlite3_create_function16,
    sqlite3_create_function_v2 = Lib.sqlite3_create_function_v2,
    sqlite3_create_module = Lib.sqlite3_create_module,
    sqlite3_create_module_v2 = Lib.sqlite3_create_module_v2,
    sqlite3_data_count = Lib.sqlite3_data_count,
    sqlite3_db_config = Lib.sqlite3_db_config,
    sqlite3_db_filename = Lib.sqlite3_db_filename,
    sqlite3_db_handle = Lib.sqlite3_db_handle,
    sqlite3_db_mutex = Lib.sqlite3_db_mutex,
    sqlite3_db_readonly = Lib.sqlite3_db_readonly,
    sqlite3_db_release_memory = Lib.sqlite3_db_release_memory,
    sqlite3_db_status = Lib.sqlite3_db_status,
    sqlite3_declare_vtab = Lib.sqlite3_declare_vtab,
    sqlite3_enable_load_extension = Lib.sqlite3_enable_load_extension,
    sqlite3_enable_shared_cache = Lib.sqlite3_enable_shared_cache,
    sqlite3_errcode = Lib.sqlite3_errcode,
    sqlite3_errmsg = Lib.sqlite3_errmsg,
    sqlite3_errmsg16 = Lib.sqlite3_errmsg16,
    sqlite3_exec = Lib.sqlite3_exec,
--    sqlite3_expired = Lib.sqlite3_expired,
    sqlite3_extended_errcode = Lib.sqlite3_extended_errcode,
    sqlite3_extended_result_codes = Lib.sqlite3_extended_result_codes,
    sqlite3_file_control = Lib.sqlite3_file_control,
    sqlite3_finalize = Lib.sqlite3_finalize,
    sqlite3_free = Lib.sqlite3_free,
--    sqlite3_free_table = Lib.sqlite3_free_table,
    sqlite3_get_autocommit = Lib.sqlite3_get_autocommit,
    sqlite3_get_auxdata = Lib.sqlite3_get_auxdata,
--    sqlite3_get_table = Lib.sqlite3_get_table,
--    sqlite3_global_recover = Lib.sqlite3_global_recover,
    sqlite3_initialize = Lib.sqlite3_initialize,
    sqlite3_interrupt = Lib.sqlite3_interrupt,
    sqlite3_last_insert_rowid = Lib.sqlite3_last_insert_rowid,
    sqlite3_libversion = Lib.sqlite3_libversion,
    sqlite3_libversion_number = Lib.sqlite3_libversion_number,
    sqlite3_limit = Lib.sqlite3_limit,
    sqlite3_load_extension = Lib.sqlite3_load_extension,
    sqlite3_log = Lib.sqlite3_log,
    sqlite3_malloc = Lib.sqlite3_malloc,
--    sqlite3_memory_alarm = Lib.sqlite3_memory_alarm,
    sqlite3_memory_highwater = Lib.sqlite3_memory_highwater,
    sqlite3_memory_used = Lib.sqlite3_memory_used,
    sqlite3_mprintf = Lib.sqlite3_mprintf,
    sqlite3_mutex_alloc = Lib.sqlite3_mutex_alloc,
    sqlite3_mutex_enter = Lib.sqlite3_mutex_enter,
    sqlite3_mutex_free = Lib.sqlite3_mutex_free,
    sqlite3_mutex_leave = Lib.sqlite3_mutex_leave,
    sqlite3_mutex_try = Lib.sqlite3_mutex_try,
    sqlite3_next_stmt = Lib.sqlite3_next_stmt,
    sqlite3_open = Lib.sqlite3_open,
    sqlite3_open16 = Lib.sqlite3_open16,
    sqlite3_open_v2 = Lib.sqlite3_open_v2,
    sqlite3_os_end = Lib.sqlite3_os_end,
    sqlite3_os_init = Lib.sqlite3_os_init,
    sqlite3_overload_function = Lib.sqlite3_overload_function,
    sqlite3_prepare = Lib.sqlite3_prepare,
    sqlite3_prepare16 = Lib.sqlite3_prepare16,
    sqlite3_prepare16_v2 = Lib.sqlite3_prepare16_v2,
    sqlite3_prepare_v2 = Lib.sqlite3_prepare_v2,
    sqlite3_profile = Lib.sqlite3_profile,
    sqlite3_progress_handler = Lib.sqlite3_progress_handler,
    sqlite3_randomness = Lib.sqlite3_randomness,
    sqlite3_realloc = Lib.sqlite3_realloc,
    sqlite3_release_memory = Lib.sqlite3_release_memory,
    sqlite3_reset = Lib.sqlite3_reset,
    sqlite3_reset_auto_extension = Lib.sqlite3_reset_auto_extension,
    sqlite3_result_blob = Lib.sqlite3_result_blob,
    sqlite3_result_double = Lib.sqlite3_result_double,
    sqlite3_result_error = Lib.sqlite3_result_error,
    sqlite3_result_error16 = Lib.sqlite3_result_error16,
    sqlite3_result_error_code = Lib.sqlite3_result_error_code,
    sqlite3_result_error_nomem = Lib.sqlite3_result_error_nomem,
    sqlite3_result_error_toobig = Lib.sqlite3_result_error_toobig,
    sqlite3_result_int = Lib.sqlite3_result_int,
    sqlite3_result_int64 = Lib.sqlite3_result_int64,
    sqlite3_result_null = Lib.sqlite3_result_null,
    sqlite3_result_text = Lib.sqlite3_result_text,
    sqlite3_result_text16 = Lib.sqlite3_result_text16,
    sqlite3_result_text16be = Lib.sqlite3_result_text16be,
    sqlite3_result_text16le = Lib.sqlite3_result_text16le,
    sqlite3_result_value = Lib.sqlite3_result_value,
    sqlite3_result_zeroblob = Lib.sqlite3_result_zeroblob,
    sqlite3_rollback_hook = Lib.sqlite3_rollback_hook,
    sqlite3_rtree_geometry_callback = Lib.sqlite3_rtree_geometry_callback,
    sqlite3_set_authorizer = Lib.sqlite3_set_authorizer,
    sqlite3_set_auxdata = Lib.sqlite3_set_auxdata,
    sqlite3_shutdown = Lib.sqlite3_shutdown,
    sqlite3_sleep = Lib.sqlite3_sleep,
    sqlite3_snprintf = Lib.sqlite3_snprintf,
--    sqlite3_soft_heap_limit = Lib.sqlite3_soft_heap_limit,
    sqlite3_soft_heap_limit64 = Lib.sqlite3_soft_heap_limit64,
    sqlite3_sourceid = Lib.sqlite3_sourceid,
    sqlite3_sql = Lib.sqlite3_sql,
    sqlite3_status = Lib.sqlite3_status,
    sqlite3_step = Lib.sqlite3_step,
    sqlite3_stmt_busy = Lib.sqlite3_stmt_busy,
    sqlite3_stmt_readonly = Lib.sqlite3_stmt_readonly,
    sqlite3_stmt_status = Lib.sqlite3_stmt_status,
    sqlite3_stricmp = Lib.sqlite3_stricmp,
    sqlite3_strnicmp = Lib.sqlite3_strnicmp,
    sqlite3_table_column_metadata = Lib.sqlite3_table_column_metadata,
    sqlite3_test_control = Lib.sqlite3_test_control,
--    sqlite3_thread_cleanup = Lib.sqlite3_thread_cleanup,
    sqlite3_threadsafe = Lib.sqlite3_threadsafe,
    sqlite3_total_changes = Lib.sqlite3_total_changes,
    sqlite3_trace = Lib.sqlite3_trace,
--    sqlite3_transfer_bindings = Lib.sqlite3_transfer_bindings,
    sqlite3_update_hook = Lib.sqlite3_update_hook,
    sqlite3_uri_boolean = Lib.sqlite3_uri_boolean,
    sqlite3_uri_int64 = Lib.sqlite3_uri_int64,
    sqlite3_uri_parameter = Lib.sqlite3_uri_parameter,
    sqlite3_user_data = Lib.sqlite3_user_data,
    sqlite3_value_blob = Lib.sqlite3_value_blob,
    sqlite3_value_bytes = Lib.sqlite3_value_bytes,
    sqlite3_value_bytes16 = Lib.sqlite3_value_bytes16,
    sqlite3_value_double = Lib.sqlite3_value_double,
    sqlite3_value_int = Lib.sqlite3_value_int,
    sqlite3_value_int64 = Lib.sqlite3_value_int64,
    sqlite3_value_numeric_type = Lib.sqlite3_value_numeric_type,
    sqlite3_value_text = Lib.sqlite3_value_text,
    sqlite3_value_text16 = Lib.sqlite3_value_text16,
    sqlite3_value_text16be = Lib.sqlite3_value_text16be,
    sqlite3_value_text16le = Lib.sqlite3_value_text16le,
    sqlite3_value_type = Lib.sqlite3_value_type,
    sqlite3_vfs_find = Lib.sqlite3_vfs_find,
    sqlite3_vfs_register = Lib.sqlite3_vfs_register,
    sqlite3_vfs_unregister = Lib.sqlite3_vfs_unregister,
    sqlite3_vmprintf = Lib.sqlite3_vmprintf,
    sqlite3_vsnprintf = Lib.sqlite3_vsnprintf,
    sqlite3_vtab_config = Lib.sqlite3_vtab_config,
    sqlite3_vtab_on_conflict = Lib.sqlite3_vtab_on_conflict,
    sqlite3_wal_autocheckpoint = Lib.sqlite3_wal_autocheckpoint,
    sqlite3_wal_checkpoint = Lib.sqlite3_wal_checkpoint,
    sqlite3_wal_checkpoint_v2 = Lib.sqlite3_wal_checkpoint_v2,
    sqlite3_wal_hook = Lib.sqlite3_wal_hook,
--    sqlite3_win32_mbcs_to_utf8 = Lib.sqlite3_win32_mbcs_to_utf8,
--    sqlite3_win32_utf8_to_mbcs = Lib.sqlite3_win32_utf8_to_mbcs,
}

return Lib;
