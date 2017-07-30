
local __ = {
    _cls_ = '',
}

function __:start() end
 
function __:getId() end

function __:setId(id) end
 
function __:invalidate(lifetime) end

function __:migrate(destroy) end

function __:save() end

function __:has(name) end

function __:get(name, default) end

function __:set(name, value) end

function __:all() end

function __:replace(attrs) end

function __:remove(name) end

function __:isStarted() end

function __:regItem(item) end

function __:getItem(name) end

function __:getMetaItem() end
 
return __

