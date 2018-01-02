
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = 'strable',
    _static_    = {
        sunday          = 0,
        monday          = 1,
        tuesday         = 2,
        wednesday       = 3,
        thursday        = 4,
        friday          = 5,
        saturday        = 6,
        weekStartsAt    = 1,
        weekEndsAt      = 6,
        weekendDays     = {6, 0},
        days            = {
            [0] = 'Sunday',
            [1] = 'Monday',
            [2] = 'Tuesday',
            [3] = 'Wednesday',
            [4] = 'Thursday',
            [5] = 'Friday',
            [6] = 'Saturday'
        },
        defaultFormat       = '%Y-%m-%d',
        monthsPerYear       = 12,
        yearsPerCentury     = 100,
        yearsPerDecade      = 10,
        monthsPerQuarter    = 3,
        weeksPerYear        = 52,
        daysPerWeek         = 7,
        hoursPerDay         = 24,
        minutesPerHour      = 60,
        secondsPerMinute    = 60,
    }
}

local app, lf, tb, str, new = lx.kit()

local dtBase = require('lxlib.dt.base.date')
local ssub, sgsub = string.sub, string.gsub
local appTimezone

local phpFmts = {
    z = 'j', F = 'B', h = 'I',
    i = 'M', s = 'S', a = 'p', M = 'b'
}

local static

function _M._init_(this)

    static = this.static

    if app:bound('app.timezone') then
        appTimezone = app:get('app.timezone')
    end
end

function _M:new(...)

    local dtObj = dtBase(...)
    local this = {
        dto = dtObj,
        confedOffset = false
    }

    return oo(this, mt)
end

-- @item table          dto
-- @item boolean        confedOffset

function _M:ctor()

    if appTimezone then
        self:setTimezone(appTimezone)
    end
end

-- @param string    s

function _M:format(s)

    return self.dto:fmt(s)
end

function _M:fmt(s)

    local t
    s = sgsub(s, '(%w)', function(m)
        t = phpFmts[m]
        if t then
            m = t
        end
        return '%' .. m
    end)

    return self.dto:fmt(s)
end

-- @param  bool|null     raw
-- @return string|num 

function _M:getOffset(raw)

    local s = self.dto:fmt('%z')
    if raw then
        return s
    end

    if self.confedOffset then
        return self.confedOffset
    end

    local sign = ssub(s, 1, 1)
    s = ssub(s, 2)
    local hour = tonumber(ssub(s, 1, 2))
    local minute = tonumber(ssub(s, 3, 4))

    local minutes = hour * 60 + minute

    if sign == '-' then
        minutes = 0 - minutes
    end

    return minutes
end

_M.offset = _M.getOffset

function _M:offsetHours()

    return self:getOffset() / 3600
end

-- return num
function _M:getTimestamp()

    local dto = self.dto
    local t = {
        year = dto:getyear(), month = dto:getmonth(), 
        day = dto:getday(), hour = dto:gethours(),
        min  = dto:getminutes(), sec = dto:getseconds()
     }

    return os.time(t)
end

function _M:setDate(year, month, day)

    self.dto:setyear(year, month, day)

    return self
end

-- @param number        hour
-- @param number|null   minute
-- @param number|null   second
-- @return self

function _M:setTime(hour, minute, second)

    self.dto:sethours(hour, minute, second)

    return self
end

-- @param timezone  timezone
-- @return self
function _M:setTimezone(timezone)

    local offset = timezone:getOffset(self)

    if offset ~= 0 then
        self.confedOffset = timezone.offset / 60
        self.dto:addseconds(offset)
    end

    return self
end

_M.timezone = _M.setTimezone
_M.tz = _M.setTimezone

-- @param   number    ts
-- @return  self

function _M:setTimestamp(ts)

    self.dto = dtBase(ts)

    return self
end

function _M:add(dateInterval, invert)

    local dto = self.dto
    local di = dateInterval
    local y, m, d, h, i, s = self:getIntervals(di, invert)
    if y ~= 0 or m ~= 0 or d ~= 0 then
        dto:addyears(y, m, d)
    end
    if h ~= 0 then dto:addhours(h) end
    if i ~= 0 then dto:addminutes(i) end
    if s ~= 0 then dto:addseconds(i) end
end

function _M:sub(dateInterval)

    self:add(dateInterval, true)
end

function _M.__:getIntervals(dateInterval, reinvert)

    local di = dateInterval
    local y, m, d, h, i, s = di.y, di.m, di.d, di.h, di.i, di.s
    local invert = (di.invert == 1) and true or false
    if reinvert then
        invert = not invert
    end

    if invert then
        y = -y; m = -m; d = -d;
        h = -h; i = -i; s = -s
    end

    return y, m, d, h, i, s
end

function _M:diff(dt2)

end

-- @param string     s

function _M:modify(s)

    local dto = self.dto

    local year, month, day = 0, 0, 0
    local m = str.rematch(s, [[([+-])(\d+)\s*(\w+)]])
    if m then
        local sign, num, unit = m[1], m[2], m[3]
        num = tonumber(num)
        if sign == '-' then
            num = 0 - num
        end

        if str.len(unit) > 1 then

            unit = str.lower(unit)
            if unit == 'year' or unit == 'years' then
                year = num
                dto:addyears(year)
            elseif unit == 'month' or unit == 'months' then
                month = num
                dto:addyears(_, month)
            elseif unit == 'day' or unit == 'days' then
                day = num
                dto:adddays(day)
            elseif unit == 'week' or unit == 'weeks' then
                day = num * 7
                dto:adddays(day)
            end

        end

    else
        error('invalid modify expression')
    end
