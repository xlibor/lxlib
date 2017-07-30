
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        cache = {},
        templates = {},
        legacyBlacklistedMethodNames = {},
        blacklistedMethodNames = {}
    }
    
    return oo(this, mt)
end

-- Returns a mock object for the specified class.
-- @param table|string type
-- @param table             methods
-- @param table             arguments
-- @param string            mockClassName
-- @param bool|null         callOriginalConstructor
-- @param bool|null         callOriginalClone
-- @param bool|null         callAutoload
-- @param bool|null         cloneArguments
-- @param bool|null         callOriginalMethods
-- @param object|null       proxyTarget
-- @param bool|null         allowMockingUnknownTypes
-- @return unit.mock.mockObject

function _M:getMock(type, methods, arguments, mockClassName, callOriginalConstructor, callOriginalClone, callAutoload, cloneArguments, callOriginalMethods, proxyTarget, allowMockingUnknownTypes)

    allowMockingUnknownTypes = lf.needTrue(allowMockingUnknownTypes)
    callOriginalMethods = callOriginalMethods or false
    cloneArguments = lf.needTrue(cloneArguments)
    callAutoload = lf.needTrue(callAutoload)
    callOriginalClone = lf.needTrue(callOriginalClone)
    callOriginalConstructor = lf.needTrue(callOriginalConstructor)
    mockClassName = mockClassName or ''
    arguments = arguments or {}
    methods = methods or {}

    if not lf.isTbl(type) and not lf.isStr(type) then
        InvalidArgument(1, 'array or string')
    end
    if not lf.isStr(mockClassName) then
        InvalidArgument(4, 'string')
    end
    if not lf.isTbl(methods) and methods then
        InvalidArgument(2, 'array', methods)
    end
 
    if mockClassName and app:hasClass(mockClassName) then
 
    end
    if callOriginalConstructor == false and callOriginalMethods == true then
        lx.throw('unit.mockException', 'Proxying to original methods requires invoking the original constructor')
    end

    local mock = self:generate(type, methods, mockClassName, callOriginalClone, callAutoload, cloneArguments, callOriginalMethods)

    return self:getObject(mock, type, callOriginalConstructor, callAutoload, arguments, callOriginalMethods, proxyTarget)
end

-- @param table             mock
-- @param table|string      type
-- @param bool              callOriginalConstructor
-- @param bool              callAutoload
-- @param table             arguments
-- @param bool              callOriginalMethods
-- @param object|null       proxyTarget
-- @return object

function _M.__:getObject(mock, type, callOriginalConstructor, callAutoload, arguments, callOriginalMethods, proxyTarget)

    local methods, className = mock.methods, mock.className
    local configurable = mock.configurable

    callOriginalMethods = callOriginalMethods or false
    arguments = arguments or {}
    callAutoload = callAutoload or false
    callOriginalConstructor = callOriginalConstructor or false
    type = type or ''
    local object
 
    object = new('unit.mock.mockedClass', methods, className, configurable)

    if callOriginalMethods then
        if not lf.isObj(proxyTarget) then
            if #arguments == 0 then
                proxyTarget = new(type)
            else
                proxyTarget = new(type, unpack(arguments))
            end
        end
        object:lxunitSetOriginalObject(proxyTarget)
    end
    
    return object
end

-- @param table|string type
-- @param table        methods
-- @param string       mockClassName
-- @param bool         callOriginalClone
-- @param bool         callAutoload
-- @param bool         cloneArguments
-- @param bool         callOriginalMethods
-- @return table

function _M:generate(type, methods, mockClassName, callOriginalClone, callAutoload, cloneArguments, callOriginalMethods)

    callOriginalMethods = callOriginalMethods or false
    cloneArguments = lf.needTrue(cloneArguments)
    callAutoload = lf.needTrue(callAutoload)
    callOriginalClone = lf.needTrue(callOriginalClone)
    mockClassName = mockClassName or ''
    local key
 
    if mockClassName == '' then
        key = lf.md5(type .. tostring(methods) .. tostring(callOriginalClone) .. tostring(cloneArguments) .. tostring(callOriginalMethods))
        if self.cache[key] then
            
            return self.cache[key]
        end
    end
    local mock = self:generateMock(type, methods, mockClassName, callOriginalClone, callAutoload, cloneArguments, callOriginalMethods)
    if key then
        self.cache[key] = mock
    end
    
    return mock
end

