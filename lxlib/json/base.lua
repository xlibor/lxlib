
local _M = {
    _cls_ = '',
    orderable = true
}

local json = require('lxlib.resty.dkjson')
local jsonSafe = json

function _M.useCjson()

    json = require('cjson')
    jsonSafe = require('cjson.safe')
    _M.orderable = false

end

function _M.useNew(newJson, newJsonSafe)

    json = newJson
    jsonSafe = newJsonSafe
end

function _M.encode(obj, state)

    if not obj then return '' end
    
    if obj.__cls == 'col' then
        local ifKeyorder 
        if state then
            if state.keyorder then ifKeyorder = true end
        end
        return obj:toJson(ifKeyorder)
    elseif obj.toJson then
        return obj:toJson()
    elseif obj.toTbl then
        return obj:toArr()
    else
        if _M.orderable then
            return json.encode(obj, state)
        else
            return json.encode(obj)
        end
    end
end

function _M.decode(str)

    return json.decode(str)
end

function _M.safeEncode(obj)

    if obj.__cls == 'col' then
        return obj:toJson()
    else
        return jsonSafe.encode(obj, state)
    end
end

function _M.safeDecode(str)

    return jsonSafe.decode(str)
end

return _M

