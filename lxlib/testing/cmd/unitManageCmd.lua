
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str, new = lx.kit()
local fs = lx.fs
local try = lx.try

function _M:ctor()

end

function _M:run()

    echo('lxunit testing')
 
    local runner = self:createRunner()
    local suite = runner:getTest()
    
    local ok, result = 
    try(function()
        return runner:doRun(suite)
    end)
    :catch('unit.exception', function(e)
        echo('testFail')
        echo(e.msg)
        -- echo(e.trace)
    end)
    :catch(function(e)
        echo(e.__cls)
        echo(e.msg)
        echo(e.trace)
    end)
    :run()
    
    if ok then

    end

end

function _M:createRunner()

    local runner = new('unit.runner')

    return runner
end

return _M

