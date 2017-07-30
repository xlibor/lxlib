
local __ = {
    _cls_ = '',
}

function __:close() end
 
function __:destroy(sessionId) end

function __:gc(lifetime) end

function __:open(savePath, sesssionName) end

function __:read(sessionId) end

function __:write(sessionId, data) end

return __

