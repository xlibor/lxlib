
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

local slen = string.len

function _M:new(command, parameters)

    local this = {
        command = command,
        parameters = parameters,
        interval = 60,
        lastRan = nil,
        timeRange = {},
        expression = '* * * * * *',
        timezone = nil,
        user = nil,
        environments = {},
        evenInMaintenanceMode = false,
        withoutOverlapping = false,
        runInBackground = false,
        filters = {},
        rejects = {},
        output = '/dev/null',
        shouldAppendOutput = false,
        beforeCallbacks = {},
        afterCallbacks = {},
        description = nil
    }
    
    return oo(this, mt)
end

function _M:ctor()

end

function _M:run()

    if not self.runInBackground then
        self:runCommandInForeground()
     else 
        self:runCommandInBackground()
    end
end

function _M.__:runCommandInForeground()

    self:callBeforeCallbacks()
    self:runCommand()
    self:callAfterCallbacks()
end

function _M.__:runCommandInBackground()

    self:runCommand()
end

function _M.__:runCommand()

    local command = self:buildCommand()
    self.lastRan = Dt.now()
    app:run(command, self.parameters)
end

function _M.__:updateLastRan()

    self.lastRan = Dt.now()
end

function _M.__:callBeforeCallbacks()

    for _, callback in ipairs(self.beforeCallbacks) do
        callback()
    end
end

function _M.__:callAfterCallbacks()

    for _, callback in ipairs(self.afterCallbacks) do
        callback()
    end
end

function _M:buildCommand()

    local command
 
    if self.withoutOverlapping then
        command = self.command
    else
        command = self.command
    end
    
    return command
end

function _M:isDue()

    if not self:runsInMaintenanceMode() and app:isDownForMaintenance() then
        
        return false
    end
    
    return self:expressionPasses() and self:runsInEnvironment(app:getEnv())
end

function _M.__:expressionPasses()

    local now = Dt.now()
    if self.timezone then
        now:setTimezone(self.timezone)
    end
    
    return self:isExpressionDue(self.expression, now)
end

function _M.__:isExpressionDue(expression, now)

    local ret = false

    if not self:checkTimeRange(now) then
        return false
    end

    local lastRan = self.lastRan
    if not lastRan then
        return true
    end

    if lastRan:lte(now:subSeconds(self.interval)) then
        return true
    end

    return false
end

function _M.__:checkTimeRange(now)

    if #self.timeRange == 0 then
        return true
    end

    local nowTime = now:toTimeString()

    local inRange = false
    for _, range in ipairs(self.timeRange) do
        local beginTime, endTime = range[1], range[2]

        if beginTime < endTime then
            if (nowTime >= beginTime and nowTime < endTime) then
                inRange = true
                break
            end
        else
            if (nowTime < endTime or nowTime >= beginTime) then
                inRange = true
                break
            end
        end
    end

    return inRange
end

function _M:filtersPass()

    for _, callback in ipairs(self.filters) do
        if not callback() then
            
            return false
        end
    end
    for _, callback in ipairs(self.rejects) do
        if callback() then
            
            return false
        end
    end
    
    return true
end

function _M:runsInEnvironment(environment)

    return lf.isEmpty(self.environments) or tb.inList(self.environments, environment)
end

function _M:runsInMaintenanceMode()

    return self.evenInMaintenanceMode
end

function _M:cron(expression)

    self.expression = expression
    
    return self
end

function _M:every(interval)

    self.interval = interval

    return self
end

function _M:between(...)
    
    local args = lf.getArgs(...)
    local p1, p2 = args[1], args[2]

    if lf.isTbl(p1) then
        for _, range in ipairs(args) do
            self:inTimeRange(range[1], range[2])
        end

        return self
    else
        return self:inTimeRange(p1, p2, false)
    end
end

function _M:unlessBetween(startTime, endTime)
    
    return self:inTimeRange(startTime, endTime, true)
end

function _M:inTimeRange(startTime, endTime, ifSkip)
    
    if slen(startTime) == 5 then
        startTime = startTime .. ':00'
    end

    if slen(endTime) == 5 then
        endTime = endTime .. ':00'
    end

    if not ifSkip then
        tapd(self.timeRange, {startTime, endTime})
    else
        tapd(self.timeRange, {'00:00:00', startTime})
        tapd(self.timeRange, {endTime, '23:59:59'})
    end

    return self
end

function _M:hourly()

    return self:spliceIntoPosition(1, 0)
end

function _M:daily()

    return self:spliceIntoPosition(1, 0):spliceIntoPosition(2, 0)
end

function _M:at(time)

    return self:dailyAt(time)
end

