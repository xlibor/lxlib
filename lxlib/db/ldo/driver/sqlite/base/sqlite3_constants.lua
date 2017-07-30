local bit = require("bit");
local bor = bit.bor;
local lshift = bit.lshift;

local SQLITE_IOERR = 10;
local SQLITE_LOCKED = 6;
local SQLITE_BUSY = 5;
local SQLITE_CANTOPEN = 14;
local SQLITE_CORRUPT = 11;
local SQLITE_ABORT = 4;
local SQLITE_READONLY = 8;


local sqliteerrorcodes = {
{"SQLITE_OK",           0   ," Successful result "};

-- beginning-of-error-codes

{"SQLITE_ERROR",        1   ," SQL error or missing database "};
{"SQLITE_INTERNAL",     2   ," Internal logic error in SQLite "};
{"SQLITE_PERM",         3   ," Access permission denied "};
{"SQLITE_ABORT",        4   ," Callback routine requested an abort "};
{"SQLITE_BUSY",         5   ," The database file is locked "};
{"SQLITE_LOCKED",       6   ," A table in the database is locked "};
{"SQLITE_NOMEM",        7   ," A malloc() failed "};
{"SQLITE_READONLY",     8   ," Attempt to write a readonly database "};
{"SQLITE_INTERRUPT",    9   ," Operation terminated by sqlite3_interrupt()"};
{"SQLITE_IOERR",       10   ," Some kind of disk I/O error occurred "};
{"SQLITE_CORRUPT",     11   ," The database disk image is malformed "};
{"SQLITE_NOTFOUND",    12   ," Unknown opcode in sqlite3_file_control() "};
{"SQLITE_FULL",        13   ," Insertion failed because database is full "};
{"SQLITE_CANTOPEN",    14   ," Unable to open the database file "};
{"SQLITE_PROTOCOL",    15   ," Database lock protocol error "};
{"SQLITE_EMPTY",       16   ," Database is empty "};
{"SQLITE_SCHEMA",      17   ," The database schema changed "};
{"SQLITE_TOOBIG",      18   ," String or BLOB exceeds size limit "};
{"SQLITE_CONSTRAINT",  19   ," Abort due to constraint violation "};
{"SQLITE_MISMATCH",    20   ," Data type mismatch "};
{"SQLITE_MISUSE",      21   ," Library used incorrectly "};
{"SQLITE_NOLFS",       22   ," Uses OS features not supported on host "};
{"SQLITE_AUTH",        23   ," Authorization denied "};
{"SQLITE_FORMAT",      24   ," Auxiliary database format error "};
{"SQLITE_RANGE",       25   ," 2nd parameter to sqlite3_bind out of range "};
{"SQLITE_NOTADB",      26   ," File opened that is not a database file "};
{"SQLITE_ROW",         100  ," sqlite3_step() has another row ready "};
{"SQLITE_DONE",        101  ," sqlite3_step() has finished executing "};
};