end

-- @param obj               this
-- @param timezone|null     tz

function _M.t__.now(this, tz)

    local dt = new(this)
    if tz then
        dt:setTimezone(tz)
    end

    return dt
end

function _M.t__.today(this, tz)

    return this.now(tz):startOfDay()
end

function _M.t__.tomorrow(this, tz)

    return this.today(tz):addDays(1)
end

-- Create a datetime instance for yesterday
-- @param obj                   this
-- @param timezone|string|null  tz
-- @return self

function _M.t__.yesterday(this, tz)

    return this.today(tz):subDay()
end

-- Create a datetime instance for the greatest supported date.
-- @return datetime

function _M.t__.maxValue(this)
 
    return this.create(9999, 12, 31, 23, 59, 59)
end

-- Create a datetime instance for the lowest supported date.
-- @return datetime

function _M.t__.minValue(this)

    return this.create(1, 1, 1, 0, 0, 0)
end

-- Create a new datetime instance from a specific date and time.
-- If any of year, month or day are set to null their now() values
-- will be used.
-- If hour is null it will be set to its now() value and the default values
-- for minute and second will be their now() values.
-- If hour is not null then the default values for minute and second
-- will be 0.
-- @param int|null                 year
-- @param int|null                 month
-- @param int|null                 day
-- @param int|null                 hour
-- @param int|null                 minute
-- @param int|null                 second
-- @param timezone|string|null tz
-- @return self

function _M.t__.create(this, year, month, day, hour, minute, second, tz)

    local dt = new(this, year, month, day, hour, minute, second)
    if tz then
        dt:setTimezone(tz)
    end

    return dt
end

-- Create a datetime instance from just a date. The time portion is set to now.
-- @param int|null                 year
-- @param int|null                 month
-- @param int|null                 day
-- @param timezone|string|null tz
-- @return self

function _M.t__.createFromDate(this, year, month, day, tz)

    return this.create(year, month, day, nil, nil, nil, tz)
end

-- Create a datetime instance from just a time. The date portion is set to today.
-- @param int|null                 hour
-- @param int|null                 minute
-- @param int|null                 second
-- @param timezone|string|null tz
-- @return self

function _M.t__.createFromTime(this, hour, minute, second, tz)

    return this.create(nil, nil, nil, hour, minute, second, tz)
end

-- Create a datetime instance from a specific format
-- @param string                   format
-- @param string                   time
-- @param timezone|string|null tz
-- @throws InvalidArgumentException
-- @return self

function _M.t__.createFromFormat(this, format, time, tz)

end

-- Create a datetime instance from a timestamp
-- @param int                      timestamp
-- @param timezone|string|null tz
-- @return self

function _M.t__.createFromTimestamp(this, timestamp, tz)

    return this.now(tz):setTimestamp(timestamp)
end

-- Create a datetime instance from an UTC timestamp
-- @param int timestamp
-- @return self

function _M.t__.createFromTimestampUTC(this, timestamp)

    return new(this ,'@' .. timestamp)
end

-- Get a copy of the instance
-- @return self

function _M:copy()

    return static.instance(self)
end

--/////////////////////////////////////////////////////////////////
--/////////////////////// GETTERS AND SETTERS /////////////////////
--/////////////////////////////////////////////////////////////////

function _M:weekOfMonth()

    return tonumber(math.ceil(self:day() / static.daysPerWeek))
end

function _M:quarter()

    return math.ceil(self:month() / 3)
end

function _M:utc()

    return self:getOffset() == 0
end

_M.isUtc = _M.utc

function _M:dst()

    return self:format('I') == '1'
end

function _M:getTimezone()

end

function _M:getTimezoneName()

end

-- function _M:local()

    -- return self.offset == self:copy():setTimezone(date_default_timezone_get()).offset
-- end

-- Set the instance's year
-- @param int|null value
-- @return self|int

function _M:year(value)

    if lf.isNil(value) then
        return self.dto:getyear()
    end

    self:setDate(value)

    return self
end

-- Set the instance's month
-- @param int|null value
-- @return self|int

function _M:month(value)

    if lf.isNil(value) then
        return self.dto:getmonth()
    end

    self:setDate(nil, value)
    
    return self
end

-- Set the instance's day
-- @param int|null value
-- @return self|int

function _M:day(value)

    if lf.isNil(value) then
        return self.dto:getday()
    end

    self:setDate(nil, nil, value)
    
    return self
end

-- Set the instance's hour
-- @param int|null value
-- @return self|int

function _M:hour(value)

    if lf.isNil(value) then
        return self.dto:gethours()
    end

    self:setTime(value)
    
    return self
end

-- Set the instance's minute
-- @param int|null value
-- @return self|int

function _M:minute(value)

    if lf.isNil(value) then
        return self.dto:getminutes()
    end

    self:setTime(nil, value)
    
    return self
end

-- Set the instance's second
-- @param int|null value
-- @return self|int

function _M:second(value)

    if lf.isNil(value) then
        return self.dto:getseconds()
    end

    self:setTime(nil, nil, value)
    
    return self