function _M:dailyAt(time)

    local segments = str.split(time, ':')
    
    return self:spliceIntoPosition(2, tonumber(segments[0])):spliceIntoPosition(1, #segments == 2 and tonumber(segments[1]) or '0')
end

function _M:twiceDaily(first, second)

    second = second or 13
    first = first or 1
    local hours = first .. ',' .. second
    
    return self:spliceIntoPosition(1, 0):spliceIntoPosition(2, hours)
end

function _M:weekdays()

    return self:spliceIntoPosition(5, '1-5')
end

function _M:mondays()

    return self:days(1)
end

function _M:tuesdays()

    return self:days(2)
end

function _M:wednesdays()

    return self:days(3)
end

function _M:thursdays()

    return self:days(4)
end

function _M:fridays()

    return self:days(5)
end

function _M:saturdays()

    return self:days(6)
end

function _M:sundays()

    return self:days(0)
end

function _M:weekly()

    return self:spliceIntoPosition(1, 0):spliceIntoPosition(2, 0):spliceIntoPosition(5, 0)
end

function _M:weeklyOn(day, time)

    time = time or '0:0'
    self:dailyAt(time)
    
    return self:spliceIntoPosition(5, day)
end

function _M:monthly()

    return self:spliceIntoPosition(1, 0):spliceIntoPosition(2, 0):spliceIntoPosition(3, 1)
end

function _M:monthlyOn(day, time)

    time = time or '0:0'
    day = day or 1
    self:dailyAt(time)
    
    return self:spliceIntoPosition(3, day)
end

function _M:quarterly()

    return self:spliceIntoPosition(1, 0):spliceIntoPosition(2, 0):spliceIntoPosition(3, 1):spliceIntoPosition(4, '*/3')
end

function _M:yearly()

    return self:spliceIntoPosition(1, 0):spliceIntoPosition(2, 0):spliceIntoPosition(3, 1):spliceIntoPosition(4, 1)
end

function _M:everyMinute()

    return self:spliceIntoPosition(1, '*')
end

function _M:everyFiveMinutes()

    return self:spliceIntoPosition(1, '*/5')
end

function _M:everyTenMinutes()

    return self:spliceIntoPosition(1, '*/10')
end

function _M:everyThirtyMinutes()

    return self:spliceIntoPosition(1, '0,30')
end

function _M:days(days)

    days = lf.isTbl(days) and days or func_get_args()
    
    return self:spliceIntoPosition(5, str.join(days, ','))
end

function _M:runInBackground()

    self.runInBackground = true
    
    return self
end

function _M:setTimezone(timezone)

    self.timezone = timezone
    
    return self
end

function _M:user(user)

    self.user = user
    
    return self
end

function _M:environments(environments)

    self.environments = lf.isTbl(environments) and environments or func_get_args()
    
    return self
end

function _M:evenInMaintenanceMode()

    self.evenInMaintenanceMode = true
    
    return self
end

function _M:withoutOverlapping()

    self.withoutOverlapping = true
    
    return self:skip(function()
        
        return file_exists(self:mutexPath())
    end)
end

function _M:when(callback)

    tapd(self.filters, callback)
    
    return self
end

function _M:skip(callback)

    tapd(self.rejects, callback)
    
    return self
end

function _M:sendOutputTo(location, append)

    append = append or false
    self.output = location
    self.shouldAppendOutput = append
    
    return self
end

function _M:appendOutputTo(location)

    return self:sendOutputTo(location, true)
end

function _M:emailOutputTo(addresses, onlyIfOutputExists)

    onlyIfOutputExists = onlyIfOutputExists or false
    if not self.output or self.output == self:getDefaultOutput() then
        lx.throw('logicException', 'Must direct output to a file in order to e-mail results.')
    end
    addresses = lf.isTbl(addresses) and addresses or func_get_args()
    
    return self:then_(function(mailer)
        self:emailOutput(mailer, addresses, onlyIfOutputExists)
    end)
end

function _M:emailWrittenOutputTo(addresses)

    return self:emailOutputTo(addresses, true)
end

function _M.__:emailOutput(mailer, addresses, onlyIfOutputExists)

    onlyIfOutputExists = onlyIfOutputExists or false
    local text = file_get_contents(self.output)
    if onlyIfOutputExists and lf.isEmpty(text) then
        
        return
    end
    mailer:raw(text, function(m)
        m:subject(self:getEmailSubject())
        for _, address in pairs(addresses) do
            m:to(address)
        end
    end)
end

function _M.__:getEmailSubject()

    if self.description then
        
        return 'Scheduled Job Output (' .. self.description .. ')'
    end
    
    return 'Scheduled Job Output'
end

function _M:pingBefore(url)

    return self:before(function()
        (new('httpClient')):get(url)
    end)
end

function _M:before(callback)

    tapd(self.beforeCallbacks, callback)
    
    return self
end

function _M:thenPing(url)

    return self:then_(function()
        (new('httpClient')):get(url)
    end)
end

function _M:after(callback)

    return self:then_(callback)
end

function _M:then_(callback)

    tapd(self.afterCallbacks, callback)
    
    return self
end

function _M:name(description)

    return self:description(description)
end

function _M:description(description)

    self.description = description
    
    return self
end

function _M.__:spliceIntoPosition(position, value)

    local segments = str.split(self.expression, ' ')
    segments[position - 1] = value
    
    return self:cron(str.join(segments, ' '))
end

function _M:getSummaryForDisplay()

    if lf.isStr(self.description) then
        
        return self.description
    end
    
    return self:buildCommand()
end

function _M:getExpression()

    return self.expression
end

return _M

