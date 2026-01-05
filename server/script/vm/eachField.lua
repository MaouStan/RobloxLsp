---@type vm
local vm        = require 'vm.vm'
local guide     = require 'core.guide'
local await     = require 'await'
local config    = require 'config'
local debugLog  = require 'debug'
local log       = require 'log'

local function getFields(source, deep, filterKey, options)
    if debugLog and debugLog.import then
        debugLog.import('=== getFields called, source type:', source.type, 'source name:', source.name or source[1] or '?')
    end
    log.info('[@import] getFields: source type=', source.type, 'name=', source.name or source[1] or '?')
    local unlock = vm.lock('eachField', source)
    if not unlock then
        return {}
    end

    while source.type == 'paren' do
        source = source.exp
        if not source then
            return {}
        end
    end
    deep = config.config.intelliSense.searchDepth + (deep or 0)

    await.delay()
    local results = guide.requestFields(source, vm.interface, deep, filterKey, options)

    -- Check if this source or its definitions has an @import binding and add imported exports
    local importedExports = vm.getImportedExports(source)
    if not importedExports then
        -- Check definitions of this source (e.g., for getlocal, check the local declaration)
        local defs = vm.getDefs(source, 0, {onlyDef = true})
        for _, def in ipairs(defs) do
            importedExports = vm.getImportedExports(def)
            if importedExports then
                break
            end
        end
    end

    if importedExports then
        local mark = {}
        for _, result in ipairs(results) do
            mark[result] = true
        end
        for _, export in ipairs(importedExports) do
            if not mark[export] then
                -- Mark this field as coming from @import for priority sorting
                export.fromImport = true
                results[#results+1] = export
            end
        end
    end

    unlock()
    return results
end

local function getFieldsBySource(source, deep, filterKey, options)
    deep = deep or -999
    local cache = vm.getCache('eachField', options)[source]
    if not cache or cache.deep < deep then
        cache = getFields(source, deep, filterKey, options)
        cache.deep = deep
        if not filterKey then
            vm.getCache('eachField', options)[source] = cache
        end
    end
    return cache
end

function vm.getFields(source, deep, options)
    if source.special == '_G' then
        if options and options.onlyDef then
            return vm.getGlobalSets('*', guide.getUri(source))
        else
            return vm.getGlobals('*', guide.getUri(source))
        end
    end
    -- Handle virtual import globals (from @import with alias)
    if source.special == 'import' and source.importDoc then
        if debugLog and debugLog.completion then
            debugLog.completion('getFields: virtual import global, name:', source.name)
        end
        return vm.getImportedExports(source) or {}
    end
    if guide.isGlobal(source) then
        local name = guide.getKeyName(source)
        if not name then
            return {}
        end
        local uri = guide.getUri(source)
        log.info('[@import] getFields: global name=', name, 'uri=', uri, 'type=', source.type)

        -- Ensure import alias cache is initialized for this URI
        if uri and uri ~= '' then
            vm.getGlobals('*', uri)
        end

        local cache = vm.getCache('eachFieldOfGlobal', options)[name]
                    or getFieldsBySource(source, deep)
        vm.getCache('eachFieldOfGlobal', options)[name] = cache
        -- Check if this global is an import alias
        local importAliasCache = vm.getCache 'importAliasCache'
        local importDoc = importAliasCache[uri] and importAliasCache[uri][name]
        log.info('[@import] getFields: importDoc for [' .. name .. ']:', importDoc ~= nil, 'path=[' .. (importDoc and importDoc.path or 'nil') .. ']')
        if importDoc then
            log.info('[@import] getFields: calling getImportedExports for', name)
            local importedExports = vm.getImportedExports(source)
            if importedExports then
                log.info('[@import] getFields: got', #importedExports, 'imported exports for', name)
                if debugLog and debugLog.completion then
                    debugLog.completion('getFields: adding', #importedExports, 'imported exports for', name)
                end
                -- Merge with existing results
                local mark = {}
                for _, field in ipairs(cache) do
                    mark[field] = true
                end
                for _, export in ipairs(importedExports) do
                    if not mark[export] then
                        -- Mark this field as coming from @import for priority sorting
                        export.fromImport = true
                        cache[#cache+1] = export
                    end
                end
            else
                log.info('[@import] getFields: getImportedExports returned nil for', name)
            end
        else
            log.info('[@import] getFields: NO importDoc found for', name, 'in cache for uri:', uri)
        end
        return cache
    else
        return getFieldsBySource(source, deep, nil, options)
    end
end