end

-- Set the date and time all together
-- @param int year
-- @param int month
-- @param int day
-- @param int hour
-- @param int minute
-- @param int second
-- @return self

function _M:setDateTime(year, month, day, hour, minute, second)

    second = second or 0
    
    return self:setDate(year, month, day):setTime(hour, minute, second)
end

-- Set the time by time string
-- @param string time
-- @return self

function _M:setTimeFromTimeString(time)

    time = str.split(time, ":")
    local t1, t2, t3 = time[1], time[2], time[3]
    local hour = t1
    local minute = t2 or 0
    local second = t3 or 0
    
    return self:setTime(hour, minute, second)
end

-- Set the instance's timestamp
-- @param int value
-- @return self

function _M:timestamp(value)

    self.timestamp = value
    
    return self
end

--/////////////////////////////////////////////////////////////////
--///////////////////// WEEK SPECIAL DAYS /////////////////////////
--/////////////////////////////////////////////////////////////////
-- Get the first day of week
-- @return int

function _M.s__.getWeekStartsAt()

    return static.weekStartsAt
end

-- Set the first day of week
-- @param int day

function _M.s__.setWeekStartsAt(day)

    static.weekStartsAt = day
end

-- Get the last day of week
-- @return int

function _M.s__.getWeekEndsAt()

    return static.weekEndsAt
end

-- Set the first day of week
-- @param int day

function _M.s__.setWeekEndsAt(day)

    static.weekEndsAt = day
end

-- Get weekend days
-- @return table

function _M.s__.getWeekendDays()

    return static.weekendDays
end

-- Set weekend days
-- @param table days

function _M.s__.setWeekendDays(days)

    static.weekendDays = days
end

--/////////////////////////////////////////////////////////////////
--/////////////////////// TESTING AIDS ////////////////////////////
--/////////////////////////////////////////////////////////////////
-- Set a datetime instance (real or mock) to be returned when a "now"
-- instance is created.  The provided instance will be returned
-- specifically under the following conditions:
--   - A call to the static now() method, ex. datetime::now()
--   - When a null (or blank string) is passed to the constructor or parse(), ex. new datetime(null)
--   - When the string "now" is passed to the constructor or parse(), ex. new datetime('now')
-- Note the timezone parameter was left out of the examples above and
-- has no affect as the mock value will be returned regardless of its value.
-- To clear the test instance call this method using the default
-- parameter of null.
-- @param datetime|null testNow

function _M.s__.setTestNow(testNow)

    static.testNow = testNow
end

-- Get the datetime instance (real or mock) to be returned when a "now"
-- instance is created.
-- @return self the current instance used for testing

function _M.s__.getTestNow()

    return static.testNow
end

-- Determine if there is a valid test instance set. A valid test instance
-- is anything that is not null.
-- @return bool true if there is a test instance, otherwise false

function _M.s__.hasTestNow()

    return static.getTestNow() and true or false
end

-- Determine if there is a relative keyword in the time string, this is to
-- create dates relative to now for test instances. e.g.: next tuesday
-- @param string time
-- @return bool true if there is a keyword, otherwise false

function _M.s__.hasRelativeKeywords(time)

    -- skip common format with a '-' in it
    if str.rematch(time, '/[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}/') ~= 1 then
        for _, keyword in pairs(static.relativeKeywords) do
            if sfind(time, keyword) then
                
                return true
            end
        end
    end
    
    return false
end

--/////////////////////////////////////////////////////////////////
--///////////////////// LOCALIZATION //////////////////////////////
--/////////////////////////////////////////////////////////////////
-- Intialize the translator instance if necessary.
-- @return TranslatorInterface

function _M.s__.initTranslator()

    if not static.translator then
        static.translator = new('translator', 'en')
        static.translator:addLoader('array', new('arrayLoader'))
        static.setLocale('en')
    end
    
    return static.translator
end

-- Get the translator instance in use
-- @return TranslatorInterface

function _M.s__.getTranslator()

    return static.initTranslator()
end

-- Set the translator instance to use
-- @param TranslatorInterface translator

function _M.s__.setTranslator(translator)

    static.translator = translator
end

-- Get the current translator locale
-- @return string

function _M.s__.getLocale()

    return static.getTranslator():getLocale()
end

-- Set the current translator locale
-- @param string locale

function _M.s__.setLocale(locale)

    static.getTranslator():setLocale(locale)
    -- Ensure the locale has been loaded.
    static.getTranslator():addResource('array', require(lx.getPath(true) .. '/lang/' .. locale, locale))
end

--/////////////////////////////////////////////////////////////////
--///////////////////// STRING FORMATTING /////////////////////////
--/////////////////////////////////////////////////////////////////

-- Reset the format used to the default when type juggling a datetime instance to a string

function _M.s__.resetDefaultFormat()

    static.setDefaultFormat(static.defaultFormat)
end

-- Set the default format used when type juggling a datetime instance to a string
-- @param string format

function _M.s__.setDefaultFormat(format)

    static.defaultFormat = format
end

-- Format the instance as a string using the set format
-- @return string

function _M:toStr()

    return self:format(static.defaultFormat)
end

-- Format the instance as date
-- @return string

function _M:toDateString()

    return self:format('%Y-%m-%d')
end

-- Format the instance as a readable date
-- @return string

