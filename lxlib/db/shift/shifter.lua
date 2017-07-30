
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs
local dbInit = lx.db

function _M:new(doer)

    local this = {
        doer = doer,
        db = app.db,
        notes = {},
        paths = {}
    }

    oo(this, mt)

    return this
end

function _M:ctor()

end

function _M:run(options)
     
    self.notes = {}
    local path = self:getShiftPath()

    local files = self:getShiftFiles(path)
 
    local ran = self.doer:getRan()

    local shifts = lx.col(files):reject(function(file)

            return tb.contains(ran, self:getShiftName(file))
        end)

    self:runShiftList(shifts, options)

    return shifts
end

function _M:install()

    self.notes = {}
    
    self.doer:create()
    self:note('shift table created successfully')
end

function _M:getShiftPath()

    local dir = lx.dir('db','shift')

    return dir
end

function _M:getShiftName(path)

    return str.replace(fs.baseName(path), '.lua', '')
end

function _M:runUp(file, batch, pretend)
    
    file = self:getShiftName(file)
    local shift = self:resolve(file)

    self:prepareRun()

    if pretend then
        return self:prependToRun(shift, 'up')
    end

    local schema = self:getSchema(shift.connName)
    shift:up(schema)

    self.doer:log(file, batch)
    self:note('shifted:'..file)
end

function _M:prepareRun()

    local conn = self:getConn()

    conn:exec("SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ALLOW_INVALID_DATES';")
end

function _M:runDown(file, shift, pretend)

    local instance = self:resolve(file)

    if pretend then
        return self:prependToRun(instance, 'down')
    end

    local schema = self:getSchema(instance.connName)
    instance:down(schema)

    self.doer:delete(shift)
    self:note('roll back:'..file)
end

function _M:rollback(options)

    self.notes = {}

    local rolledBack = {}
    local steps = tb.get(options, 'step', 0)
    local shifts

    if steps > 0 then
        shifts = self.doer:getShifts(steps)
    else
        shifts = self.doer:getLast()
    end

    local count = tb.count(shifts)
    local path = self:getShiftPath()
    local files = self:getShiftFiles(path)
    files = tb.flip(files, true)
    local pretend, file
    if count == 0 then
        self:note('nothing to rollback')
    else
        pretend = options.pretend
        for _, shift in ipairs(shifts) do
            file = files[shift.shift]
            tapd(rolledBack, file)
            self:runDown(file, shift.shift, pretend)
        end
    end

    return rolledBack
end

function _M:reset(options)

    self.notes = {}

    local rolledBack = {}
    local path = self:getShiftPath()
    local files = self:getShiftFiles(path)
    files = tb.flip(files, true)
    local shifts = tb.reverse(self.doer:getRan())
 
    local count = tb.count(shifts)
    
    local pretend, file
    if count == 0 then
        self:note('nothing to rollback')
    else
        pretend = options.pretend
        for _, shift in ipairs(shifts) do
            file = files[shift]
            tapd(rolledBack, file)
            self:runDown(file, shift, pretend)
        end
    end

    return rolledBack
end

function _M:resolve(file)

    local dir = self:getShiftNamespace()
    local path = dir..'.'..file

    return require(path)
end

function _M.__:getShiftNamespace()

    return app.dbPath..'.shift'
end

function _M:runShiftList(shifts, options)

    if lf.isEmpty(shifts) then
        self:note('nothing to shift')
        return
    end

    local batch = self.doer:getNextBatchNumber()
    local pretend = options.pretend
    local step = options.step

    for _, file in ipairs(shifts) do
        self:runUp(file, batch, pretend)

        if step then
            batch = batch + 1
        end
    end
end

function _M:getShiftFiles(path)

    local files = fs.files(path, 'n', function(file)
        local name, ext = file:sub(1, -5), file:sub(-3)

        if ext == 'lua' then
            return name
        end
    end)

    tb.sort(files)

    return files or {}
end
 
function _M:doerValid()

    return self.doer:isValid()
end

function _M:prependToRun(shift, method)
    
    local queries = self:getQueries(shift, method)
    local name = shift.__cls

    for _, query in ipairs(queries) do
        self:note('name:'..name..',query:'..query.query)
    end
end

function _M.__:getConn(connName)

    return self.db:conn(connName)
end

function _M.__:getQueries(shift, method)

    local connName = shift.connName
    local conn = self:getConn(connName)
    local schema = conn:getSchemaBuilder()
    return conn:pretend(function(conn)
        lf.call({shift, method}, schema)
    end)
end

function _M.__:getSchema(connName)

    return self:getConn(connName):getSchemaBuilder()
end

function _M.__:note(message)

    tapd(self.notes, message)
end

function _M:getNotes()

    return self.notes
end

return _M

