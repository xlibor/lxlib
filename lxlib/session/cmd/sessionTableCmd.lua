
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs

function _M:make()

    local table = app:conf('session.drivers.db.table')
    local creator = new 'shift.creator'
    local name = 'create_' .. table .. '_table'
    local path = creator:create(name)
    local stubPath = lx.getPath(true) .. '/stub/db.lua'
    local stub = fs.get(stubPath)
    stub = str.replace(stub, 'DummyTable', table)
    fs.put(path, stub)

    self:info('shift for sessions created successfully!')
end

return _M