function _M:toFormattedDateString()

    return self:format('M j, Y')
end

-- Format the instance as time
-- @return string

function _M:toTimeString()

    return self:format('%H:%M:%S')
end

-- Format the instance as date and time
-- @return string

function _M:toDateTimeString()

    return self:format('%Y-%m-%d %H:%M:%S')
end

-- Format the instance with day, date and time
-- @return string

function _M:toDayDateTimeString()

    return self:format('D, M j, Y g:i A')
end

-- Format the instance as ATOM
-- @return string

function _M:toAtomString()

    return self:format(static.ATOM)
end

-- Format the instance as COOKIE
-- @return string

function _M:toCookieString()

    return self:format(static.COOKIE)
end

-- Format the instance as ISO8601
-- @return string

function _M:toIso8601String()

    return self:format(static.ISO8601)
end

-- Format the instance as RFC822
-- @return string

function _M:toRfc822String()

    return self:format(static.RFC822)
end

-- Format the instance as RFC850
-- @return string

function _M:toRfc850String()

    return self:format(static.RFC850)
end

-- Format the instance as RFC1036
-- @return string

function _M:toRfc1036String()

    return self:format(static.RFC1036)
end

-- Format the instance as RFC1123
-- @return string

function _M:toRfc1123String()

    return self:format(static.RFC1123)
end

-- Format the instance as RFC2822
-- @return string

function _M:toRfc2822String()

    return self:format(static.RFC2822)
end

-- Format the instance as RFC3339
-- @return string

function _M:toRfc3339String()

    return self:format(static.RFC3339)
end

-- Format the instance as RSS
-- @return string

function _M:toRssString()

    return self:format(static.RSS)
end

-- Format the instance as W3C
-- @return string

function _M:toW3cString()

    return self:format(static.W3C)
end

--/////////////////////////////////////////////////////////////////
--//////////////////////// COMPARISONS ////////////////////////////
--/////////////////////////////////////////////////////////////////
-- Determines if the instance is equal to another
-- @param datetime dt
-- @return bool

function _M:eq(dt)

    return self.dto:__eq(dt.dto)
end

-- Determines if the instance is not equal to another
-- @param datetime dt
-- @return bool

function _M:ne(dt)

    return not self.dto:__eq(dt.dto)
end

-- Determines if the instance is greater (after) than another
-- @param datetime dt
-- @return bool

function _M:gt(dt)

    return not self.dto:__le(dt.dto)
end

-- Determines if the instance is greater (after) than or equal to another
-- @param datetime dt
-- @return bool

function _M:gte(dt)

    return not self.dto:__lt(dt.dto)
end

-- Determines if the instance is less (before) than another
-- @param datetime dt
-- @return bool

function _M:lt(dt)

    return self.dto:__lt(dt.dto)
end

-- Determines if the instance is less (before) or equal to another
-- @param datetime dt
-- @return bool

function _M:lte(dt)

    return self.dto:__le(dt.dto)
end

-- Determines if the instance is between two others
-- @param datetime dt1
-- @param datetime dt2
-- @param bool|null   equal Indicates if a > and < comparison should be used or <= or >=
-- @return bool

function _M:between(dt1, dt2, equal)

    equal = lf.needTrue(equal)
    local temp
    if dt1:gt(dt2) then
        temp = dt1
        dt1 = dt2
        dt2 = temp
    end
    if equal then
        
        return self:gte(dt1) and self:lte(dt2)
    end
    
    return self:gt(dt1) and self:lt(dt2)
end

-- Get the closest date from the instance.
-- @param datetime dt1
-- @param datetime dt2
-- @return self

function _M:closest(dt1, dt2)

    return self:diffInSeconds(dt1) < self:diffInSeconds(dt2) and dt1 or dt2
end

-- Get the farthest date from the instance.
-- @param datetime dt1
-- @param datetime dt2
-- @return self

function _M:farthest(dt1, dt2)

    return self:diffInSeconds(dt1) > self:diffInSeconds(dt2) and dt1 or dt2
end

-- Get the minimum instance between a given instance (default now) and the current instance.
-- @param datetime|null dt
-- @return self

function _M:min(dt)

    dt = dt or static.now(self.tz)
    
    return self:lt(dt) and self or dt
end

-- Get the maximum instance between a given instance (default now) and the current instance.
-- @param datetime|null dt
-- @return self

function _M:max(dt)

    dt = dt or static.now(self.tz)
    
    return self:gt(dt) and self or dt
end

-- Determines if the instance is a weekday
-- @return bool

function _M:isWeekday()

    return not self:isWeekend()
end

-- Determines if the instance is a weekend day
-- @return bool

function _M:isWeekend()

    return tb.inList(self.weekendDays, self:dayOfWeek())
end

-- Determines if the instance is yesterday
-- @return bool

function _M:isYesterday()

    return self:toDateString() == static.yesterday(self.tz):toDateString()
end

-- Determines if the instance is today
-- @return bool

function _M:isToday()

    return self:toDateString() == static.now(self.tz):toDateString()
end

-- Determines if the instance is tomorrow
-- @return bool

function _M:isTomorrow()

    return self:toDateString() == static.tomorrow(self.tz):toDateString()
end

-- Determines if the instance is in the future, ie. greater (after) than now
-- @return bool

function _M:isFuture()

    return self:gt(static.now(self.tz))
