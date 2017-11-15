
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'migration'
}

local app, lf, tb, str = lx.kit()

-- Run the migrations.

function _M:up()

    Schema.create(Models.table('threads'), function(table)
        table:increments('id')
        table:string('subject')
        table:timestamps()
        table:softDeletes()
    end)
end

-- Reverse the migrations.

function _M:down()

    Schema.dropIfExists(Models.table('threads'))
end

return _M

