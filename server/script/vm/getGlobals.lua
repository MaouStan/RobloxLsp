---@type vm
local config      = require 'config'
local defaultlibs = require 'library.defaultlibs'
local furi        = require 'file-uri'
local files       = require 'files'
local fs          = require 'bee.filesystem'
local guide       = require 'core.guide'
local rbxlibs     = require 'library.rbxlibs'
local rojo        = require 'library.rojo'
local util        = require 'utility'
local workspace   = require 'workspace.workspace'
local vm          = require 'vm.vm'
local log         = require 'log'
local debugLog    = require 'debug'

-- Startup log to verify this file is loaded
log.info('[@import] getGlobals.lua loaded - import feature initialized')

-- Safe debug logging wrapper - always logs for debugging
local function logImport(...)
    local args = {...}
    local parts = {'[@import]'}
    for i = 1, #args do
        parts[i+1] = tostring(args[i])
    end
    local msg = table.concat(parts, ' ')
    log.info(msg)  -- Always log, regardless of debug settings
end

-- LRU Cache for imported globals with size limit
local importCache = {}
local cacheOrder = {}
local CACHE_SIZE_LIMIT = 100

--- Add to LRU cache with eviction
local function addToCache(uri, globals)
    -- Remove oldest if at limit
    if #cacheOrder >= CACHE_SIZE_LIMIT then
        local oldest = table.remove(cacheOrder, 1)
        importCache[oldest] = nil
    end

    -- Update position if already exists
    for i, cachedUri in ipairs(cacheOrder) do
        if cachedUri == uri then
            table.remove(cacheOrder, i)
            break
        end
    end

    importCache[uri] = globals
    table.insert(cacheOrder, uri)
end

--- Clear cache for a specific URI or all cache
local function clearImportCache(uri)
    if uri then
        importCache[uri] = nil
        for i, cachedUri in ipairs(cacheOrder) do
            if cachedUri == uri then
                table.remove(cacheOrder, i)
                break
            end
        end
    else
        importCache = {}
        cacheOrder = {}
    end
end

--- Invalidate cache when files change (hook into file watch)
local function onFileChanged(uri)
    clearImportCache(uri)
end

--- Normalize path and resolve parent directory references safely
---@param pathStr string The path string to normalize
---@return string normalizedPath The normalized absolute path
local function normalizePathSafe(pathStr)
    local p = fs.path(pathStr)
    -- Use filesystem's canonical to resolve .. and . safely
    if p and fs.exists(p) then
        local canonical = p:string()
        return workspace.normalize(canonical)
    end
    return workspace.normalize(pathStr)
end

