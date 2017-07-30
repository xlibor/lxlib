
local __ = {
    _cls_ = ''
}

function __:table(table) end

function __:raw(value) end

function __:selectOne(query, bindings) end

function __:select(query, bindings) end

function __:insert(query, bindings) end

function __:update(query, bindings) end

function __:delete(query, bindings) end

function __:exec(query, bindings) end

function __:execRows(query, bindings) end

function __:prepareBind(bindings) end

function __:trans(callback) end

function __:beginTrans() end

function __:commit() end

function __:rollback() end

function __:transLevel() end

function __:pretend(callback) end

return __