-- @param table|string type
-- @param table|null   methods
-- @param string       mockClassName
-- @param bool         callOriginalClone
-- @param bool         callAutoload
-- @param bool         cloneArguments
-- @param bool         callOriginalMethods
-- @return table

function _M.__:generateMock(type, methods, mockClassName, callOriginalClone, callAutoload, cloneArguments, callOriginalMethods)

    local isClass = false
    local isBond = false

    -- mockClassName = self:generateClassName(type, mockClassName, 'mock_')
    local fullClassName = type

    if app:hasClass(fullClassName) then
        isClass = true
     elseif app:hasBond(fullClassName) then
        isBond = true
    end
    if not isClass and not isBond then
        error('none of class or bond:' .. fullClassName)
    end

    if lf.isTbl(methods) and lf.isEmpty(methods) and (isClass or isBond) then
        methods = self:getClassMethods(fullClassName)
    end
    if not lf.isTbl(methods) then
        methods = {}
    end
    
    local configurable = {}
    for _, method in pairs(methods) do
        method = str.lower(method)
        configurable[method] = method
    end

    return {
        methods = methods,
        configurable = configurable,
        className = fullClassName
    }
end

-- @param table|string type
-- @param string       className
-- @param string       prefix
-- @return table

function _M.__:generateClassName(type, className, prefix)

    local fullClassName
    local namespaceName
 
    return {
        className = className,
        originalClassName = type,
        fullClassName = fullClassName,
        namespaceName = namespaceName
    }
end

-- @param table mockClassName
-- @param bool  isBond
-- @param table additionalInterfaces
-- @return table

function _M.__:generateMockClassDeclaration(mockClassName, isBond, additionalInterfaces)

    additionalInterfaces = additionalInterfaces or {}
    local buffer = 'class '
    tapd(additionalInterfaces, 'unit.mock.mockBuilder')
    local interfaces = str.join(additionalInterfaces, ', ')
    if isBond then
        buffer = buffer .. fmt('%s implements %s', mockClassName['className'], interfaces)
        if not tb.inList(additionalInterfaces, mockClassName['originalClassName']) then
            buffer = buffer .. ', '
            if not lf.isEmpty(mockClassName['namespaceName']) then
                buffer = buffer .. mockClassName['namespaceName'] .. '\\'
            end
            buffer = buffer .. mockClassName['originalClassName']
        end
     else 
        buffer = buffer .. fmt('%s extends %s%s implements %s', mockClassName['className'], not lf.isEmpty(mockClassName['namespaceName']) and mockClassName['namespaceName'] .. '\\' or '', mockClassName['originalClassName'], interfaces)
    end
    
    return buffer
end

-- @param string           templateDir
-- @param ReflectionMethod method
-- @param bool             cloneArguments
-- @param bool             callOriginalMethods
-- @return string

function _M.__:generateMockedMethodDefinitionFromExisting(templateDir, method, cloneArguments, callOriginalMethods)

    local deprecation
    local returnType
    local reference
    local modifier
    if method:isPrivate() then
        modifier = 'private'
     elseif method:isProtected() then
        modifier = 'protected'
     else 
        modifier = 'public'
    end
    if method:isStatic() then
        modifier = modifier .. ' static'
    end
    if method:returnsReference() then
        reference = '&'
     else 
        reference = ''
    end
    if self:hasReturnType(method) then
        returnType = tostring(method:getReturnType())
     else 
        returnType = ''
    end
    if str.rematch(method:getDocComment(), '#\\*[ \\t]*+@deprecated[ \\t]*+(.*?)\\r?+\\n[ \\t]*+\\*(?:[ \\t]*+@|/$)#s', deprecation) then
        deprecation = str.trim(str.rereplace(deprecation[1], '#[ \\t]*\\r?\\n[ \\t]*+\\*[ \\t]*+#', ' '))
     else 
        deprecation = false
    end
    
    return self:generateMockedMethodDefinition(templateDir, method:getDeclaringClass():getName(), method:getName(), cloneArguments, modifier, self:getMethodParameters(method), self:getMethodParameters(method, true), returnType, reference, callOriginalMethods, method:isStatic(), deprecation, self:allowsReturnNull(method))
end

-- @param string       templateDir
-- @param string       className
-- @param string       methodName
-- @param bool         cloneArguments
-- @param string       modifier
-- @param string       arguments_decl
-- @param string       arguments_call
-- @param string       return_type
-- @param string       reference
-- @param bool         callOriginalMethods
-- @param bool         static
-- @param string|false deprecation
-- @param bool         allowsReturnNull
-- @return string

