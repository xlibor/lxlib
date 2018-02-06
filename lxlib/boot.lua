
local _M = {}

function _M.init()
    
    local process = require('ngx.process')
    local ok, err = process.enable_privileged_agent()
    if not ok then
       ngx.log(ngx.ERR, "enable privileged agent failed")
    end
end

return _M

