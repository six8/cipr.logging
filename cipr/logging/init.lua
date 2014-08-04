local print = print
local date = os.date
local sformat = string.format
local io = io
local json = require 'json'

-- Public namespace for the logging module
local ns = {}

local ROOT_NAME = 'root'

-- Should we check how class methods are being called? Can be disabled in production.
local STRICT = true

local NOTSET
local CRITICAL = 50
local ERROR = 40
local INFO = 20
local WARNING = 30
local DEBUG = 10
local VERBOSE = 1

-- Put levels in namespace
ns.CRITICAL = CRITICAL
ns.ERROR = ERROR
ns.INFO = INFO
ns.WARNING = WARNING
ns.WARN = WARNING
ns.DEBUG = DEBUG
ns.VERBOSE = VERBOSE

local levelNameMap = {
    [CRITICAL] = 'CRITICAL',
    [ERROR] = 'ERROR',
    [INFO] = 'INFO',
    [WARNING] = 'WARNING',
    [DEBUG] = 'DEBUG',
    [VERBOSE] = 'VERBOSE',
}

local timeFormat = '%Y%m%dT%X'

--[[
Split a `str` by '.'
]]--
local function split(str)
    local sep = '.'
    local fields = {}
    local i = 1
    local addTo = function(c)
        fields[i] = c
        i = i + 1
    end

    str = str .. sep
    str:gsub("([^"..sep.."]*)"..sep, addTo)
    return fields
end

-- Create class
ns.Logger = {
    CRITICAL = ns.CRITICAL,
    ERROR = ns.ERROR,
    INFO = ns.INFO,
    WARNING = ns.WARNING,
    WARN = ns.WARNING,
    DEBUG = ns.DEBUG,
    VERBOSE = ns.VERBOSE    
}

ns.Logger.__index = ns.Logger

--[[
Make sure self is an instance of Logger. Used to make sure methods are being called
with a `:`.
]]--
local checkself = function(self, methodName)
    if self.__index ~= ns.Logger.__index then
        error('`' .. methodName .. '` must be called in method format.')
    end
end

function ns.Logger.new(theClass, ...)
    local instance = setmetatable({ class = theClass }, ns.Logger)
    instance:initialize(...)
    return instance
end

function ns.Logger:initialize(name, level, parent)
    self._name = name
    self._parent = parent
    self:setLevel(level)
end

function ns.Logger:__tostring()
    return sformat('<Logger(name=\'%s\', level=%s, parent=%s)>', self._name or 'nil', self._level or 'nil', self._parent and self._parent:__tostring() or 'nil')
end

function ns.Logger:setLevel(level)
    self._level = level

    if self._parent == nil then
        local platform = system.getInfo("platformName")
        if platform == "Win" then
            -- Disable buffering in windows simulator
            io.output():setvbuf('no')
        elseif platform == "Mac OS X" or level == DEBUG then
            -- Use line buffer if debugging or on MacOSX simulator
            io.output():setvbuf('line')
        else
            -- Turn on console output buffering on devices when not debugging, to avoid performance issues
            io.output():setvbuf('full')
        end
    end
end

function ns.Logger:getEffectiveLevel()
    if self._level then
        return self._level
    elseif self._parent then
        return self._parent:getEffectiveLevel()
    else
        return 0
    end
end

function ns.Logger:log(level, message, ...)
    if STRICT then checkself(self, 'Logger:log') end
    if level and level >= self:getEffectiveLevel() then
        if ... then
            local args = {...}
            for i=1,#args do
                if type(args[i]) == 'table' then
                    -- Encode tables as json so we can log them
                    args[i] = json.encode(args[i])
                end
            end

            message = sformat(message, unpack(args))
        end
        print(sformat('%s [%s] %-7s %s', date(timeFormat), self._name, levelNameMap[level], message))
        io.output():flush()
    end
end

function ns.Logger:info(message, ...)
    if STRICT then checkself(self, 'Logger:info') end
    return self:log(INFO, message, ...)
end

function ns.Logger:error(message, ...)
    if STRICT then checkself(self, 'Logger:error') end
    return self:log(ERROR, message, ...)
end

function ns.Logger:debug(message, ...)
    if STRICT then checkself(self, 'Logger:debug') end
    return self:log(DEBUG, message, ...)
end

function ns.Logger:verbose(message, ...)
    if STRICT then checkself(self, 'Logger:verbose') end
    return self:log(VERBOSE, message, ...)
end

function ns.Logger:warn(message, ...)
    if STRICT then checkself(self, 'Logger:warn') end
    return self:log(WARNING, message, ...)
end

function ns.Logger:critical(message, ...)
    if STRICT then checkself(self, 'Logger:critical') end
    return self:log(CRITICAL, message, ...)
end

local loggers = {
    [ROOT_NAME] = ns.Logger:new(ROOT_NAME, INFO)
}

function ns.getLogger(name)
    if not name then
        name = ROOT_NAME
    end

    if not loggers[name] then
        local mods = split(name)
        local parent = loggers[ROOT_NAME]
        local parentName = ''

        for i = 1, #mods do
            local mname = parentName .. mods[i]
            loggers[mname] = ns.Logger:new(mname, NOTSET, parent)
            parentName = mname .. '.'
            parent = loggers[mname]
        end
    end

    return loggers[name]
end

return ns