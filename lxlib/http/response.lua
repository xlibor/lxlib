 
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'lxlib.http.base.response',
    _mix_   = 'responseMix'
}

local app, lf, tb, str = lx.kit() 

function _M:setOriginal(original)

    self.original = original
end

function _M:setContent(content)

    local vt = type(content)

    if vt == 'table' then
        local shouldBeJson = false
        if lf.isObj(content) then
            if content:__is('renderable') then
                content = content:render()
            else
                shouldBeJson = content:__is('jsonable')
            end
        else
            shouldBeJson = true
        end

        if shouldBeJson then
            content = lf.jsen(content)
            self:header('Content-Type', 'application/json')
        end
    end

    self:__super('setContent', content)
end

function _M:morphToJson(content)

    if lf.isObj(content) then
        if content:__is('jsonable') then
            return content:toJson()
        end
    else
        return lf.jsen(content)
    end
end

return _M

