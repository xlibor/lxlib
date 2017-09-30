
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'migration'
}

local app, lf, tb, str = lx.kit()

-- Run the migrations.
-- @return void

function _M:up()

    Schema.table(Models.table('messages'), function(table)
        table:softDeletes()
    end)
end

-- Reverse the migrations.
-- @return void

function _M:down()

    Schema.table(Models.table('messages'), function(table)
        table:dropSoftDeletes()
    end)
end

return _M