--- Resolve import path relative to the current file
---@param uri string The current file URI
---@param importPath string The import path from @import annotation
---@return string|nil resolvedUri The resolved URI or nil if not found
local function resolveImportPath(uri, importPath)
    logImport('[@import] resolveImportPath: uri=', uri, 'importPath=', importPath)
    if not uri or not importPath or importPath == "" then
        logImport('[@import] resolveImportPath: nil uri or empty path')
        return nil
    end

    local currentPath = furi.decode(uri)
    local currentDir = fs.path(currentPath):parent_path()
    local basePath = currentDir
    logImport('[@import] resolveImportPath: currentPath=', currentPath, 'currentDir=', currentDir:string())

    -- Check for workspace root import (TypeScript-style: "/Core/Utils")
    if importPath:match("^[/\\]") then
        -- Use workspace root as base
        if workspace.path and workspace.path ~= "" then
            basePath = fs.path(workspace.path)
            -- Remove leading slash from importPath
            importPath = importPath:sub(2)
        else
            log.warn('Workspace root not found for absolute import:', importPath)
            return nil
        end
    end

    -- Construct the full path to the imported file
    local importFullPath = basePath / importPath

    -- Normalize path to resolve .. and . (safe path traversal)
    local normalizedPath = normalizePathSafe(importFullPath:string())

    -- Security check: ensure resolved path is within workspace
    if workspace.path and workspace.path ~= "" then
        local workspaceAbs = normalizePathSafe(workspace.path)
        local normalizedAbs = normalizePathSafe(normalizedPath)
        -- Check if normalized path starts with workspace path
        if normalizedAbs:lower():sub(1, #workspaceAbs:lower()) ~= workspaceAbs:lower() then
            log.warn('Import path escapes workspace:', importPath, '->', normalizedPath)
            return nil
        end
    end

    -- Check if the file exists
    if not fs.exists(fs.path(normalizedPath)) then
        -- Try adding .lua extension
        local withLua = basePath / (importPath .. ".lua")
        normalizedPath = normalizePathSafe(withLua:string())
        if not fs.exists(fs.path(normalizedPath)) then
            -- Try adding .luau extension
            local withLuau = basePath / (importPath .. ".luau")
            normalizedPath = normalizePathSafe(withLuau:string())
            if not fs.exists(fs.path(normalizedPath)) then
                return nil
            end
        end
    end

    -- Convert back to URI
    local resultUri = furi.encode(normalizedPath)
    logImport('[@import] resolveImportPath: RESULT=', resultUri)
    return resultUri
end

--- Load globals from an imported file with error handling
---@param importUri string The URI of the imported file
---@param mark table Mark table to prevent duplicates
---@return table|nil globals Array of global definitions or nil on failure
local function loadImportedGlobals(importUri, mark)
    logImport('[@import] loadImportedGlobals: importUri=', importUri)
    -- Check cache first
    if importCache[importUri] then
        logImport('[@import] loadImportedGlobals: CACHE HIT, globals=', #importCache[importUri])
        return importCache[importUri]
    end

    -- Use pcall for error handling
    local success, result = pcall(function()
        local importAst = files.getAst(importUri)
        local importDocs = importAst and (importAst.docs or (importAst.ast and importAst.ast.docs))
        logImport('[@import] loadImportedGlobals: importAst=', importAst and 'exists' or 'nil')
        if importAst then
            logImport('[@import] loadImportedGlobals: importAst.ast=', importAst.ast and 'exists' or 'nil', 'importAst.docs=', importAst.docs and 'exists (' .. #importAst.docs .. ')' or 'nil', 'importAst.ast.docs=', importAst.ast and importAst.ast.docs and 'exists (' .. #importAst.ast.docs .. ')' or 'nil')
        end
        if importAst and importAst.ast then
            local importGlobals = guide.findGlobals(importAst.ast)
            logImport('[@import] loadImportedGlobals: found', #importGlobals, 'globals in imported file')
            local cached = {}
            for _, global in ipairs(importGlobals) do
                if not mark[global] then
                    cached[#cached+1] = global
                    mark[global] = true
                end
            end
            return cached
        end
        return {}
    end)

    if not success then
        log.warn('Failed to parse imported file:', importUri, result)
        addToCache(importUri, {})
        return nil
    end

    addToCache(importUri, result)
    return result
end

--- Get globals from imported files via @import annotations
---@param uri string The current file URI
---@param ast table The AST of the current file
---@param visited table Table to track visited URIs and prevent circular imports
---@return table importedGlobals Array of imported global definitions
local function getImportedGlobals(uri, ast, visited)
    local docs = ast and (ast.docs or (ast.ast and ast.ast.docs))
    logImport('[@import] getImportedGlobals: uri=', uri, 'ast=', ast and 'exists' or 'nil', 'ast.docs=', ast and ast.docs and 'exists (' .. #ast.docs .. ')' or 'nil', 'ast.ast.docs=', ast and ast.ast and ast.ast.docs and 'exists (' .. #ast.ast.docs .. ')' or 'nil')
    visited = visited or {}
    if visited[uri] then
        logImport('[@import] getImportedGlobals: CIRCULAR IMPORT detected for', uri)
        return {}  -- Circular import detected, stop recursion
    end
    visited[uri] = true

    local imported = {}
    local mark = {}

    if not ast or not docs then
        logImport('[@import] getImportedGlobals: NO DOCS, returning empty')
        return imported
    end

    logImport('[@import] getImportedGlobals: scanning', #docs, 'docs')
    -- Scan for @import annotations
    for _, doc in ipairs(docs) do
        if doc.type == 'doc.import' and doc.path and doc.path ~= "" then
            local importUri = resolveImportPath(uri, doc.path)
            if importUri and files.exists(importUri) then
                -- Load globals from imported file (with circular import protection)
                local globals = loadImportedGlobals(importUri, mark)
                if globals then
                    for _, global in ipairs(globals) do
                        if not mark[global] then
                            imported[#imported+1] = global
                            mark[global] = true
                        end
                    end
                end
            end
        end
    end

    logImport('[@import] getImportedGlobals: returning', #imported, 'imported globals')
    return imported
end

--- Detect loadstring(readfile("..."))() pattern and extract import paths
---@param ast table The AST of the current file
---@return table paths Array of detected file paths
local function detectLoadstringImports(ast)
    local paths = {}

    if not ast or not ast.ast then
        return paths
    end

    -- Look for patterns like: local XXX = loadstring(readfile("path"))()
    guide.eachSource(ast.ast, function (source)
        if source.type == 'local' then
            -- Check if this is a local variable declaration
            local value = source.value
            if not value then
                return
            end

            -- Pattern: loadstring(readfile("path"))()
            -- The AST structure is:
            -- local
            --   value: call
            --     func: call
            --       func: (getglobal 'loadstring')
            --       args: call
            --         func: (getglobal 'readfile')
            --         args: (string "path")

            if value.type == 'call' then
                local outerCall = value
                local innerCall = outerCall.node

                if innerCall and innerCall.type == 'call' then
                    local loadstringCall = innerCall
                    local loadstringFunc = loadstringCall.node

                    -- Check if this is calling loadstring
                    if loadstringFunc and loadstringFunc.type == 'getglobal'
                    and loadstringFunc[1] == 'loadstring' then
                        -- Check if loadstring's argument is readfile("path")
                        local readfileCall = loadstringCall.args and loadstringCall.args[1]
                        if readfileCall and readfileCall.type == 'call' then
                            local readfileFunc = readfileCall.node
                            if readfileFunc and readfileFunc.type == 'getglobal'
                            and readfileFunc[1] == 'readfile' then
                                -- Extract the file path from readfile's argument
                                local pathArg = readfileCall.args and readfileCall.args[1]
                                if pathArg and pathArg.type == 'string' then
                                    paths[#paths+1] = pathArg[1]
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    return paths
end

--- Get globals from loadstring(readfile(...))() patterns
---@param uri string The current file URI
---@param ast table The AST of the current file
---@param visited table Table to track visited URIs and prevent circular imports
---@return table importedGlobals Array of imported global definitions
local function getLoadstringImports(uri, ast, visited)
    visited = visited or {}
    if visited[uri] then
        return {}  -- Circular import detected
    end
    visited[uri] = true

    local imported = {}
    local mark = {}

    if not ast then
        return imported
    end

    -- Detect loadstring patterns
    local paths = detectLoadstringImports(ast)

    for _, path in ipairs(paths) do
        local importUri = resolveImportPath(uri, path)
        if importUri and files.exists(importUri) then
            -- Load globals from imported file (with circular import protection)
            local globals = loadImportedGlobals(importUri, mark)
            if globals then
                for _, global in ipairs(globals) do
                    if not mark[global] then
                        imported[#imported+1] = global
                        mark[global] = true
                    end
                end
            end
        end
    end

    return imported
end

--- Get all global variables matching the given key
---@param key string|nil The global variable name or "*" for all
---@param uri string|nil The file URI for context-specific globals (e.g., "script")
---@param onlySet boolean|nil If true, only return globals that have been set/defined
---@return table globals Array of global variable definitions
function vm.getGlobals(key, uri, onlySet)
    -- Log every call to getGlobals for debugging
    log.info('[@import] getGlobals called: key=', key or 'nil', 'uri=', uri or 'nil', 'onlySet=', onlySet or 'nil')

    local globals = {}
    local scriptCache = vm.getCache 'scriptCache'
    for _, lib in pairs(rbxlibs.global) do
        if key == "*" or lib.name == key then
            if lib.name == "script" and uri then
                if not scriptCache[uri] then
                    local script = util.shallowCopy(lib)
                    local scriptValue = rojo.Scripts[uri]
                    if scriptValue then
                        script.value = scriptValue
                    else
                        script.value[1] = rojo:scriptClass(uri)
                    end
                    scriptCache[uri] = script
                end
                globals[#globals+1] = scriptCache[uri]
            else
                globals[#globals+1] = lib
            end
        end
    end
    local dummyCache = vm.getCache 'globalDummy'
    for name in pairs(config.config.diagnostics.globals) do
        if key == '*' or name == key then
            if not dummyCache[key] then
                dummyCache[key] = {
                    type   = 'dummy',
                    start  = 0,
                    finish = 0,
                    [1]    = key
                }
            end
            globals[#globals+1] = dummyCache[key]
        end
    end
    if not uri or not files.exists(uri) then
        return globals
    end
    local ast = files.getAst(uri)
    if not ast then
        return globals
    end
    local fileGlobals = guide.findGlobals(ast.ast)
    local mark = {}

    -- Track visited URIs to prevent circular imports
    local visited = {}

    -- Process @import annotations and create virtual globals for import aliases
    local importAliasCache = vm.getCache 'importAliasCache'
    if not importAliasCache[uri] then
        importAliasCache[uri] = {}
    end
    -- Check if we need to process docs for this URI
    -- Use a separate flag to track if docs have been processed
    local docsProcessedKey = uri .. '_docsProcessed'
    if not importAliasCache[docsProcessedKey] then
        -- Docs can be in ast.docs or ast.ast.docs depending on parser implementation
        local docs = ast.docs or (ast.ast and ast.ast.docs)
        if docs and #docs > 0 then
            logImport('Processing docs for URI:', uri, 'doc count:', #docs, 'key:', key, 'location:', ast.docs and 'ast.docs' or 'ast.ast.docs')
            for _, doc in ipairs(docs) do
                logImport('Doc type:', doc.type, 'path:[' .. (doc.path or 'nil') .. ']', 'alias:', doc.alias, 'start:', doc.start)
                if doc.type == 'doc.import' and doc.alias and doc.alias ~= "" then
                    importAliasCache[uri][doc.alias] = doc
                    logImport('Registered import alias:', doc.alias, '->[' .. doc.path .. ']', 'for key:', key)
                end
            end
        else
            logImport('No docs found for URI:', uri, 'ast.docs:', ast and ast.docs or 'nil', 'ast.ast.docs:', ast and ast.ast and ast.ast.docs or 'nil')
        end
        importAliasCache[docsProcessedKey] = true
    end

    -- Debug: log what's in the cache
    if key ~= "*" and importAliasCache[uri] and importAliasCache[uri][key] then
        logImport('Found import alias in cache:', key, 'path:', importAliasCache[uri][key].path)
    end

    -- Add virtual globals for import aliases
    local foundImportAlias = false
    logImport('Checking import alias cache for key:', key, 'uri:', uri, 'cache exists:', importAliasCache[uri] ~= nil)
    if importAliasCache[uri] then
        for alias, importDoc in pairs(importAliasCache[uri]) do
            logImport('  Checking alias:', alias, 'against key:', key, 'match:', key == "*" or key == alias)
        end
    end
    for alias, importDoc in pairs(importAliasCache[uri] or {}) do
        if key == "*" or key == alias then
            -- Create a virtual global representing the imported module
            foundImportAlias = true
            local virtualGlobal = {
                type = 'global',
                special = 'import',
                name = alias,
                start = importDoc.start,
                finish = importDoc.finish,
                [1] = alias,
                importDoc = importDoc,
                uri = uri,
            }
            globals[#globals+1] = virtualGlobal
            mark[virtualGlobal] = true
            logImport('Created virtual global:', alias, 'for key:', key, 'path:', importDoc.path, 'onlySet:', onlySet)
        end
    end
    if not foundImportAlias and key ~= "*" and importAliasCache[uri] then
        logImport('WARNING: No import alias found for key:', key, 'in URI:', uri)
        for alias, doc in pairs(importAliasCache[uri]) do
            logImport('  Cache has alias:', alias, 'path:', doc.path)
        end
    end

    -- Add globals from imported files (for non-alias imports, existing behavior)
    local importedGlobals = getImportedGlobals(uri, ast, visited)
    for _, res in ipairs(importedGlobals) do
        if not mark[res] then
            mark[res] = true
            if key == "*" or guide.getSimpleName(res) == key then
                globals[#globals+1] = res
            end
        end
    end

    -- Add globals from loadstring(readfile(...))() patterns
    local loadstringGlobals = getLoadstringImports(uri, ast, visited)
    for _, res in ipairs(loadstringGlobals) do
        if not mark[res] then
            mark[res] = true
            if key == "*" or guide.getSimpleName(res) == key then
                globals[#globals+1] = res
            end
        end
    end

    for _, res in ipairs(fileGlobals) do
        if mark[res] then
            goto CONTINUE
        end
        if not onlySet or vm.isSet(res) then
            mark[res] = true
            if key == "*" or guide.getSimpleName(res) == key then
                globals[#globals+1] = res
            end
        end
        ::CONTINUE::
    end
    if uri:match("%.spec%.lua[u]?$") or uri:match("%.spec%/init%.lua[u]?$") then
        for _, lib in pairs(defaultlibs.testez) do
            if key == "*" or lib.name == key then
                globals[#globals+1] = lib
            end
        end
    end
    return globals
end

--- Get global variables that have been set/defined
---@param key string|nil The global variable name or "*" for all
---@param uri string|nil The file URI for context-specific globals
---@return table globals Array of defined global variable definitions
function vm.getGlobalSets(key, uri)
    return vm.getGlobals(key, uri, true)
end

--- Get the exported return value from an imported file via @import annotation
---@param source table The source (e.g., local variable) to check for import binding
---@return table|nil fields Array of field definitions from the imported file's return value
function vm.getImportedExports(source)
    logImport('getImportedExports: CALLED with source type:', source and source.type or 'nil', 'name:', source and (source[1] or source.name) or 'nil')
    if not source then
        logImport('getImportedExports: source is nil')
        return nil
    end

    local importDoc
    local uri

    -- Case 1: Source is a virtual global with importDoc attached
    if source.special == 'import' and source.importDoc then
        importDoc = source.importDoc
        uri = source.uri
        logImport('getImportedExports: virtual import global, uri:', uri, 'path:', importDoc.path)
    -- Case 2: Source has a bindGroup with doc.import
    elseif source.bindGroup then
        for _, doc in ipairs(source.bindGroup) do
            if doc.type == 'doc.import' and doc.path and doc.path ~= "" then
                importDoc = doc
                break
            end
        end
        uri = guide.getUri(source)
        if debugLog and logImport then
            logImport('getImportedExports: bindGroup found, uri:', uri, 'hasDoc:', importDoc ~= nil)
        end
    -- Case 3: Source is a getglobal that might be an import alias
    elseif source.type == 'getglobal' or source.type == 'setglobal' then
        uri = guide.getUri(source)
        local name = source[1] or source.name
        logImport('getImportedExports: getglobal/setglobal, name:', name, 'uri:', uri)
        if name and uri then
            local importAliasCache = vm.getCache 'importAliasCache'
            importDoc = importAliasCache[uri] and importAliasCache[uri][name]
            if debugLog and logImport then
                logImport('getImportedExports: importDoc from cache:', importDoc ~= nil)
            end
        end
    else
        if debugLog and logImport then
            logImport('getImportedExports: unknown source type:', source.type)
        end
    end

    if not importDoc or not importDoc.path or importDoc.path == "" then
        logImport('getImportedExports: no valid importDoc')
        return nil
    end

    if not uri then
        logImport('getImportedExports: no uri')
        return nil
    end

    -- Resolve the import path
    local importUri = resolveImportPath(uri, importDoc.path)
    logImport('getImportedExports: resolved importUri:', importUri)

    if not importUri then
        logImport('getImportedExports: failed to resolve import path')
        return nil
    end

    -- Check if file exists in LSP file map or on actual filesystem
    local inFileMap = files.exists(importUri)
    if not inFileMap then
        -- Decode URI to file path and check actual filesystem
        local importPath = furi.decode(importUri)
        local existsOnDisk = fs.exists(fs.path(importPath))
        logImport('getImportedExports: file not in LSP map, on disk:', existsOnDisk, 'path:', importPath)
        if not existsOnDisk then
            logImport('getImportedExports: import file does not exist (not in map or on disk)')
            return nil
        end
    end

    -- Get the AST of the imported file
    local importAst = files.getAst(importUri)
    if not importAst or not importAst.ast then
        -- If file exists on disk but not in LSP map, add it using setText
        if not inFileMap then
            local importPath = furi.decode(importUri)
            local f = io.open(importPath, 'r')
            if f then
                local content = f:read('*a')
                f:close()
                logImport('getImportedExports: reading file from disk:', importPath, 'size:', #content)
                -- Use setText to properly add file to LSP file map
                files.setText(importUri, content, true)
                -- Now get the AST (should be compiled now)
                importAst = files.getAst(importUri)
            end
        end
        if not importAst or not importAst.ast then
            logImport('getImportedExports: no AST for imported file')
            return nil
        end
    end

    -- Find the return statement in the main block
    local returns = {}
    local mark = {}

    logImport('getImportedExports: searching for return statements in AST')
    guide.eachSourceType(importAst.ast, 'return', function (ret)
        logImport('getImportedExports: found return statement at', ret.start, 'with', #ret, 'expressions')
        for i, exp in ipairs(ret) do
            logImport('getImportedExports:   exp['..i..'] type:', exp.type, 'name:', exp.name or exp[1] or '?')
            -- If the return is a local variable, get its fields
            if exp.type == 'local' then
                -- Get fields from the local variable's value
                logImport('getImportedExports:   return is local, getting fields')
                local fields = vm.getFields(exp, 0, {onlyDef = true})
                logImport('getImportedExports:   got', #fields, 'fields from local')
                for _, field in ipairs(fields) do
                    if not mark[field] then
                        local fname = field[1] or field.name or field.type or '?'
                        logImport('getImportedExports:     adding field:', fname)
                        returns[#returns+1] = field
                        mark[field] = true
                    end
                end
            elseif exp.type == 'getlocal' then
                -- Follow the local to its definition
                logImport('getImportedExports:   return is getlocal, following to definition')
                local defs = vm.getDefs(exp, 0)
                for _, def in ipairs(defs) do
                    if def.type == 'local' then
                        local fields = vm.getFields(def, 0, {onlyDef = true})
                        for _, field in ipairs(fields) do
                            if not mark[field] then
                                local fname = field[1] or field.name or field.type or '?'
                                logImport('getImportedExports:     adding field:', fname)
                                returns[#returns+1] = field
                                mark[field] = true
                            end
                        end
                    end
                end
            else
                -- For other expression types, try to get fields
                logImport('getImportedExports:   return is', exp.type, ', getting fields')
                local fields = vm.getFields(exp, 0, {onlyDef = true})
                logImport('getImportedExports:   got', #fields, 'fields from', exp.type)
                for _, field in ipairs(fields) do
                    if not mark[field] then
                        local fname = field[1] or field.name or field.type or '?'
                        logImport('getImportedExports:     adding field:', fname)
                        returns[#returns+1] = field
                        mark[field] = true
                    end
                end
            end
        end
    end)

    logImport('getImportedExports: found', #returns, 'exported fields')
    for i, field in ipairs(returns) do
        local name = field[1] or field.name or field.type or '?'
        logImport('  export', i, ':', name)
    end

    return #returns > 0 and returns or nil
end

--- Clear the import cache for a specific URI or all caches
---@param uri string|nil The file URI to clear, or nil to clear all
function vm.clearImportCache(uri)
    clearImportCache(uri)
end

--- Notify that a file has changed (invalidates import cache)
---@param uri string The file URI that changed
function vm.onFileChanged(uri)
    onFileChanged(uri)
end