end

-- Determines if the instance is in the past, ie. less (before) than now
-- @return bool

function _M:isPast()

    return self:lt(static.now(self.tz))
end

-- Determines if the instance is a leap year
-- @return bool

function _M:isLeapYear()

    return self:format('L') == '1'
end

-- Checks if the passed in date is the same day as the instance current day.
-- @param datetime dt
-- @return bool

function _M:isSameDay(dt)

    return self:toDateString() == dt:toDateString()
end

-- Checks if this day is a Sunday.
-- @return bool

function _M:isSunday()

    return self:dayOfWeek() == static.sunday
end

-- Checks if this day is a Monday.
-- @return bool

function _M:isMonday()

    return self:dayOfWeek() == static.monday
end

-- Checks if this day is a Tuesday.
-- @return bool

function _M:isTuesday()

    return self:dayOfWeek() == static.tuesday
end

-- Checks if this day is a Wednesday.
-- @return bool

function _M:isWednesday()

    return self:dayOfWeek() == static.wednesday
end

-- Checks if this day is a Thursday.
-- @return bool

function _M:isThursday()

    return self:dayOfWeek() == static.thursday
end

-- Checks if this day is a Friday.
-- @return bool

function _M:isFriday()

    return self:dayOfWeek() == static.friday
end

-- Checks if this day is a Saturday.
-- @return bool

function _M:isSaturday()

    return self:dayOfWeek() == static.saturday
end

--/////////////////////////////////////////////////////////////////
--///////////////// ADDITIONS AND SUBTRACTIONS ////////////////////
--/////////////////////////////////////////////////////////////////
-- Add years to the instance. Positive value travel forward while
-- negative value travel into the past.
-- @param int value
-- @return self

function _M:addYears(value)

    local dto = self.dto
    dto:addyears(value)

    return self
end

-- Add a year to the instance
-- @param int|null  value
-- @return self

function _M:addYear(value)

    value = value or 1
    
    return self:addYears(value)
end

-- Remove a year from the instance
-- @param int|null   value
-- @return self

function _M:subYear(value)

    value = value or 1
    
    return self:subYears(value)
end

-- Remove years from the instance.
-- @param int value
-- @return self

function _M:subYears(value)

    return self:addYears(-1 * value)
end

-- Add months to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addMonths(value)

    local dto = self.dto
    dto:addmonths(value)

    return self
end

-- Add a month to the instance
-- @param int|null   value
-- @return self

function _M:addMonth(value)

    value = value or 1
    
    return self:addMonths(value)
end

-- Remove a month from the instance
-- @param int|null   value
-- @return self

function _M:subMonth(value)

    value = value or 1
    
    return self:subMonths(value)
end

-- Remove months from the instance
-- @param int value
-- @return self

function _M:subMonths(value)

    return self:addMonths(-1 * value)
end

-- Add months without overflowing to the instance. Positive value
-- travels forward while negative value travels into the past.
-- @param int value
-- @return self

function _M:addMonthsNoOverflow(value)

    local date = self:copy():addMonths(value)
    if date.day ~= self:day() then
        date:day(1):subMonth():day(date.daysInMonth)
    end
    
    return date
end

-- Add a month with no overflow to the instance
-- @param int|null   value
-- @return self

function _M:addMonthNoOverflow(value)

    value = value or 1
    
    return self:addMonthsNoOverflow(value)
end

-- Remove a month with no overflow from the instance
-- @param int|null   value
-- @return self

function _M:subMonthNoOverflow(value)

    value = value or 1
    
    return self:subMonthsNoOverflow(value)
end

-- Remove months with no overflow from the instance
-- @param int value
-- @return self

function _M:subMonthsNoOverflow(value)

    return self:addMonthsNoOverflow(-1 * value)
end

-- Add days to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addDays(value)

    local dto = self.dto
    dto:adddays(value)

    return self
end

-- Add a day to the instance
-- @param int|null   value
-- @return self

function _M:addDay(value)

    value = value or 1
    
    return self:addDays(value)
end

-- Remove a day from the instance
-- @param int|null  value
-- @return self

function _M:subDay(value)

    value = value or 1
    
    return self:subDays(value)
end

-- Remove days from the instance
-- @param int value
-- @return self

function _M:subDays(value)

    return self:addDays(-1 * value)
end

-- Add weekdays to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addWeekdays(value)

    return self:modify(tonumber(value) .. ' weekday')
end

-- Add a weekday to the instance
-- @param int|null   value
-- @return self

function _M:addWeekday(value)

    value = value or 1
    
    return self:addWeekdays(value)
end

-- Remove a weekday from the instance
-- @param int|null   value
-- @return self

function _M:subWeekday(value)

    value = value or 1
    
    return self:subWeekdays(value)
end

-- Remove weekdays from the instance
-- @param int value
-- @return self

function _M:subWeekdays(value)

    return self:addWeekdays(-1 * value)
end

-- Add weeks to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addWeeks(value)

    return self:addDays(value * 7)
end

-- Add a week to the instance
-- @param int|null   value
-- @return self

function _M:addWeek(value)

    value = value or 1
    
    return self:addWeeks(value)
end

-- Remove a week from the instance
-- @param int|null   value
-- @return self

function _M:subWeek(value)

    value = value or 1
    
    return self:subWeeks(value)
