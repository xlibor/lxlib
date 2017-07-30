
local _M = {
    _cls_ = '@sqlSelectLimitField'
}
local mt = { __index = _M }

function _M:new(p1, p2)

    local this = {
        offset = (p1 and p2) and p1 or nil,
        rows = (p1 and p2) and p2 or p1
    }

    setmetatable(this, mt)

    return this
end

function _M:sql(dbType)
    
    local sql
    local offset, rows = self.offset, self.rows
    if offset and rows then
        sql = ' limit ' .. offset .. ',' .. rows
    elseif not offset and rows then
        sql = ' limit ' .. rows
    end

    return sql
end
 
return _M

