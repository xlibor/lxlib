
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'shift'
}

local app, lf, tb, str, new = lx.kit()

function _M:up(schema)

    schema:create(app:conf('taggable.tags_table_name'), function(table)
        table:increments('id')
        table:string('slug'):unique()
        table:string('name'):unique()
        table:text('description'):nullable()
        table:integer('suggest'):default(0)
        table:integer('count'):unsigned():default(0)
        table:integer('parent_id'):nullable()
        table:integer('lft'):nullable()
        table:integer('rgt'):nullable()
        table:integer('depth'):nullable()
    end)
    schema:create(app:conf('taggable.taggables_table_name'), function(table)
        table:increments('id')
        if app:conf('taggable.primary_keys_type') == 'string' then
            table:string('taggable_id', 36):index()
        else 
            table:integer('taggable_id'):unsigned():index()
        end
        table:string('taggable_type'):index()
        table:integer('tag_id'):unsigned():index()
        table:foreign('tag_id'):references('id'):on(app:conf('taggable.tags_table_name')):onDelete('cascade')
    end)
end

function _M:down(schema)

    schema:drop(app:conf('taggable.tags_table_name'))
    schema:drop(app:conf('taggable.taggables_table_name'))
end

return _M

