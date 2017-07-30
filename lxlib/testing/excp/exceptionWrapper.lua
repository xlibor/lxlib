
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.exception'
}

local app, lf, tb, str = lx.kit()

-- @param exception e

function _M:ctor(e)

    self.__skip = true

    self:__super(_M, 'ctor', e:getMsg(), e:getCode())
    self.classname = e.__cls
    self.file = e:getFile()
    self.line = e:getLine()

    if e:getPrevious() then
        self.previous = new('self', e:getPrevious())
    end
end

-- @return string

function _M:getClassname()

    return self.classname
end

-- @return PHPUnit_Framework_ExceptionWrapper

function _M:getPreviousWrapped()

    return self.previous
end

-- @return string

function _M:toStr()

    local string = PHPUnit_Framework_TestFailure.exceptionToString(self)
    local trace = PHPUnit_Util_Filter.getFilteredStacktrace(self)
    if trace then
        string = string .. "\n" .. trace
    end
    if self.previous then
        string = string .. "\nCaused by\n" .. self.previous
    end
    
    return string
end

return _M

