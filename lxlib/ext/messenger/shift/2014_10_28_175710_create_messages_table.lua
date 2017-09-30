
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'migration'
}

local app, lf, tb, str = lx.kit()

-- Run the migrations.
-- @return void

function _M:up()

    Schema.create(Models.table('messages'), function(table)
        table:increments('id')
        table:integer('thread_id'):unsigned()
        table:integer('user_id'):unsigned()
        table:text('body')
        table:timestamps()
    end)
end

-- Reverse the migrations.
-- @return void

function _M:down()

    Schema.dropIfExists(Models.table('messages'))
end

return _M

