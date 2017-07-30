
local _M = {
    _cls_ = ''    
}

function _M.trySet(shdict, key, value, ttl)

    local ok, err = shdict:safe_set(key, value, ttl)
    if not ok then
        if err == "no memory" then
            ok, err = shdict:set(key, value, ttl)
        end

        if not ok then
            return false
        end
    end

    return true
end

function _M.tryGet(shdict, key)

    local res, flags, stale = shdict:get_stale(key)

    return res, stale
end

return _M

