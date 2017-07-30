
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'authGateBond',
    _mix_   = 'handleAuthorization'
}

local app, lf, tb, str = lx.kit()
local try = lx.try

function _M:new(userResolver, abilities, policies, beforeCallbacks, afterCallbacks)

    local this = {
        userResolver = userResolver,
        abilities = abilities or {},
        policies = policies or {},
        beforeCallbacks = beforeCallbacks or {},
        afterCallbacks = afterCallbacks or {}
    }
end

function _M:has(ability)

    return self.abilities[ability]
end

function _M:define(ability, callback)

    if lf.isFunc(callback) then
        self.abilities[ability] = callback
    elseif lf.isStr(callback) and str.contains(callback, '@') then
        self.abilities[ability] = self:buildAbilityCallback(callback)
    else 
        lx.throw('invalidArgumentException', "Callback must be a callable or a 'Class@method' string.")
    end
    
    return self
end

function _M.__:buildAbilityCallback(callback)

    return function(...)
        local class, method = str.parseCallback(callback)
        local obj = self:resolvePolicy(class)
        method = obj[method]

        return method(obj, ...)
    end
end

function _M:policy(class, policy)

    self.policies[class] = policy
    
    return self
end

function _M:before(callback)

    tapd(self.beforeCallbacks, callback)
    
    return self
end

function _M:after(callback)

    tapd(self.afterCallbacks, callback)
    
    return self
end

function _M:allows(ability, arguments)

    arguments = arguments or {}
    
    return self:check(ability, arguments)
end

function _M:denies(ability, arguments)

    arguments = arguments or {}
    
    return not self:allows(ability, arguments)
end

function _M:check(ability, arguments)

    arguments = arguments or {}
    local ok, ret = try(function()
        
        return self:raw(ability, arguments)
    end)
    :catch('authorizationException', function(e) 
        
        return false
    end)
    :run()

    if ok then return ret end

end

function _M:authorize(ability, arguments)

    arguments = arguments or {}
    local result = self:raw(ability, arguments)
    if result:__is('authAccessResponse') then
        
        return result
    end
    
    return result and self:allow() or self:deny()
end

function _M.__:raw(ability, arguments)

    arguments = arguments or {}
    local user = self:resolveUser()
    if not user then
        
        return false
    end
    arguments = tb.wrap(arguments)
    
    local result = self:callBeforeCallbacks(user, ability, arguments)
    if not result then
        result = self:callAuthCallback(user, ability, arguments)
    end
    
    self:callAfterCallbacks(user, ability, arguments, result)
    
    return result
end

function _M.__:callAuthCallback(user, ability, arguments)

    local callback = self:resolveAuthCallback(user, ability, arguments)
    
    return callback(user, unpack(arguments))
end

function _M.__:callBeforeCallbacks(user, ability, arguments)

    local result

    arguments = tb.merge({user, ability}, {arguments})
    for _, before in pairs(self.beforeCallbacks) do
        result = before(unpack(arguments))
        if result then
            
            return result
        end
    end
end

function _M.__:callAfterCallbacks(user, ability, arguments, result)

    arguments = tb.merge({user, ability, result}, {arguments})
    for _, after in pairs(self.afterCallbacks) do
        after(unpack(arguments))
    end
end

function _M.__:resolveAuthCallback(user, ability, arguments)

    local policy
    if arguments[1] then
        policy = self:getPolicyFor(arguments[1])
        if policy then
            
            return self:resolvePolicyCallback(user, ability, arguments, policy)
        end
    end
    if self.abilities[ability] then
        
        return self.abilities[ability]
    else 
        
        return function()
            
            return false
        end
    end
end

function _M:getPolicyFor(class)

    if lf.isObj(class) then
        class = class.__cls
    end
    if self.policies[class] then
        
        return self:resolvePolicy(self.policies[class])
    end
    for expected, policy in pairs(self.policies) do
        if lf.isSubClsOf(class, expected) then
            
            return self:resolvePolicy(policy)
        end
    end
end

function _M:resolvePolicy(class)

    return self.container:make(class)
end

function _M.__:resolvePolicyCallback(user, ability, arguments, policy)

    return function()
        
        result = self:callPolicyBefore(policy, user, ability, arguments)
        
        if result then
            
            return result
        end
        ability = self:formatAbilityToMethod(ability)
        
        if arguments[1] and lf.isStr(arguments[1]) then
            tb.shift(arguments)
        end
        
        local fn = policy[ability]
        if lf.isFun(fn) then
            return fn(policy, user, unpack(arguments))
        end

        return false
    end
end

function _M.__:callPolicyBefore(policy, user, ability, arguments)

    if policy:__has('before') then
        
        return policy:before(user, ability, arguments)
    end
end

function _M.__:formatAbilityToMethod(ability)

    return str.strpos(ability, '-') and str.camel(ability) or ability
end

function _M:forUser(user)

    local callback = function()
        
        return user
    end
    
    return self:__new(self.container, callback, self.abilities, self.policies, self.beforeCallbacks, self.afterCallbacks)
end

function _M.__:resolveUser()

    return lf.call(self.userResolver)
end

return _M

