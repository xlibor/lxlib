
local _M = { _cls_ = '' }
local mt = { __index = _M }
 
local dbDataTypes = {
    bit = 1, byte = 2, tinyint = 3, smallint = 4, mediumint = 5,
    integer = 6, int = 7, bigint = 8, single = 9, decimal = 10,
    double = 11, real = 12, float = 13, currency = 14,
    smallmoney = 15, money = 16, boolean = 17, char = 18,
    unicodechar = 19, varchar = 20, unicodevarchar = 21,
    text = 22, unicodetext = 23, tinyblob = 24, tinytext = 25,
    blob = 26, mediumblob = 27, mediumtext = 28, longblob = 29,
    longtext = 30, guid = 31, hyperlink = 32, memo = 33,
    smalldatetime = 34, date = 35, time = 36, year = 37, datetime = 38,
    timestamp = 39, binary = 40, longbinary = 41, varbinary = 42, image = 43
}

_M.ddt = dbDataTypes

return _M