end

-- Remove weeks to the instance
-- @param int value
-- @return self

function _M:subWeeks(value)

    return self:addWeeks(-1 * value)
end

-- Add hours to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addHours(value)

    local dto = self.dto
    dto:addhours(value)

    return self
end

-- Add an hour to the instance
-- @param int|null   value
-- @return self

function _M:addHour(value)

    value = value or 1
    
    return self:addHours(value)
end

-- Remove an hour from the instance
-- @param int|null   value
-- @return self

function _M:subHour(value)

    value = value or 1
    
    return self:subHours(value)
end

-- Remove hours from the instance
-- @param int value
-- @return self

function _M:subHours(value)

    return self:addHours(-1 * value)
end

-- Add minutes to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addMinutes(value)

    self.dto:addminutes(value)

    return self
end

-- Add a minute to the instance
-- @param int|null   value
-- @return self

function _M:addMinute(value)

    value = value or 1
    
    return self:addMinutes(value)
end

-- Remove a minute from the instance
-- @param int|null   value
-- @return self

function _M:subMinute(value)

    value = value or 1
    
    return self:subMinutes(value)
end

-- Remove minutes from the instance
-- @param int value
-- @return self

function _M:subMinutes(value)

    return self:addMinutes(-1 * value)
end

-- Add seconds to the instance. Positive value travels forward while
-- negative value travels into the past.
-- @param int value
-- @return self

function _M:addSeconds(value)

    self.dto:addseconds(value)

    return self
end

-- Add a second to the instance
-- @param int|null   value
-- @return self

function _M:addSecond(value)

    value = value or 1
    
    return self:addSeconds(value)
end

-- Remove a second from the instance
-- @param int|null   value
-- @return self

function _M:subSecond(value)

    value = value or 1
    
    return self:subSeconds(value)
end

-- Remove seconds from the instance
-- @param int value
-- @return self

function _M:subSeconds(value)

    return self:addSeconds(-1 * value)
end

--/////////////////////////////////////////////////////////////////
--///////////////////////// DIFFERENCES ///////////////////////////
--/////////////////////////////////////////////////////////////////
-- Get the difference in years
-- @param datetime|null dt
-- @param bool|null        abs Get the absolute of the difference
-- @return int

function _M:diffInYears(dt, abs)

    abs = lf.needTrue(abs)
    dt = dt or static.now(self.tz)
    
    return tonumber(self:diff(dt, abs):format('%r%y'))
end

_M.age = _M.diffInYears

-- Get the difference in months
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInMonths(dt, abs)

    abs = lf.needTrue(abs)
    dt = dt or static.now(self.tz)
    
    return self:diffInYears(dt, abs) * static.monthsPerYear + tonumber(self:diff(dt, abs):format('%r%m'))
end

-- Get the difference in weeks
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInWeeks(dt, abs)

    abs = lf.needTrue(abs)
    
    return tonumber((self:diffInDays(dt, abs) / static.daysPerWeek))
end

-- Get the difference in days
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInDays(dt, abs)

    abs = lf.needTrue(abs)
    dt = dt or static.now(self.tz)
    
    return tonumber(self:diff(dt, abs):format('%r%a'))
end

-- Get the difference in days using a filter closure
-- @param Closure           callback
-- @param datetime|null     dt
-- @param bool|null         abs      Get the absolute of the difference
-- @return int

function _M:diffInDaysFiltered(callback, dt, abs)

    abs = lf.needTrue(abs)
    
    return self:diffFiltered(datetimeInterval.day(), callback, dt, abs)
end

-- Get the difference in hours using a filter closure
-- @param Closure           callback
-- @param datetime|null     dt
-- @param bool|null         abs      Get the absolute of the difference
-- @return int

function _M:diffInHoursFiltered(callback, dt, abs)

    abs = lf.needTrue(abs)
    
    return self:diffFiltered(datetimeInterval.hour(), callback, dt, abs)
end

-- Get the difference by the given interval using a filter closure
-- @param datetimeInterval  ci       An interval to traverse by
-- @param Closure           callback
-- @param datetime|null     dt
-- @param bool|null         abs      Get the absolute of the difference
-- @return int

function _M:diffFiltered(ci, callback, dt, abs)

    abs = lf.needTrue(abs)
    local start = self
    local theEnd = dt or static.now(self.tz)
    local inverse = false
    if theEnd < start then
        start = theEnd
        theEnd = self
        inverse = true
    end
    local period = new('datePeriod' ,start, ci, theEnd)
    local vals = tb.filter(iterator_to_array(period), function(date)
        
        return lf.call(callback, datetime.instance(date))
    end)
    local diff = #vals
    
    return inverse and not abs and -diff or diff
end

-- Get the difference in weekdays
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInWeekdays(dt, abs)

    abs = lf.needTrue(abs)
    
    return self:diffInDaysFiltered(function(date)
        
        return date:isWeekday()
    end, dt, abs)
end

-- Get the difference in weekend days using a filter
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInWeekendDays(dt, abs)

    abs = lf.needTrue(abs)
    
    return self:diffInDaysFiltered(function(date)
        
        return date:isWeekend()
    end, dt, abs)
end

-- Get the difference in hours
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInHours(dt, abs)

    abs = lf.needTrue(abs)
    
    return tonumber((self:diffInSeconds(dt, abs) / static.secondsPerMinute / static.minutesPerHour))
