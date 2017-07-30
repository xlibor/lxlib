
local lx, _M = oo{
    _cls_    = ''
}

local app, lf, tb, str = lx.kit()

local sfind, ssub, sgsub, slen = string.find, string.sub, string.gsub, string.len

function _M:nestArgs()

    local all = self.all
    local args = self.args

    local nest, prev = {}, {}
    local keys, keysCount, vt, vl

    for k, value in pairs(all) do
        if sfind(k, '%[') then
            all[k] = nil
            args:remove(k)
            k = sgsub(k, '%[', ',')
            k = sgsub(k, '%]', '')
            keys = str.split(k, ',')
            keysCount = #keys
            prev = nest
            for i, key in ipairs(keys) do
                vl = slen(key)
                if vl > 0 then
                    if str.allNum(key) then
                        key = tonumber(key)
                    end

                    if i < keysCount then
                        tb.set(prev, key, prev[key] or {})
                        prev = prev[key]
                    else
                        tb.set(prev, key, value)
                    end
                else
                    if i < keysCount then
                        tapd(prev, v)
                    else
                        tb.mergeTo(prev, lf.needList(value))
                    end
                end
            end
        end
    end

    for k, v in pairs(nest) do
        all[k] = v
        args:set(k, v)
    end

    return nest
end

return _M

