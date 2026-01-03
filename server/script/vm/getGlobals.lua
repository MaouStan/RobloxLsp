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

-- Cache for imported globals
local importCache = {}

--- Resolve import path relative to the current file
---@param uri string The current file URI
---@param importPath string The import path from @import annotation
---@return string|nil resolvedUri The resolved URI or nil if not found
local function resolveImportPath(uri, importPath)
    if not uri or not importPath or importPath == "" then
        return nil
    end

    -- Decode current file URI to get the directory path
    local currentPath = furi.decode(uri)
    local currentDir = fs.path(currentPath):parent_path()

    -- Construct the full path to the imported file
    local importFullPath = currentDir / importPath
    local normalizedPath = workspace.normalize(importFullPath:string())

    -- Check if the file exists
    if not fs.exists(fs.path(normalizedPath)) then
        -- Try adding .lua extension
        importFullPath = currentDir / (importPath .. ".lua")
        normalizedPath = workspace.normalize(importFullPath:string())
        if not fs.exists(fs.path(normalizedPath)) then
            -- Try adding .luau extension
            importFullPath = currentDir / (importPath .. ".luau")
            normalizedPath = workspace.normalize(importFullPath:string())
            if not fs.exists(fs.path(normalizedPath)) then
                return nil
            end
        end
    end

    -- Convert back to URI
    return furi.encode(normalizedPath)
end

--- Get globals from imported files via @import annotations
---@param uri string The current file URI
---@param ast table The AST of the current file
---@return table importedGlobals Array of imported global definitions
local function getImportedGlobals(uri, ast)
    local imported = {}
    local mark = {}

    if not ast or not ast.docs then
        return imported
    end

    -- Scan for @import annotations
    for _, doc in ipairs(ast.docs) do
        if doc.type == 'doc.import' and doc.path and doc.path ~= "" then
            local importUri = resolveImportPath(uri, doc.path)
            if importUri and files.exists(importUri) then
                -- Check cache first
                if not importCache[importUri] then
                    local importAst = files.getAst(importUri)
                    if importAst and importAst.ast then
                        local importGlobals = guide.findGlobals(importAst.ast)
                        local cached = {}
                        for _, global in ipairs(importGlobals) do
                            if not mark[global] then
                                cached[#cached+1] = global
                                mark[global] = true
                            end
                        end
                        importCache[importUri] = cached
                    else
                        importCache[importUri] = {}
                    end
                end

                -- Add cached globals to result
                for _, global in ipairs(importCache[importUri]) do
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
---@return table importedGlobals Array of imported global definitions
local function getLoadstringImports(uri, ast)
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
            -- Check cache first
            if not importCache[importUri] then
                local importAst = files.getAst(importUri)
                if importAst and importAst.ast then
                    local importGlobals = guide.findGlobals(importAst.ast)
                    local cached = {}
                    for _, global in ipairs(importGlobals) do
                        if not mark[global] then
                            cached[#cached+1] = global
                            mark[global] = true
                        end
                    end
                    importCache[importUri] = cached
                else
                    importCache[importUri] = {}
                end
            end

            -- Add cached globals to result
            for _, global in ipairs(importCache[importUri]) do
                if not mark[global] then
                    imported[#imported+1] = global
                    mark[global] = true
                end
            end
        end
    end

    return imported
end

function vm.getGlobals(key, uri, onlySet)
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

    -- Add globals from imported files
    local importedGlobals = getImportedGlobals(uri, ast)
    for _, res in ipairs(importedGlobals) do
        if not mark[res] then
            mark[res] = true
            if key == "*" or guide.getSimpleName(res) == key then
                globals[#globals+1] = res
            end
        end
    end

    -- Add globals from loadstring(readfile(...))() patterns
    local loadstringGlobals = getLoadstringImports(uri, ast)
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

function vm.getGlobalSets(key, uri)
    return vm.getGlobals(key, uri, true)
end