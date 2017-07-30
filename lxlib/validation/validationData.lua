
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M.initAndGatherData(attr, masterData)

    local data = tb.dot(_M.initAttrOnData(attr, masterData))
    
    return tb.merge(data, _M.extractValuesForWildcards(masterData, data, attr))
end

function _M.__.initAttrOnData(attr, masterData)

    local explicitPath = _M.getLeadingExplicitAttrPath(attr)
    local data = _M.extractDataFromPath(explicitPath, masterData)
    if not sinfd(attr, '%*') or str.endsWith(attr, '*') then
        
        return data
    end
    
    return data_set(data, attr, nil, true)
end

function _M.__.extractValuesForWildcards(masterData, data, attr)

    local keys = {}
    local pattern = str.replace(str.pregQuote(attr), '\\*', '[^\\.]+')
    for key, value in pairs(data) do
        if str.rematch(key, pattern, matches) then
            tapd(keys, matches[1])
        end
    end
    keys = tb.unique(keys)
    data = {}
    for _, key in pairs(keys) do
        data[key] = tb.get(masterData, key)
    end
    
    return data
end

function _M.extractDataFromPath(attr, masterData)

    local results = {}
    local value = tb.get(masterData, attr, '__missing__')
    if value ~= '__missing__' then
        tb.set(results, attr, value)
    end
    
    return results
end

function _M.getLeadingExplicitAttrPath(attr)

    return str.rtrim(str.split(attr, '*')[1], '.')
end

return _M