end

-- Get the difference in minutes
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInMinutes(dt, abs)

    abs = lf.needTrue(abs)
    
    return tonumber((self:diffInSeconds(dt, abs) / static.secondsPerMinute))
end

-- Get the difference in seconds
-- @param datetime|null     dt
-- @param bool|null         abs Get the absolute of the difference
-- @return int

function _M:diffInSeconds(dt, abs)

    abs = lf.needTrue(abs)
    dt = dt or static.now(self.tz)
    local value = dt:getTimestamp() - self:getTimestamp()
    
    return abs and abs(value) or value
end

-- The number of seconds since midnight.
-- @return int

function _M:secondsSinceMidnight()

    return self:diffInSeconds(self:copy():startOfDay())
end

-- The number of seconds until 23:23:59.
-- @return int

function _M:secondsUntilEndOfDay()

    return self:diffInSeconds(self:copy():endOfDay())
end

-- Get the difference in a human readable format in the current locale.
-- When comparing a value in the past to default now:
-- 1 hour ago
-- 5 months ago
-- When comparing a value in the future to default now:
-- 1 hour from now
-- 5 months from now
-- When comparing a value in the past to another value:
-- 1 hour before
-- 5 months before
-- When comparing a value in the future to another value:
-- 1 hour after
-- 5 months after
-- @param datetime|null other
-- @param bool        absolute removes time difference modifiers ago, after, etc
-- @return string

function _M:diffForHumans(other, absolute)

    absolute = absolute or false
    local count
    local isNow = other == nil
    if isNow then
        other = static.now(self.tz)
    end
    local diffInterval = self:diff(other)
    local st = true
    if st == diffInterval.y > 0 then
        unit = 'year'
        count = diffInterval.y
     elseif st == diffInterval.m > 0 then
        unit = 'month'
        count = diffInterval.m
     elseif st == diffInterval.d > 0 then
        unit = 'day'
        count = diffInterval.d
        if count >= self:daysPerWeek() then
            unit = 'week'
            count = tonumber((count / self:daysPerWeek()))
        end
     elseif st == diffInterval.h > 0 then
        unit = 'hour'
        count = diffInterval.h
     elseif st == diffInterval.i > 0 then
        unit = 'minute'
        count = diffInterval.i
     else 
        count = diffInterval.s
        unit = 'second'
    end
    if count == 0 then
        count = 1
    end
    local time = static.getTranslator():transChoice(unit, count, {[':count'] = count})
    if absolute then
        
        return time
    end
    local isFuture = diffInterval.invert == 1
    local transId = isNow and isFuture and 'from_now' or 'ago' or (isFuture and 'after' or 'before')
    -- Some langs have special pluralization for past and future tense.
    local tryKeyExists = unit .. '_' .. transId
    if tryKeyExists ~= static.getTranslator():transChoice(tryKeyExists, count) then
        time = static.getTranslator():transChoice(tryKeyExists, count, {[':count'] = count})
    end
    
    return static.getTranslator():trans(transId, {[':time'] = time})
end

--/////////////////////////////////////////////////////////////////
--////////////////////////// MODIFIERS ////////////////////////////
--/////////////////////////////////////////////////////////////////
-- Resets the time to 00:00:00
-- @return self

function _M:startOfDay()

    self:setTime(0, 0, 0)
    return self
end

-- Resets the time to 23:59:59
-- @return self

function _M:endOfDay()
    
    self:setTime(23, 59, 59)

    return self
end

-- Resets the date to the first day of the month and the time to 00:00:00
-- @return self

function _M:startOfMonth()

    return self:startOfDay():day(1)
end

-- Resets the date to end of the month and time to 23:59:59
-- @return self

function _M:endOfMonth()

    return self:day(self:daysInMonth()):endOfDay()
end

-- Resets the date to the first day of the year and the time to 00:00:00
-- @return self

function _M:startOfYear()

    return self:month(1):startOfMonth()
end

-- Resets the date to end of the year and time to 23:59:59
-- @return self

function _M:endOfYear()

    return self:month(static.monthsPerYear):endOfMonth()
end

-- Resets the date to the first day of the decade and the time to 00:00:00
-- @return self

function _M:startOfDecade()

    return self:startOfYear():year(self:year() - self:year() % static.yearsPerDecade)
end

-- Resets the date to end of the decade and time to 23:59:59
-- @return self

function _M:endOfDecade()

    return self:endOfYear():year(self:year() - self:year() % static.yearsPerDecade + static.yearsPerDecade - 1)
end

-- Resets the date to the first day of the century and the time to 00:00:00
-- @return self

function _M:startOfCentury()

    return self:startOfYear():year(self:year() - self:year() % static.yearsPerCentury)
end

-- Resets the date to end of the century and time to 23:59:59
-- @return self

function _M:endOfCentury()

    return self:endOfYear():year(self:year() - self:year() % static.yearsPerCentury + static.yearsPerCentury - 1)
end

-- Resets the date to the first day of week (defined in weekStartsAt) and the time to 00:00:00
-- @return self

function _M:startOfWeek()

    if self:dayOfWeek() ~= static.weekStartsAt then
        self:previous(static.weekStartsAt)
    end
    
    return self:startOfDay()
end

-- Resets the date to end of week (defined in weekEndsAt) and time to 23:59:59
-- @return self

