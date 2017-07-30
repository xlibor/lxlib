
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'shift'
}

local app, lf, tb, str = lx.kit()

function _M:up(schema)

    schema:table('DummyTable', function(table)

    end)
end

function _M:down(schema)
    
    schema:table('DummyTable', function(table)

    end)
end

return _M

