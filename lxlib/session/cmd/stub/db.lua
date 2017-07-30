
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'shift'
}

local app, lf, tb, str = lx.kit()

function _M:up(schema)

    schema:create('DummyTable', function(table)

        table:string('id'):unique()
        table:integer('user_id'):nullable()
        table:string('ip_address', 45):nullable()
        table:text('user_agent'):nullable()
        table:text('payload')
        table:integer('last_activity')

    end)
end

function _M:down(schema)

    schema:drop('DummyTable')
end

return _M

