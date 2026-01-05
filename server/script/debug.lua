--[[
    Debug Logging Module
    Provides configurable debug logging for the LSP server

    Usage:
    local debug = require 'debug'
    debug.log('import', 'Processing import:', path)
    debug.log('completion', 'Found', count, 'items')
]]

local config  = require 'config'
local util    = require 'utility'
local fs      = require 'bee.filesystem'
local await   = require 'await'
local log     = require 'log'

local m = {}

-- Log levels
local LOG_LEVELS = {
    trace = 0,
    debug = 1,
    info  = 2,
    warn  = 3,
    error = 4,
}

-- Current log level (cached from config)
local currentLogLevel = 'debug'

-- Log file handle
local logFile = nil
local logFilePath = nil

-- Update configuration from config module
local function updateConfig()
    local cfg = config.get(nil, 'debug')
    if not cfg then
        return
    end

    currentLogLevel = cfg.logLevel or 'debug'

    -- Handle log file
    local newLogFilePath = cfg.logFile or ''
    if newLogFilePath ~= logFilePath then
        -- Close old log file if open
        if logFile then
            logFile:close()
            logFile = nil
        end
        logFilePath = newLogFilePath

        -- Open new log file if specified
        if logFilePath ~= '' then
            local path = fs.path(logFilePath)
            local parent = path:parent_path()
            if not fs.exists(parent) then
                fs.create_directories(parent)
            end
            logFile = io.open(logFilePath, 'a')
        end
    end
end

-- Check if a category is enabled
local function isCategoryEnabled(category)
    local cfg = config.get(nil, 'debug')
    if not cfg or not cfg.enable then
        return false
    end

    local categories = cfg.categories or {}
    for _, cat in ipairs(categories) do
        if cat == 'all' or cat == category then
            return true
        end
    end
    return false
end

-- Core logging function
local function logRaw(level, category, ...)
    local cfg = config.get(nil, 'debug')
    if not cfg or not cfg.enable then
        return
    end

    -- Check log level
    local levelNum = LOG_LEVELS[level] or 1
    local configLevelNum = LOG_LEVELS[currentLogLevel] or 1
    if levelNum < configLevelNum then
        return
    end

    -- Check category
    if not isCategoryEnabled(category) then
        return
    end

    -- Format message
    local args = {...}
    local parts = {}
    for i = 1, #args do
        parts[i] = tostring(args[i])
    end
    local message = table.concat(parts, ' ')

    -- Add prefix
    local timestamp = os.date('%H:%M:%S')
    local prefix = string.format('[%s] [%s] [%-8s] ', timestamp, level, category)
    local fullMessage = prefix .. message

    -- Log to console
    log.debug(fullMessage)

    -- Log to file if configured
    if logFile then
        logFile:write(fullMessage .. '\n')
        logFile:flush()
    end
end

-- Public API
function m.trace(category, ...)
    logRaw('trace', category, ...)
end

function m.debug(category, ...)
    logRaw('debug', category, ...)
end

function m.info(category, ...)
    logRaw('info', category, ...)
end

function m.warn(category, ...)
    logRaw('warn', category, ...)
end

function m.error(category, ...)
    logRaw('error', category, ...)
end

-- Convenience function for @import logging
function m.import(...)
    if isCategoryEnabled('import') then
        m.debug('import', ...)
    end
end

-- Convenience function for completion logging
function m.completion(...)
    if isCategoryEnabled('completion') then
        m.debug('completion', ...)
    end
end

-- Convenience function for diagnostics logging
function m.diagnostics(...)
    if isCategoryEnabled('diagnostics') then
        m.debug('diagnostics', ...)
    end
end

-- Update config when settings change
function m.updateConfig()
    updateConfig()
end

-- Close log file on shutdown
function m.close()
    if logFile then
        logFile:close()
        logFile = nil
    end
end

return m
