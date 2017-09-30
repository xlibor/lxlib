
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'command'
}

local app, lf, tb, str = lx.kit()
local fs = lx.fs

function _M:ctor()

    local table = app:conf('db.shift.table')
    local doer = app:make('shift.dbDoer', table)
    self.shifter = app:make('shifter', doer)
end

function _M:run()

    self:prepare()
    self.shifter:run(self.args)
    self:showNotes()
end

function _M:prepare()

    local shifter = self.shifter
    if not shifter:doerValid() then
        self:install()
    end
end

function _M:rollback()

    self.shifter:rollback(self.args)
    self:showNotes()
end

function _M:reset()

    self.shifter:reset(self.args)
    self:showNotes()
end

function _M:refresh()

    local shifter = self.shifter
    local step = self:arg('step', 0)

    if step > 0 then
        self:rollback(self.args)
    else
        self:reset(self.args)
    end
 
    self:run(self.args)
end

function _M:install()

    self.shifter:install(self.args)
    self:showNotes()
end

function _M:showNotes()

    for _, msg in ipairs(self.shifter.notes) do
        self:info(msg)
    end
end

return _M

