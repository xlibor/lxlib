
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

local sgsub = string.gsub

function _M:new(namespace, prefix, isLibCmd, viaApp)

    local this = {
        commands = {},
        commandAliases = {},
        namespace = namespace,
        prefix = prefix,
        isLibCmd = isLibCmd,
        viaApp = viaApp
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

end

function _M:group(groupInfo, cb)

    local vt = type(groupInfo)
    if vt == 'string' then
        groupInfo = {ns = groupInfo}
    end
    self.namespace = groupInfo.namespace or groupInfo.ns
    self.prefix = groupInfo.prefix or groupInfo.pre
    self.isLibCmd = groupInfo.isLibCmd or groupInfo.lib 
    self.viaApp = groupInfo.viaApp or groupInfo.app
    cb()

    self.prefix = ''
    self.isLibCmd = false
    self.namespace = ''
    self.viaApp = false
end

local function regexReplace(s, vars)

    if #vars > 0 then
        local t
        s = sgsub(s, '([%$%#])(%d+)', function(sign, index)
            index = tonumber(index)
            t = vars[index]
            if sign == '#' then
                t = str.ucfirst(t)
            end

            return t
        end)
    end

    return s
end

function _M:add(uri, command)

    local namespace, prefix, isLibCmd, viaApp =
        self.namespace, self.prefix, self.isLibCmd, self.viaApp

    local alias

    if str.has(uri, '|') then
        uri, alias = str.div(uri, '|')
    end

    local varList = {}
    if str.has(uri, '{') then
        local regex = sgsub(uri, "%{([A-Za-z0-9_]+)%}", function(m)
            
            tapd(varList, m)
            return m
        end)
        uri = regex
    end

    local cmd, action
    local vt = type(command)
    if vt == 'string' then
        if str.has(command, '@') then
            cmd, action = str.div(command, '@')
        else
            cmd = command
        end
    elseif vt == 'function' then
        cmd = command
    elseif vt == 'table' then
        cmd, action, alias = command.use, command.by, command.as
    end
     
    cmd = regexReplace(cmd, varList)
    if action then
        action = regexReplace(action, varList)
    end
    if alias then
        alias = regexReplace(alias, varList)
        self.commandAliases[alias] = uri
    end

    if prefix and str.len(prefix) > 0 then
        uri = prefix .. '/' .. uri
    end
 
    if type(cmd) == 'string' then
        cmd = namespace .. '.' .. cmd
    end

    self.commands[uri] = {cmd = cmd, action = action,
        isLibCmd = isLibCmd, alias = alias, viaApp = viaApp}

end

function _M:filterSign(cmd, method, input)

    local args = input.args
    local sign = cmd.sign
     
    if not sign then return true end
    local argsDef = sign[method]
    if not argsDef then return true end
     
    local t, argExists

    for varName, v in pairs(argsDef) do
        local short, opt, value = v.short, v.opt, v.value
        local index = v.index
        t = args[varName]

        if not lf.isNil(t) then
            argExists = true
        else
            if short then
                t = args[short]
                if not lf.isNil(t) then
                    args[varName] = args[short]
                    argExists = true
                else
                    argExists = false
                end
            else
                argExists = false
            end
        end

        if not argExists and index then
            t = args[index]
            if not lf.isNil(t) then
                args[varName] = t
                argExists = true
            end
        end

        if not argExists then
            if opt then
                if value then
                    args[varName] = value
                end
            else
                return false, ('var:'..varName..' is not optional ')
            end
        end
    end
     
    return true
end

function _M:handle(cmd, input, output)

    if cmd then
        method = cmd.action or 'index'
        cmd = cmd.cmd
        local vt = type(cmd)
        if vt == 'string' then
            app:bind(cmd)
            local command = app:make(cmd, input, output)
            app:instance('app.command', command)
            local action = command[method]
            if action then
                local ok, err = self:filterSign(command, method, input)
                if not ok then
                    if err then warn(err) end
                end
                action(command)
            else
                warn('method:'..method..' no exists')
            end
        elseif vt == 'function' then
            cmd(input, output)
        else
            warn('invalid cmd type:', vt)
        end
    end

end

function _M:match(input)

    local commands = self.commands
    local uri = input.uri

    local cmd = commands[uri]
    if not cmd then
        local byAlias = self.commandAliases[uri]
        if byAlias then
            cmd = commands[byAlias]
        end
    end

    return cmd
end

return _M

