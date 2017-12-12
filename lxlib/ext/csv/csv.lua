
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

local Csv = require('ftcsv')

function _M:new()

    local this = {
        options = {}
    }

    return oo(this, mt)
end

function _M:parse()

end

function _M:parseFile(csvPath, options, delimiter)

    delimiter = delimiter or ','
    options = options or {}
    options.loadFromString = false

    local csv, headers = Csv.parse(csvPath, delimiter, options)

    return csv, headers
end

function _M:parseStr(csvStr, options, delimiter)

    delimiter = delimiter or ','
    options = options or {}
    options.loadFromString = true

    local csv, headers = Csv.parse(csvPath, delimiter, options)

    return csv, headers
end

return _M

