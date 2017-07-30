
local _M = {
    _cls_ = ''
}

local lf = require('lxlib.base.pub')

local basePath = 'lxlib.db.grammar.'

local loadGrammar = function(self, key)

    return function(...)
        
        return lf.import(basePath..key):new(...)
    end 
end

setmetatable(_M, {__index = loadGrammar})

return _M