local sqlitecodes = {
{"SQLITE_IOERR_READ",              bor(SQLITE_IOERR , lshift(1,8))};
{"SQLITE_IOERR_SHORT_READ",        bor(SQLITE_IOERR , lshift(2,8))};
{"SQLITE_IOERR_WRITE",             bor(SQLITE_IOERR , lshift(3,8))};
{"SQLITE_IOERR_FSYNC",             bor(SQLITE_IOERR , lshift(4,8))};
{"SQLITE_IOERR_DIR_FSYNC",         bor(SQLITE_IOERR , lshift(5,8))};
{"SQLITE_IOERR_TRUNCATE",          bor(SQLITE_IOERR , lshift(6,8))};
{"SQLITE_IOERR_FSTAT",             bor(SQLITE_IOERR , lshift(7,8))};
{"SQLITE_IOERR_UNLOCK",            bor(SQLITE_IOERR , lshift(8,8))};
{"SQLITE_IOERR_RDLOCK",            bor(SQLITE_IOERR , lshift(9,8))};
{"SQLITE_IOERR_DELETE",            bor(SQLITE_IOERR , lshift(10,8))};
{"SQLITE_IOERR_BLOCKED",           bor(SQLITE_IOERR , lshift(11,8))};
{"SQLITE_IOERR_NOMEM",             bor(SQLITE_IOERR , lshift(12,8))};
{"SQLITE_IOERR_ACCESS",            bor(SQLITE_IOERR , lshift(13,8))};
{"SQLITE_IOERR_CHECKRESERVEDLOCK", bor(SQLITE_IOERR , lshift(14,8))};
{"SQLITE_IOERR_LOCK",              bor(SQLITE_IOERR , lshift(15,8))};
{"SQLITE_IOERR_CLOSE",             bor(SQLITE_IOERR , lshift(16,8))};
{"SQLITE_IOERR_DIR_CLOSE",         bor(SQLITE_IOERR , lshift(17,8))};
{"SQLITE_IOERR_SHMOPEN",           bor(SQLITE_IOERR , lshift(18,8))};
{"SQLITE_IOERR_SHMSIZE",           bor(SQLITE_IOERR , lshift(19,8))};
{"SQLITE_IOERR_SHMLOCK",           bor(SQLITE_IOERR , lshift(20,8))};
{"SQLITE_IOERR_SHMMAP",            bor(SQLITE_IOERR , lshift(21,8))};
{"SQLITE_IOERR_SEEK",              bor(SQLITE_IOERR , lshift(22,8))};
{"SQLITE_LOCKED_SHAREDCACHE",      bor(SQLITE_LOCKED ,  lshift(1,8))};
{"SQLITE_BUSY_RECOVERY",           bor(SQLITE_BUSY   ,  lshift(1,8))};
{"SQLITE_CANTOPEN_NOTEMPDIR",      bor(SQLITE_CANTOPEN , lshift(1,8))};
{"SQLITE_CANTOPEN_ISDIR",          bor(SQLITE_CANTOPEN , lshift(2,8))};
{"SQLITE_CORRUPT_VTAB",            bor(SQLITE_CORRUPT , lshift(1,8))};
{"SQLITE_READONLY_RECOVERY",       bor(SQLITE_READONLY , lshift(1,8))};
{"SQLITE_READONLY_CANTLOCK",       bor(SQLITE_READONLY , lshift(2,8))};
{"SQLITE_ABORT_ROLLBACK",          bor(SQLITE_ABORT , lshift(2,8))};




{"SQLITE_OPEN_READONLY",         0x00000001  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_READWRITE",        0x00000002  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_CREATE",           0x00000004  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_DELETEONCLOSE",    0x00000008  ," VFS only "};
{"SQLITE_OPEN_EXCLUSIVE",        0x00000010  ," VFS only "};
{"SQLITE_OPEN_AUTOPROXY",        0x00000020  ," VFS only "};
{"SQLITE_OPEN_URI",              0x00000040  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_MAIN_DB",          0x00000100  ," VFS only "};
{"SQLITE_OPEN_TEMP_DB",          0x00000200  ," VFS only "};
{"SQLITE_OPEN_TRANSIENT_DB",     0x00000400  ," VFS only "};
{"SQLITE_OPEN_MAIN_JOURNAL",     0x00000800  ," VFS only "};
{"SQLITE_OPEN_TEMP_JOURNAL",     0x00001000  ," VFS only "};
{"SQLITE_OPEN_SUBJOURNAL",       0x00002000  ," VFS only "};
{"SQLITE_OPEN_MASTER_JOURNAL",   0x00004000  ," VFS only "};
{"SQLITE_OPEN_NOMUTEX",          0x00008000  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_FULLMUTEX",        0x00010000  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_SHAREDCACHE",      0x00020000  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_PRIVATECACHE",     0x00040000  ," Ok for sqlite3_open_v2() "};
{"SQLITE_OPEN_WAL",              0x00080000  ," VFS only "};

-- Reserved:                         0x00F00000

{"SQLITE_IOCAP_ATOMIC",                 0x00000001};
{"SQLITE_IOCAP_ATOMIC512",              0x00000002};
{"SQLITE_IOCAP_ATOMIC1K",               0x00000004};
{"SQLITE_IOCAP_ATOMIC2K",               0x00000008};
{"SQLITE_IOCAP_ATOMIC4K",               0x00000010};
{"SQLITE_IOCAP_ATOMIC8K",               0x00000020};
{"SQLITE_IOCAP_ATOMIC16K",              0x00000040};
{"SQLITE_IOCAP_ATOMIC32K",              0x00000080};
{"SQLITE_IOCAP_ATOMIC64K",              0x00000100};
{"SQLITE_IOCAP_SAFE_APPEND",            0x00000200};
{"SQLITE_IOCAP_SEQUENTIAL",             0x00000400};
{"SQLITE_IOCAP_UNDELETABLE_WHEN_OPEN",  0x00000800};
{"SQLITE_IOCAP_POWERSAFE_OVERWRITE",    0x00001000};


{"SQLITE_LOCK_NONE",           0};
{"SQLITE_LOCK_SHARED",         1};
{"SQLITE_LOCK_RESERVED",       2};
{"SQLITE_LOCK_PENDING",        3};
{"SQLITE_LOCK_EXCLUSIVE",      4};


{"SQLITE_SYNC_NORMAL",        0x00002};
{"SQLITE_SYNC_FULL",          0x00003};
{"SQLITE_SYNC_DATAONLY",      0x00010};

{"SQLITE_FCNTL_LOCKSTATE",               1};
{"SQLITE_GET_LOCKPROXYFILE",             2};
{"SQLITE_SET_LOCKPROXYFILE",             3};
{"SQLITE_LAST_ERRNO",                    4};
{"SQLITE_FCNTL_SIZE_HINT",               5};
{"SQLITE_FCNTL_CHUNK_SIZE",              6};
{"SQLITE_FCNTL_FILE_POINTER",            7};
{"SQLITE_FCNTL_SYNC_OMITTED",            8};
{"SQLITE_FCNTL_WIN32_AV_RETRY",          9};
{"SQLITE_FCNTL_PERSIST_WAL",            10};
{"SQLITE_FCNTL_OVERWRITE",              11};
{"SQLITE_FCNTL_VFSNAME",                12};
{"SQLITE_FCNTL_POWERSAFE_OVERWRITE",    13};
{"SQLITE_FCNTL_PRAGMA",                 14};

{"SQLITE_ACCESS_EXISTS",     0};
{"SQLITE_ACCESS_READWRITE",  1};
{"SQLITE_ACCESS_READ",       2};

{"SQLITE_SHM_UNLOCK",        1};
{"SQLITE_SHM_LOCK",          2};
{"SQLITE_SHM_SHARED",        4};
{"SQLITE_SHM_EXCLUSIVE",     8};

{"SQLITE_SHM_NLOCK",         8};



{"SQLITE_CONFIG_SINGLETHREAD",   1  ," nil "};
{"SQLITE_CONFIG_MULTITHREAD",    2  ," nil "};
{"SQLITE_CONFIG_SERIALIZED",     3  ," nil "};
{"SQLITE_CONFIG_MALLOC",         4  ," sqlite3_mem_methods* "};
{"SQLITE_CONFIG_GETMALLOC",      5  ," sqlite3_mem_methods* "};
{"SQLITE_CONFIG_SCRATCH",        6  ," void*, int sz, int N "};
{"SQLITE_CONFIG_PAGECACHE",      7  ," void*, int sz, int N "};
{"SQLITE_CONFIG_HEAP",           8  ," void*, int nByte, int min "};
{"SQLITE_CONFIG_MEMSTATUS",      9  ," boolean "};
{"SQLITE_CONFIG_MUTEX",         10  ," sqlite3_mutex_methods* "};
{"SQLITE_CONFIG_GETMUTEX",      11  ," sqlite3_mutex_methods* "};

-- previously SQLITE_CONFIG_CHUNKALLOC 12 which is now unused.

{"SQLITE_CONFIG_LOOKASIDE",     13  ," int int "};
{"SQLITE_CONFIG_PCACHE",        14  ," no-op "};
{"SQLITE_CONFIG_GETPCACHE",     15  ," no-op "};
{"SQLITE_CONFIG_LOG",           16  ," xFunc, void* "};
{"SQLITE_CONFIG_URI",           17  ," int "};
{"SQLITE_CONFIG_PCACHE2",       18  ," sqlite3_pcache_methods2* "};
{"SQLITE_CONFIG_GETPCACHE2",    19  ," sqlite3_pcache_methods2* "};

{"SQLITE_DBCONFIG_LOOKASIDE",        1001  ," void* int int "};
{"SQLITE_DBCONFIG_ENABLE_FKEY",      1002  ," int int* "};
{"SQLITE_DBCONFIG_ENABLE_TRIGGER",   1003  ," int int* "};

{"SQLITE_DENY",    1   ," Abort the SQL statement with an error "};
{"SQLITE_IGNORE",  2   ," Don't allow access, but don't generate an error "};


--[[****************************************** 3rd ************ 4th **********--]]
{"SQLITE_CREATE_INDEX",          1   ," Index Name      Table Name      "};
{"SQLITE_CREATE_TABLE",          2   ," Table Name      NULL            "};
{"SQLITE_CREATE_TEMP_INDEX",     3   ," Index Name      Table Name      "};
{"SQLITE_CREATE_TEMP_TABLE",     4   ," Table Name      NULL            "};
{"SQLITE_CREATE_TEMP_TRIGGER",   5   ," Trigger Name    Table Name      "};
{"SQLITE_CREATE_TEMP_VIEW",      6   ," View Name       NULL            "};
{"SQLITE_CREATE_TRIGGER",        7   ," Trigger Name    Table Name      "};
{"SQLITE_CREATE_VIEW",           8   ," View Name       NULL            "};
{"SQLITE_DELETE",                9   ," Table Name      NULL            "};
{"SQLITE_DROP_INDEX",           10   ," Index Name      Table Name      "};
{"SQLITE_DROP_TABLE",           11   ," Table Name      NULL            "};
{"SQLITE_DROP_TEMP_INDEX",      12   ," Index Name      Table Name      "};
{"SQLITE_DROP_TEMP_TABLE",      13   ," Table Name      NULL            "};
{"SQLITE_DROP_TEMP_TRIGGER",    14   ," Trigger Name    Table Name      "};
{"SQLITE_DROP_TEMP_VIEW",       15   ," View Name       NULL            "};
{"SQLITE_DROP_TRIGGER",         16   ," Trigger Name    Table Name      "};
{"SQLITE_DROP_VIEW",            17   ," View Name       NULL            "};
{"SQLITE_INSERT",               18   ," Table Name      NULL            "};
{"SQLITE_PRAGMA",               19   ," Pragma Name     1st arg or NULL "};
{"SQLITE_READ",                 20   ," Table Name      Column Name     "};
{"SQLITE_SELECT",               21   ," NULL            NULL            "};
{"SQLITE_TRANSACTION",          22   ," Operation       NULL            "};
{"SQLITE_UPDATE",               23   ," Table Name      Column Name     "};
{"SQLITE_ATTACH",               24   ," Filename        NULL            "};
{"SQLITE_DETACH",               25   ," Database Name   NULL            "};
{"SQLITE_ALTER_TABLE",          26   ," Database Name   Table Name      "};
{"SQLITE_REINDEX",              27   ," Index Name      NULL            "};
{"SQLITE_ANALYZE",              28   ," Table Name      NULL            "};
{"SQLITE_CREATE_VTABLE",        29   ," Table Name      Module Name     "};
{"SQLITE_DROP_VTABLE",          30   ," Table Name      Module Name     "};
{"SQLITE_FUNCTION",             31   ," NULL            Function Name   "};
{"SQLITE_SAVEPOINT",            32   ," Operation       Savepoint Name  "};
{"SQLITE_COPY",                  0   ," No longer used "};


{"SQLITE_LIMIT_LENGTH",                    0};
{"SQLITE_LIMIT_SQL_LENGTH",                1};
{"SQLITE_LIMIT_COLUMN",                    2};
{"SQLITE_LIMIT_EXPR_DEPTH",                3};
{"SQLITE_LIMIT_COMPOUND_SELECT",           4};
{"SQLITE_LIMIT_VDBE_OP",                   5};
{"SQLITE_LIMIT_FUNCTION_ARG",              6};
{"SQLITE_LIMIT_ATTACHED",                  7};
{"SQLITE_LIMIT_LIKE_PATTERN_LENGTH",       8};
{"SQLITE_LIMIT_VARIABLE_NUMBER",           9};
{"SQLITE_LIMIT_TRIGGER_DEPTH",            10};


{"SQLITE_INTEGER",  1};
{"SQLITE_FLOAT",    2};
{"SQLITE_BLOB",     4};
{"SQLITE_NULL",     5};
{"SQLITE_TEXT",     3};



{"SQLITE_UTF8",           1};
{"SQLITE_UTF16LE",        2};
{"SQLITE_UTF16BE",        3};
{"SQLITE_UTF16",          4    ," Use native byte order "};
{"SQLITE_ANY",            5    ," sqlite3_create_function only "};
{"SQLITE_UTF16_ALIGNED",  8    ," sqlite3_create_collation only "};


{"SQLITE_INDEX_CONSTRAINT_EQ",    2};
{"SQLITE_INDEX_CONSTRAINT_GT",    4};
{"SQLITE_INDEX_CONSTRAINT_LE",    8};
{"SQLITE_INDEX_CONSTRAINT_LT",    16};
{"SQLITE_INDEX_CONSTRAINT_GE",    32};
{"SQLITE_INDEX_CONSTRAINT_MATCH", 64};


{"SQLITE_MUTEX_FAST",             0};
{"SQLITE_MUTEX_RECURSIVE",        1};
{"SQLITE_MUTEX_STATIC_MASTER",    2};
{"SQLITE_MUTEX_STATIC_MEM",       3  ," sqlite3_malloc() "};
{"SQLITE_MUTEX_STATIC_MEM2",      4  ," NOT USED "};
{"SQLITE_MUTEX_STATIC_OPEN",      4  ," sqlite3BtreeOpen() "};
{"SQLITE_MUTEX_STATIC_PRNG",      5  ," sqlite3_random() "};
{"SQLITE_MUTEX_STATIC_LRU",       6  ," lru page list "};
{"SQLITE_MUTEX_STATIC_LRU2",      7  ," NOT USED "};
{"SQLITE_MUTEX_STATIC_PMEM",      7  ," sqlite3PageMalloc() "};


{"SQLITE_TESTCTRL_FIRST",                    5};
{"SQLITE_TESTCTRL_PRNG_SAVE",                5};
{"SQLITE_TESTCTRL_PRNG_RESTORE",             6};
{"SQLITE_TESTCTRL_PRNG_RESET",               7};
{"SQLITE_TESTCTRL_BITVEC_TEST",              8};
{"SQLITE_TESTCTRL_FAULT_INSTALL",            9};
{"SQLITE_TESTCTRL_BENIGN_MALLOC_HOOKS",     10};
{"SQLITE_TESTCTRL_PENDING_BYTE",            11};
{"SQLITE_TESTCTRL_ASSERT",                  12};
{"SQLITE_TESTCTRL_ALWAYS",                  13};
{"SQLITE_TESTCTRL_RESERVE",                 14};
{"SQLITE_TESTCTRL_OPTIMIZATIONS",           15};
{"SQLITE_TESTCTRL_ISKEYWORD",               16};
{"SQLITE_TESTCTRL_SCRATCHMALLOC",           17};
{"SQLITE_TESTCTRL_LOCALTIME_FAULT",         18};
{"SQLITE_TESTCTRL_EXPLAIN_STMT",            19};
{"SQLITE_TESTCTRL_LAST",                    19};

{"SQLITE_STATUS_MEMORY_USED",          0};
{"SQLITE_STATUS_PAGECACHE_USED",       1};
{"SQLITE_STATUS_PAGECACHE_OVERFLOW",   2};
{"SQLITE_STATUS_SCRATCH_USED",         3};
{"SQLITE_STATUS_SCRATCH_OVERFLOW",     4};
{"SQLITE_STATUS_MALLOC_SIZE",          5};
{"SQLITE_STATUS_PARSER_STACK",         6};
{"SQLITE_STATUS_PAGECACHE_SIZE",       7};
{"SQLITE_STATUS_SCRATCH_SIZE",         8};
{"SQLITE_STATUS_MALLOC_COUNT",         9};

{"SQLITE_DBSTATUS_LOOKASIDE_USED",       0};
{"SQLITE_DBSTATUS_CACHE_USED",           1};
{"SQLITE_DBSTATUS_SCHEMA_USED",          2};
{"SQLITE_DBSTATUS_STMT_USED",            3};
{"SQLITE_DBSTATUS_LOOKASIDE_HIT",        4};
{"SQLITE_DBSTATUS_LOOKASIDE_MISS_SIZE",  5};
{"SQLITE_DBSTATUS_LOOKASIDE_MISS_FULL",  6};
{"SQLITE_DBSTATUS_CACHE_HIT",            7};
{"SQLITE_DBSTATUS_CACHE_MISS",           8};
{"SQLITE_DBSTATUS_CACHE_WRITE",          9};
{"SQLITE_DBSTATUS_MAX",                  9   ," Largest defined DBSTATUS "};

{"SQLITE_STMTSTATUS_FULLSCAN_STEP",     1};
{"SQLITE_STMTSTATUS_SORT",              2};
{"SQLITE_STMTSTATUS_AUTOINDEX",         3};


{"SQLITE_CHECKPOINT_PASSIVE", 0};
{"SQLITE_CHECKPOINT_FULL",    1},
{"SQLITE_CHECKPOINT_RESTART", 2},

{"SQLITE_VTAB_CONSTRAINT_SUPPORT", 1},

{"SQLITE_ROLLBACK", 1};
{"SQLITE_FAIL",     3};
{"SQLITE_REPLACE",  5};

{"SQLITE_IGNORE", 2, "Also used by sqlite3_authorizer() callback "};
{"SQLITE_ABORT", 4,  "Also an error code "};


{"SQLITE_STATIC", 0};
{"SQLITE_TRANSIENT",-1};
}


return {
    sqliteerrorcodes = sqliteerrorcodes;
    sqlitecodes = sqlitecodes;
};