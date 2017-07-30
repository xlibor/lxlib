
local _M = {
    _cls_ = ''
}

local lx = require('lxlib')
local lf, str = lx.f, lx.str

local function addMethodToBond(bond, data)

    if #data > 0 then
        for _, v in ipairs(data) do
            if not str.startsWith(v, '_') then
                bond[v] = v
            end
        end
    elseif next(data) then
        for k, v in pairs(data) do
            if not str.startsWith(k, '_') then
                bond[k] = k
            end
        end
    end

end

function _M.getBondMethods(app, key, bond)
    
    local t
    local bondPath, bondKey
    local argType = type(bond)
    local defs = {}

    bondKey = key

    if argType == 'table' then
        return bond, key
    elseif argType == 'string' then
        bondPath = bond
    elseif argType == 'nil' then
        bondPath = key
    end

    if bondPath then
 
        bond = lf.import(bondPath)

        local bondCls, extInfo = bond.__cls, bond._ext_

        if not bondCls then
            error('no bond cls in ' .. bondPath)
        end
 
        addMethodToBond(defs, bond)
 
        local appends
        if extInfo then
            if type(extInfo) == 'string' then
                extInfo = {extInfo}
            end
            if not type(extInfo) == 'table' then
                error('invalid super bond def')
            end
            for _, superBond in ipairs(extInfo) do
                t = app:getBond(superBond)
                if not t then
                    error('bond [' .. superBond .. '] invalid')
                end
                appends = t
                app.bondParents[bondKey] = superBond
            end
        end

        if appends then
            addMethodToBond(defs, appends)
        end

        return defs, bondKey
    end
end

function _M.setBond(app, key, bond)

    local bondMethods, bondName = _M.getBondMethods(app, key, bond)

    app.bonds[bondName] = bondMethods
end

return _M

