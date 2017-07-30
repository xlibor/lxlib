-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- ...


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'regularExpression'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        string = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param string string

function _M:ctor(string)

    parent.__construct(string)
    self.pattern = self:createPatternFromFormat(\str.rereplace(string, '/\\r\\n/', "\n"))
    self.string = string
end

function _M.__:failureDescription(other)

    return 'string matches format description'
end

function _M.__:additionalFailureDescription(other)

    local line
    local from = \preg_split('(\\r\\n|\\r|\\n)', self.string)
    local to = \preg_split('(\\r\\n|\\r|\\n)', other)
    for index, line in pairs(from) do
        if to[index] and line ~= to[index] then
            line = self:createPatternFromFormat(line)
            if \str.rematch(to[index], line) > 0 then
                from[index] = to[index]
            end
        end
    end
    self.string = \str.join(from, "\n")
    other = \str.join(to, "\n")
    local differ = new('differ', "--- Expected\n+++ Actual\n")
    
    return differ:diff(self.string, other)
end

function _M.__:createPatternFromFormat(string)

    string = \str.replace(\str.pregQuote(string, '/'), {'%e', '%s', '%S', '%a', '%A', '%w', '%i', '%d', '%x', '%f', '%c'}, {'\\' .. DIRECTORY_SEPARATOR, '[^\\r\\n]+', '[^\\r\\n]*', '.+', '.*', '\\s*', '[+-]?\\d+', '\\d+', '[0-9a-fA-F]+', '[+-]?\\.?\\d+\\.?\\d*(?:[Ee][+-]?\\d+)?', '.'})
    
    return '/^' .. string .. '$/s'
end

return _M

