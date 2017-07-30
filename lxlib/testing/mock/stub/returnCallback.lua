
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.stub'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        callback = nil
    }
    
    return oo(this, mt)
end

function _M:ctor(callback)

    self.callback = callback
end

function _M:invoke(invocation)

    return lf.call(self.callback, unpack(invocation.parameters))
end

function _M:toStr()

    local type
    local class

    if lf.isTbl(self.callback) then
        if lf.isObj(self.callback[1]) then
            class = self.callback[1].__cls
            type = ':'
         else 
            class = self.callback[2]
            type = '.'
        end
        
        return fmt('return result of user defined callback %s%s%s() with the ' .. 'passed arguments', class, type, self.callback[2])
    else 
        
        return 'return result of user defined callback ' .. tostring(self.callback) .. ' with the passed arguments'
    end
end

return _M

