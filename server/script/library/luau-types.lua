local json = require 'json'
local util = require 'utility'
local fs = require 'bee.filesystem'

local m = {}

-- Cache for parsed type definitions
local cachedTypes = nil
local cachedMetadata = nil

---Parse the METADATA header from globalTypes.d.luau
---Format: --#METADATA#{"KEY": ["value1", "value2"], ...}
local function parseMetadata(content)
    local metadataLine = content:match("^%-%-#METADATA#(%b{})")
    if not metadataLine then
        return nil
    end

    local success, metadata = pcall(json.decode, metadataLine)
    if success then
        return metadata
    end
    return nil
end

---Parse type alias definitions from globalTypes.d.luau
---Format: type TypeName = definition
local function parseTypeAliases(content)
    local types = {}
    for typeName, typeDef in content:gmatch('type%s+([%w_]+)%s*=%s*([^\n]*)') do
        types[typeName] = {
            name = typeName,
            definition = typeDef:gsub('%s*%-%-.*$', ''):gsub('%s+$', '') -- strip comments and trailing whitespace
        }
    end
    return types
end

---Parse declare class definitions
---Format: declare class ClassName extends BaseClass
local function parseDeclareClasses(content)
    local classes = {}
    -- Match declare class ClassName [extends BaseClass]
    for className, baseClass in content:gmatch('declare%s+class%s+([%w_]+)%s*(extends%s+([%w_]+))?') do
        classes[className] = {
            name = className,
            base = baseClass or "Instance"
        }
    end
    return classes
end

---Parse declare global tables/functions
---Format: declare Name: { ... }
local function parseDeclareGlobals(content)
    local globals = {}
    -- Match declare GlobalName: { ... }
    for globalName, signature in content:gmatch('declare%s+([%w_]+):%s*%{([^%}]*)%}') do
        globals[globalName] = {
            name = globalName,
            signature = signature
        }
    end
    return globals
end

---Load and parse globalTypes.d.luau from MaouData
---@return table|nil parsed - Parsed type definitions or nil if file not found
function m.loadGlobalTypes()
    if cachedTypes then
        return cachedTypes
    end

    local globalTypesPath = ROOT / "maou-data" / "globalTypes.d.luau"

    -- Check if file exists using fs.exists
    if not fs.exists(globalTypesPath) then
        return nil
    end

    -- Load file content safely
    local content = util.loadFile(globalTypesPath)
    if not content then
        return nil
    end

    -- Parse the file
    local types = {
        metadata = parseMetadata(content),
        typeAliases = parseTypeAliases(content),
        classes = parseDeclareClasses(content),
        globals = parseDeclareGlobals(content)
    }

    cachedTypes = types
    return types
end

---Get parsed metadata from globalTypes.d.luau
---@return table|nil metadata - Metadata table with CREATABLE_INSTANCES and SERVICES
function m.getMetadata()
    if cachedMetadata then
        return cachedMetadata
    end

    local types = m.loadGlobalTypes()
    if types and types.metadata then
        cachedMetadata = types.metadata
        return cachedMetadata
    end

    return nil
end

---Get creatable instances list from metadata
---@return table|nil instances - Array of creatable instance class names
function m.getCreatableInstances()
    local metadata = m.getMetadata()
    return metadata and metadata.CREATABLE_INSTANCES or nil
end

---Get services list from metadata
---@return table|nil services - Array of service class names
function m.getServices()
    local metadata = m.getMetadata()
    return metadata and metadata.SERVICES or nil
end

---Clear cached type definitions (useful for hot-reload)
function m.clearCache()
    cachedTypes = nil
    cachedMetadata = nil
end

return m
