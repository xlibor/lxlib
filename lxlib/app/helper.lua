
local _M = {
    _cls_ = ''
}

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

function _M.kit()

    return _M.redirect, _M.back, _M.abort, _M.route
end

function _M.echo(...)

    echo(...)
end

function _M.csrf_field()

    local ret = '<input type="hidden" name="_token" value="'
        .. _M.csrf_token() .. '">'

    ret = new('htmlStr', ret)

    return ret
end

function _M.csrf_token()

    local session = app:get('session')

    if session then
        local token = session:getToken()
        if not token then
            throw('runtimeException', 'can not get token from session store')
        end
        
        return token
    end

    throw('runtimeException', 'session store not set.')
end

_M.csrfToken = _M.csrf_token

function _M.mix(path)

    local root = app:get('request').root
    local appName = app.name
    local pubDir = app.scaffold.pub

    return root .. '/' .. appName .. '/' .. pubDir .. '/' .. path  
end

function _M.jsen(p)

    return lx.json.encode(p)
end

function _M.jsde(p)

    return lx.json.decode(p)
end

function _M.route(name, parameters, absolute)

    parameters = parameters or {}
    absolute = lf.needTrue(absolute)
    
    return app.url:route(name, parameters, absolute)
end

function _M.url(path, parameters, secure)

    if not path then
        return app.url
    else
        return app.url:to(path, parameters, secure)
    end
end

function _M.config(key, default)

    return app:conf(key) or default
end

function _M.cache(key)

    local cache = app.cache
    if not key then
        return cache
    end

    local vt = type(key)

    if vt == 'string' then
        return cache:get(key)
    end
end

function _M.session(key, default)

    local session = app:get('session')

    if key then
        if lf.isArr(key) then
            session:put(key)
        else
            return session:get(key, default)
        end
    else
        return session
    end
end

function _M.redirect(to, status, headers, secure)

    status = status or 302
    headers = headers or {}
    if not to then
        return app('redirect')
    end

    return app('redirect'):to(to, status, headers, secure)
end

function _M.old(key, default)

    local req = app:get('request')

    return req:old(key, default)
end

function _M.request(key, default)

    local req = app:get('request')

    if not key then
        return req
    end

    local vt = type(key)
    if vt == 'table' then
        return req:only(key)
    end

    return req:input(key, default)
end

function _M:response(content, status, headers)

    local ctx = app:ctx()
    local resp = ctx.resp

    if not (content or status or headers) then
        return resp
    end

    resp:setContent(content)
    if status then
        resp:setStatusCode(status)
    end

    if headers then
        resp:withHeaders(headers)
    end

    return resp
end

function _M.auth(guard)

    local auth = app.auth

    if not guard then
        return auth
    else
        return auth:guard(guard)
    end
end

function _M.trans(id, replace, locale)

    replace = replace or {}
    if not id then
        
        return app('translator')
    end
    
    return app('translator'):trans(id, replace, locale)
end

function _M.e(value)

    local vt = type(value)

    if vt == 'table' then
        local cls = value.__cls
        if cls then
            if value.toStr then
                value = value:toStr()
                return value
            end
        end
    end

    return lf.htmlentities(value)
end

function _M.ucfirst(s)

    return str.ucfirst(s)
end

function _M.abort(code, message, headers)

    headers = headers or {}
    message = message or ''

    if code == 404 then
        throw('notFoundHttpException', message)
    end

    throw('httpException', code, message, nil, headers)
end

function _M.back(status, headers)

    headers = headers or {}
    status = status or 302
    
    return app('redirect'):back(status, headers)
end

function _M.fair(...)

    local fair = new('db.seed.fair')
    local args = {...}
    local p1, p2, p3 = unpack(args)

    p1 = lf.needCls(p1)

    if p2 and lf.isStr(p2) then
        
        return fair:of(p1, p2):times(p3 or 1)
    elseif p2 then
        
        return fair:of(p1):times(p2)
    else 
        
        return fair:of(p1)
    end
end

function _M.flash(message, level)

    level = level or 'info'
    local notifier = app('flash')
    if message then
        
        return notifier:message(message, level)
    end
    
    return notifier
end

function _M.view(tpl, ctx)

    local view = app:make('view')
    
    return view:make(tpl, ctx)
end

function _M.hash(value)

    local hash = app:get('hash')

    return hash:make(value)
end

function _M.validator(data, rules, messages, customAttrs)

    customAttrs = customAttrs or {}
    messages = messages or {}
    rules = rules or {}
    local factory = app('validator')
    if not data then
        
        return factory
    end
    data = data or {}
    
    return factory:make(data, rules, messages, customAttrs)
end

return _M