function _M.__:generateMockedMethodDefinition(templateDir, className, methodName, cloneArguments, modifier, arguments_decl, arguments_call, return_type, reference, callOriginalMethods, static, deprecation, allowsReturnNull)

    allowsReturnNull = allowsReturnNull or false
    deprecation = deprecation or false
    static = static or false
    callOriginalMethods = callOriginalMethods or false
    reference = reference or ''
    return_type = return_type or ''
    arguments_call = arguments_call or ''
    arguments_decl = arguments_decl or ''
    modifier = modifier or 'public'
    cloneArguments = lf.needTrue(cloneArguments)
    local deprecationTemplate
    local templateFile
    if static then
        templateFile = 'mocked_static_method.tpl'
     else 
        if return_type == 'void' then
            templateFile = fmt('%s_method_void.tpl', callOriginalMethods and 'proxied' or 'mocked')
         else 
            templateFile = fmt('%s_method.tpl', callOriginalMethods and 'proxied' or 'mocked')
        end
    end
    -- Mocked interfaces returning 'self' must explicitly declare the
    -- interface name as the return type. See
    -- https://bugs.php.net/bug.php?id=70722
    if return_type == 'self' then
        return_type = className
    end
    if false ~= deprecation then
        deprecation = "The {className}::{methodName} method is deprecated ({deprecation})."
        deprecationTemplate = self:getTemplate(templateDir .. 'deprecation.tpl')
        deprecationTemplate:setVar({deprecation = var_export(deprecation, true)})
        deprecation = deprecationTemplate:render()
    end
    local template = self:getTemplate(templateDir .. templateFile)
    template:setVar({
        arguments_decl = arguments_decl,
        arguments_call = arguments_call,
        return_delim = return_type and ': ' or '',
        return_type = allowsReturnNull and '?' .. return_type or return_type,
        arguments_count = not lf.isEmpty(arguments_call) and #str.split(arguments_call, ',') or 0,
        class_name = className,
        method_name = methodName,
        modifier = modifier,
        reference = reference,
        clone_arguments = cloneArguments and 'true' or 'false',
        deprecation = deprecation
    })
    
    return template:render()
end

-- @param ReflectionMethod method
-- @return bool

function _M.__:canMockMethod(method)

    if method:isConstructor() or method:isFinal() or method:isPrivate() or self:isMethodNameBlacklisted(method:getName()) then
        
        return false
    end
    
    return true
end

-- Returns whether i method name is blacklisted
-- Since PHP 7 the only names that are still reserved for method names are the ones that start with an underscore
-- @param string name
-- @return bool

function _M.__:isMethodNameBlacklisted(name)

    if PHP_MAJOR_VERSION < 7 and self.legacyBlacklistedMethodNames[name] then
        
        return true
    end
    if PHP_MAJOR_VERSION >= 7 and self.blacklistedMethodNames[name] then
        
        return true
    end
    
    return false
end



-- @param ReflectionParameter parameter
-- @return bool
-- @since  Method available since Release 2.2.1

function _M.__:isVariadic(parameter)

    return ReflectionParameter.class:__has('isVariadic') and parameter:isVariadic()
end

-- @param ReflectionParameter parameter
-- @return bool
-- @since  Method available since Release 2.3.4

function _M.__:hasType(parameter)

    return ReflectionParameter.class:__has('hasType') and parameter:hasType()
end

-- @param ReflectionMethod method
-- @return bool

function _M.__:hasReturnType(method)

    return ReflectionMethod.class:__has('hasReturnType') and method:hasReturnType()
end

-- @param ReflectionMethod method
-- @return bool

function _M.__:allowsReturnNull(method)

    return ReflectionMethod.class:__has('getReturnType') and ReflectionType.class:__has('allowsNull') and method:hasReturnType() and method:getReturnType():allowsNull()
end

-- @param string className
-- @return table
-- @since  Method available since Release 2.3.2

function _M:getClassMethods(className)

    local class = new('class', className)
    local methods = class:getMethods()

    return methods
end

-- @param string filename
-- @return Text_Template
-- @since  Method available since Release 3.2.4

function _M.__:getTemplate(filename)

    if not self.templates[filename] then
        self.templates[filename] = new('text_Template', filename)
    end
    
    return self.templates[filename]
end

return _M