function _M:endOfWeek()

    if self:dayOfWeek() ~= static.weekEndsAt then
        self:next(static.weekEndsAt)
    end
    
    return self:endOfDay()
end

-- Modify to the next occurrence of a given day of the week.
-- If no dayOfWeek is provided, modify to the next occurrence
-- of the current day of the week.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:next(dayOfWeek)

    if dayOfWeek == nil then
        dayOfWeek = self:dayOfWeek()
    end
    
    return self:startOfDay():modify('next ' .. static.days[dayOfWeek])
end

-- Modify to the previous occurrence of a given day of the week.
-- If no dayOfWeek is provided, modify to the previous occurrence
-- of the current day of the week.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:previous(dayOfWeek)

    if dayOfWeek == nil then
        dayOfWeek = self:dayOfWeek()
    end
    
    return self:startOfDay():modify('last ' .. static.days[dayOfWeek])
end

-- Modify to the first occurrence of a given day of the week
-- in the current month. If no dayOfWeek is provided, modify to the
-- first day of the current month.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:firstOfMonth(dayOfWeek)

    self:startOfDay()
    if dayOfWeek == nil then
        
        return self:day(1)
    end
    
    return self:modify('first ' .. static.days[dayOfWeek] .. ' of ' .. self:format('F') .. ' ' .. self:year())
end

-- Modify to the last occurrence of a given day of the week
-- in the current month. If no dayOfWeek is provided, modify to the
-- last day of the current month.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:lastOfMonth(dayOfWeek)

    self:startOfDay()
    if dayOfWeek == nil then
        
        return self:day(self:daysInMonth())
    end
    
    return self:modify('last ' .. static.days[dayOfWeek] .. ' of ' .. self:format('F') .. ' ' .. self:year())
end

-- Modify to the given occurrence of a given day of the week
-- in the current month. If the calculated occurrence is outside the scope
-- of the current month, then return false and no modifications are made.
-- Use the supplied consts to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int nth
-- @param int dayOfWeek
-- @return mixed

function _M:nthOfMonth(nth, dayOfWeek)

    local dt = self:copy():firstOfMonth()
    local check = dt:format('Y-m')
    dt:modify('+' .. nth .. ' ' .. static.days[dayOfWeek])
    
    return dt:format('Y-m') == check and self:modify(dt) or false
end

-- Modify to the first occurrence of a given day of the week
-- in the current quarter. If no dayOfWeek is provided, modify to the
-- first day of the current quarter.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:firstOfQuarter(dayOfWeek)

    return self:day(1):month(self.quarter * 3 - 2):firstOfMonth(dayOfWeek)
end

-- Modify to the last occurrence of a given day of the week
-- in the current quarter. If no dayOfWeek is provided, modify to the
-- last day of the current quarter.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:lastOfQuarter(dayOfWeek)

    return self:day(1):month(self.quarter * 3):lastOfMonth(dayOfWeek)
end

-- Modify to the given occurrence of a given day of the week
-- in the current quarter. If the calculated occurrence is outside the scope
-- of the current quarter, then return false and no modifications are made.
-- Use the supplied consts to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int nth
-- @param int dayOfWeek
-- @return mixed

function _M:nthOfQuarter(nth, dayOfWeek)

    local dt = self:copy():day(1):month(self.quarter * 3)
    local lastMonth = dt.month
    local year = dt.year
    dt:firstOfQuarter():modify('+' .. nth .. ' ' .. static.days[dayOfWeek])
    
    return lastMonth < dt.month or year ~= dt.year and false or self:modify(dt)
end

-- Modify to the first occurrence of a given day of the week
-- in the current year. If no dayOfWeek is provided, modify to the
-- first day of the current year.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:firstOfYear(dayOfWeek)

    return self:month(1):firstOfMonth(dayOfWeek)
end

-- Modify to the last occurrence of a given day of the week
-- in the current year. If no dayOfWeek is provided, modify to the
-- last day of the current year.  Use the supplied consts
-- to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int|null dayOfWeek
-- @return self

function _M:lastOfYear(dayOfWeek)

    return self:month(static.monthsPerYear):lastOfMonth(dayOfWeek)
end

-- Modify to the given occurrence of a given day of the week
-- in the current year. If the calculated occurrence is outside the scope
-- of the current year, then return false and no modifications are made.
-- Use the supplied consts to indicate the desired dayOfWeek, ex. static::MONDAY.
-- @param int nth
-- @param int dayOfWeek
-- @return mixed

function _M:nthOfYear(nth, dayOfWeek)

    local dt = self:copy():firstOfYear():modify('+' .. nth .. ' ' .. static.days[dayOfWeek])
    
    return self:year() == dt.year and self:modify(dt) or false
end

-- Modify the current instance to the average of a given instance (default now) and the current instance.
-- @param datetime|null dt
-- @return self

function _M:average(dt)

    dt = dt or static.now(self.tz)
    
    return self:addSeconds(tonumber((self:diffInSeconds(dt, false) / 2)))
end

-- Check if its the birthday. Compares the date/month values of the two dates.
-- @param datetime|null dt The instance to compare with or null to use current day.
-- @return bool

function _M:isBirthday(dt)

    dt = dt or static.now(self.tz)
    
    return self:format('md') == dt:format('md')
end

return _M

