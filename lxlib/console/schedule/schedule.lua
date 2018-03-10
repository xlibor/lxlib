
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        events = {}
    }
    
    return oo(this, mt)
end

function _M:run()

    local events = self:dueEvents()
    local eventsRan = 0

    for _, event in ipairs(events) do
        if event:filtersPass() then
            -- echo('Running scheduled command:' .. event:getSummaryForDisplay())
            ngx.thread.spawn(function()
                event:run()
            end)
            eventsRan = eventsRan + 1
        end
    end

    if #events == 0 or eventsRan == 0 then
        -- echo('No scheduled commands are ready to run.')
    end

    -- do return end
    
    if not self.tagged then
        for k, v in ipairs(self.events) do
            echo(v.command)
            echo(v.timeRange)
            echo(v.parameters)
        end
        self.tagged = true
    end
end

function _M:call(callback, parameters)

    parameters = parameters or {}
    local event = new('schedule.callbackEvent', callback, parameters)
    tapd(self.events, event)
    
    return event
end

function _M:command(command, parameters)

    parameters = parameters or {}
    if #parameters > 0 then
        -- local params = self:compileParameters(parameters)
        -- params = str.trim(params)
        -- if str.len(params) > 0 then
        --     command = command .. ' ' .. params
        -- end
    end
    local event = new('schedule.event', command, parameters)
    tapd(self.events, event)
    
    return event
end

function _M.__:compileParameters(parameters)

    return Col(parameters):map(function(value, key)
        
        return lf.isNum(key) and value or key .. '=' .. (lf.isNum(value) and value or self:escapeArgument(value))
    end):implode(' ')
end

function _M:dueEvents()

    return tb.filter(self.events, function(event)
        
        return event:isDue()
    end)
end

function _M:reset()

    self.events = {}
end

return _M

