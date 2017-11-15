
local _M = {
    _cls_ = ''
}

local lf = require('lxlib.base.pub')

local basePath = 'lxlib.db.grammar.'

local loadGrammar = function(self, key)

    return function(...)
        
        return lf.import(basePath .. key):new(...)
    end 
end

function _M.common(dbType)

    local commonGrammar = lf.import(basePath .. 'sqlCommonGrammar'):new(dbType)

    return commonGrammar
end

setmetatable(_M, {__index = loadGrammar})

return _M

