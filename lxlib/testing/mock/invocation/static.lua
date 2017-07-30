
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = {'unit.mock.invocation', 'strable'}
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        className = nil,
        methodName = nil,
        parameters = nil,
        returnType = nil,
        returnTypeNullable = false
    }
    
    return oo(this, mt)
end

-- @param string className
-- @param string methodName
-- @param table  parameters
-- @param string returnType
-- @param bool   cloneObjects

function _M:ctor(className, methodName, parameters, returnType, cloneObjects)

    cloneObjects = cloneObjects or false
    self.className = className
    self.methodName = methodName
    self.parameters = parameters
    if str.find(returnType, '%?') == 1 then
        returnType = str.sub(returnType, 2)
        self.returnTypeNullable = true
    end
    self.returnType = returnType
    if not cloneObjects then
        
        return
    end
    for key, value in pairs(self.parameters) do
        if lf.isObj(value) then
            self.parameters[key] = self:cloneObject(value)
        end
    end
end

-- @return string

function _M:toStr()

    local exporter = new('unit.exporter')
    
    return fmt(
        '%s.%s(%s)%s', self.className, self.methodName,
        str.join(tb.map(
                self.parameters, {exporter, 'shortenedExport'}
            ), ', '
        ), self.returnType and fmt(': %s', self.returnType) or ''
    )
end

-- @return mixed Mocked return value.

function _M:generateReturnValue()

    local st = self.returnType
    if lf.isStr(st) and str.len(st) == 0 then
        
        return
    elseif st == 'string' then
        
        return self.returnTypeNullable and nil or ''
    elseif st == 'float' then
        
        return self.returnTypeNullable and nil or 0.0
    elseif st == 'int' then
        
        return self.returnTypeNullable and nil or 0
    elseif st == 'bool' then
        
        return self.returnTypeNullable and nil or false
    elseif st == 'array' then
        
        return self.returnTypeNullable and nil or {}
    elseif st == 'void' then
        
        return
    elseif st == 'function' then
        
        return function()
        end
    elseif st == 'eachable' then

    else 
        if self.returnTypeNullable then
            
            return nil
        end
        generator = new('unit.mock.generator')

        return generator:getMock(self.returnType, {}, {}, '', false)
    end
end

-- @param object original
-- @return object

function _M.__:cloneObject(original)

    local method
    local cloneable = false
    local object
 
    if cloneable then
        try(function()
            
            object = original:__clone()
        end)
        :catch(function(e) 
            
            object = original
        end)
        :run()
    else 
        object = original
    end

    return object
end

return _M

