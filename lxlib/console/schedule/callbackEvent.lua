
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'event'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        callback = nil,
        parameters = nil
    }
    
    return oo(this, mt)
end

function _M:ctor(callback, parameters)

    parameters = parameters or {}
    if not lf.isStr(callback) and not lf.isCallable(callback) then
        lx.throw('invalidArgumentException', 'Invalid scheduled callback event. Must be string or callable.')
    end
    self.callback = callback
    self.parameters = parameters
end

function _M:run(container)

    if self.description then
        touch(self:mutexPath())
    end
    try(function()
        response = container:call(self.callback, self.parameters)
    end)
    :final(function()
        self:removeMutex()
    end
    :run()
    parent.callAfterCallbacks(container)
    
    return response
end

function _M.__:removeMutex()

    if self.description then
        @unlink(self:mutexPath())
    end
end

function _M:withoutOverlapping()

    if not self.description then
        lx.throw('logicException', "A scheduled event name is required to prevent overlapping. Use the 'name' method before 'withoutOverlapping'.")
    end
    
    return self:skip(function()
        
        return file_exists(self:mutexPath())
    end)
end

function _M.__:mutexPath()

    return storage_path('framework/schedule-' .. lf.sha1(self.description))
end

function _M:getSummaryForDisplay()

    if lf.isStr(self.description) then
        
        return self.description
    end
    
    return lf.isStr(self.callback) and self.callback or 'Closure'
end

return _M

