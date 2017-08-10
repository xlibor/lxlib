
local lx, _M = oo{
    _cls_    = '',
    _ext_    = 'morphSome'
}

local app, lf, tb, str = lx.kit()

function _M:getResults()

    return self.query:first()
end

function _M:initRelation(models, relation)

    for _, model in ipairs(models) do
        model:setRelation(relation, {})
    end

    return models
end

function _M:match(models, results, relation)

    return self:matchOne(models, results, relation)
end

return _M


