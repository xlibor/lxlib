
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'shift'
}

local app, lf, tb, str = lx.kit()

function _M:up(schema)

    schema:create('DummyTable', function(table)
        table:incr('id')
        table:timestamps()
    end)
end

function _M:down(schema)
    
    schema:drop('DummyTable')
end

return _M

