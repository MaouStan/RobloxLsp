local files        = require 'files'
local workspace     = require 'workspace'
local lang          = require 'language'
local furi          = require 'file-uri'
local fs            = require 'bee.filesystem'
local guide         = require 'core.guide'

--- Check if an import path is valid
--- @param uri string The current file URI
--- @param importPath string The import path from @import annotation
--- @return boolean isValid True if the path resolves to an existing file
local function isValidImportPath(uri, importPath)
    if not uri or not importPath or importPath == "" then
        return false
    end

    local currentPath = furi.decode(uri)
    local currentDir = fs.path(currentPath):parent_path()
    local basePath = currentDir

    -- Check for workspace root import (starts with /)
    if importPath:match("^[/\\]") then
        if workspace.path and workspace.path ~= "" then
            basePath = fs.path(workspace.path)
            importPath = importPath:sub(2) -- Remove leading /
        else
            return false
        end
    end

    -- Try direct path
    local fullPath = basePath / importPath
    if fs.exists(fullPath) then
        return true
    end

    -- Try with .lua extension
    fullPath = basePath / (importPath .. ".lua")
    if fs.exists(fullPath) then
        return true
    end

    -- Try with .luau extension
    fullPath = basePath / (importPath .. ".luau")
    if fs.exists(fullPath) then
        return true
    end

    return false
end

return function (uri, callback)
    local state = files.getAst(uri)
    local docs = state and (state.docs or (state.ast and state.ast.docs))
    if not state or not docs then
        return
    end

    for _, doc in ipairs(docs) do
        if doc.type == 'doc.import' then
            if doc.path and doc.path ~= "" then
                if not isValidImportPath(uri, doc.path) then
                    local message = lang.script('DIAG_IMPORT_PATH_NOT_FOUND')
                    -- Fallback to English if translation not found
                    if message == 'DIAG_IMPORT_PATH_NOT_FOUND' then
                        message = string.format("Cannot find import file: '%s'", doc.path)
                    else
                        message = string.format(message, doc.path)
                    end
                    callback {
                        start   = doc.start,
                        finish  = doc.finish,
                        message = message
                    }
                end
            end
        end
    end
end
