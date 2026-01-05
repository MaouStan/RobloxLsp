local files   = require 'files'
local vm      = require 'vm'
local lang    = require 'language'
local config  = require 'config'
local guide   = require 'core.guide'
local debugLog = require 'debug'
local log     = require 'log'

-- Startup log to verify this diagnostic is loaded
log.info('[@import] undefined-global.lua loaded')

local function check(src, uri, callback)
    local key = guide.getKeyName(src)
    if not key then
        return
    end
    -- Log when checking for undefined global
    log.info('[@import] undefined-global checking: key=', key, 'uri=', uri)

    if config.config.diagnostics.globals[key] then
        return
    end
    local globals = vm.getGlobalSets(key, uri)
    log.info('[@import] undefined-global result: key=', key, 'globals count=', #globals)

    -- Debug: log if this is an import alias
    local importAliasCache = vm.getCache 'importAliasCache'
    local isImportAlias = importAliasCache and importAliasCache[uri] and importAliasCache[uri][key] ~= nil
    log.info('[@import] importAliasCache exists:', importAliasCache ~= nil, 'uri cache:', importAliasCache and importAliasCache[uri] ~= nil, 'isImportAlias:', isImportAlias)

    for i = 1, #globals do
        if globals[i] == src then
            globals[i] = globals[#globals]
            globals[#globals] = nil
        end
    end
    if #globals == 0 then
        log.info('[@import] Reporting undefined global for: key=', key)
        callback {
            start   = src.start,
            finish  = src.finish,
            message = lang.script('DIAG_UNDEF_GLOBAL', key),
        }
        return
    end
end

return function (uri, callback)
    local ast = files.getAst(uri)
    if not ast then
        return
    end

    guide.eachSourceType(ast.ast, 'getglobal', function (src)
        check(src, uri, callback)
    end)

    guide.eachSourceType(ast.ast, 'setglobal', function (src)
        if guide.getParentFunction(src) ~= guide.getRoot(src) then
            check(src, uri, callback)
        end
    end)
end
