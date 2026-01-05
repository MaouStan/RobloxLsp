#!/usr/bin/env lua
--[[
    @import Feature Test Script
    Tests the @import annotation autocomplete functionality without VSCode

    Usage: lua test_import.lua
]]

-- Add server/script to package.path
local script_dir = arg[0]:match("^(.*)[\\/][^\\/]*$") or "."
package.path = script_dir .. "/server/script/?.lua;" .. package.path

-- Disable some internal logging for cleaner output
_G.DEVELOP = true
_G.log = {
    debug = function(...) print("[DEBUG]", ...) end,
    info = function(...) print("[INFO]", ...) end,
    warn = function(...) print("[WARN]", ...) end,
    error = function(...) print("[ERROR]", ...) end,
}

print("=" .. string.rep("=", 60))
print("  @import Feature Test Script")
print("=" .. string.rep("=", 60))
print()

-- Load required modules
local files = require 'files'
local vm = require 'vm.vm'
local guide = require 'core.guide'
local luadoc = require 'parser.luadoc'

-- Test files directory
local test_dir = script_dir .. "/Example"

-- Create test files
local function createTestFiles()
    -- Create lib1.lua
    local lib1_content = [[
local GG = {}

function GG.greet(name)
    return "Hello, " .. name .. "!"
end

function GG.farewell(name)
    return "Goodbye, " .. name .. "!"
end

return GG
]]

    -- Create main.lua with @import
    local main_content = [[
---@import "./lib1.lua" as lib1

lib1.g    -- Test completion here

---@import "./lib1.lua" as Utils
Utils.g  -- Test completion here too
]]

    print("[SETUP] Creating test files...")
    print()
    print("lib1.lua:")
    print(lib1_content)
    print()
    print("main.lua:")
    print(main_content)
    print()

    return lib1_content, main_content
end

-- Parse file content into AST
local function parseFile(uri, content)
    local textMode = require 'parser.text'
    local luaMode = require 'parser.lua'

    -- Create a simple text object
    local text = {
        uri = uri,
        content = content,
        get = function(self, offset, len)
            return self.content:sub(offset + 1, offset + len)
        end,
        len = function(self)
            return #self.content
        end
    }

    -- Parse Lua code
    local lua_result, lua_err = luaMode(text, 'Lua')
    if not lua_result then
        print("[ERROR] Failed to parse Lua:", lua_err)
        return nil
    end

    -- Parse LuaDoc comments
    local state, err = luadoc(text, lua_result.ast)
    if not state then
        print("[ERROR] Failed to parse LuaDoc:", err)
        return nil
    end

    return {
        uri = uri,
        ast = state,
        text = text
    }
end

-- Test @import parsing
local function testImportParsing(main_ast)
    print("[TEST 1] Testing @import annotation parsing...")
    print()

    if not main_ast.ast.docs then
        print("  ❌ FAILED: No docs found in AST")
        return false
    end

    print("  Found " .. #main_ast.ast.docs .. " doc annotations:")

    local found_import = false
    for i, doc in ipairs(main_ast.ast.docs) do
        print(string.format("    [%d] type: %s, path: %s, alias: %s",
            i, doc.type or "?", doc.path or "?", doc.alias or "?"))

        if doc.type == 'doc.import' then
            found_import = true
            if doc.path and doc.path ~= "" then
                print("        ✅ path parsed: " .. doc.path)
            else
                print("        ❌ path is missing!")
            end
            if doc.alias and doc.alias ~= "" then
                print("        ✅ alias parsed: " .. doc.alias)
            else
                print("        ❌ alias is missing!")
            end
        end
    end

    print()
    if found_import then
        print("  ✅ PASSED: @import annotations parsed correctly")
    else
        print("  ❌ FAILED: No @import annotations found")
    end
    print()

    return found_import
end

-- Test virtual global creation
local function testVirtualGlobals(uri, main_ast)
    print("[TEST 2] Testing virtual global creation...")
    print()

    -- Call vm.getGlobals to trigger virtual global creation
    local globals = vm.getGlobals('*', uri)

    if not globals then
        print("  ❌ FAILED: No globals returned")
        return false
    end

    print("  Found " .. #globals .. " globals (including Roblox globals)")

    -- Count import globals
    local import_globals = {}
    for _, g in ipairs(globals) do
        if g.special == 'import' then
            import_globals[g.name] = g
            print("    ✅ Import global: " .. g.name)
        end
    end

    print()
    if #import_globals > 0 then
        print("  ✅ PASSED: Virtual globals created (" .. #import_globals .. " imports)")
    else
        print("  ❌ FAILED: No import virtual globals found")
    end
    print()

    return #import_globals > 0
end

-- Test getFields for imported module
local function testGetFields(uri, main_ast)
    print("[TEST 3] Testing vm.getFields for imported module...")
    print()

    -- Create a mock getglobal source
    local mock_getglobal = {
        type = 'getglobal',
        [1] = 'lib1',
        uri = uri
    }

    print("  Calling vm.getFields for 'lib1'...")

    -- Get fields for lib1
    local fields = vm.getFields(mock_getglobal, 0)

    if not fields then
        print("  ❌ FAILED: No fields returned")
        return false
    end

    print("  Found " .. #fields .. " fields")

    -- Filter for our exports (greet, farewell)
    local exports = {}
    for _, field in ipairs(fields) do
        local name = field[1] or field.name
        if name and (name == 'greet' or name == 'farewell') then
            exports[name] = field
            print("    ✅ Found export: " .. name)
        end
    end

    print()
    if exports.greet and exports.farewell then
        print("  ✅ PASSED: All expected exports found")
        return true
    else
        print("  ❌ FAILED: Missing exports")
        print("    greet: " .. (exports.greet and "found" or "MISSING"))
        print("    farewell: " .. (exports.farewell and "found" or "MISSING"))
        return false
    end
end

-- Test getImportedExports directly
local function testGetImportedExports(uri, main_ast)
    print("[TEST 4] Testing vm.getImportedExports directly...")
    print()

    -- Create a mock source with import binding
    local mock_source = {
        type = 'getglobal',
        [1] = 'lib1',
        uri = uri
    }

    local exports = vm.getImportedExports(mock_source)

    if not exports then
        print("  ❌ FAILED: getImportedExports returned nil")
        return false
    end

    print("  Found " .. #exports .. " exported fields:")

    local found = {}
    for i, export in ipairs(exports) do
        local name = export[1] or export.name or export.type
        print(string.format("    [%d] %s", i, name))
        found[name] = true
    end

    print()
    if found.greet and found.farewell then
        print("  ✅ PASSED: All expected exports found")
        return true
    else
        print("  ❌ FAILED: Missing exports")
        print("    greet: " .. (found.greet and "found" or "MISSING"))
        print("    farewell: " .. (found.farewell and "found" or "MISSING"))
        return false
    end
end

-- Main test runner
local function runTests()
    -- Create test files
    local lib1_content, main_content = createTestFiles()

    -- Parse files
    print("[PARSING] Parsing test files...")
    print()

    local lib1_uri = test_dir .. "/lib1.lua"
    local main_uri = test_dir .. "/main.lua"

    -- Note: In a real scenario, files would be loaded from disk
    -- For this test, we're simulating the file system
    print("  lib1 URI: " .. lib1_uri)
    print("  main URI: " .. main_uri)
    print()

    -- Initialize files module with test data
    files.setText(lib1_uri, lib1_content)
    files.setText(main_uri, main_content)

    -- Parse main file
    local main_ast = parseFile(main_uri, main_content)
    if not main_ast then
        print("[FATAL] Failed to parse main.lua")
        return false
    end

    -- Parse lib1 file
    local lib1_ast = parseFile(lib1_uri, lib1_content)
    if not lib1_ast then
        print("[FATAL] Failed to parse lib1.lua")
        return false
    end

    print("  ✅ Both files parsed successfully")
    print()

    -- Run tests
    local results = {}

    results.parsing = testImportParsing(main_ast)
    results.globals = testVirtualGlobals(main_uri, main_ast)
    results.fields = testGetFields(main_uri, main_ast)
    results.exports = testGetImportedExports(main_uri, main_ast)

    -- Summary
    print("=" .. string.rep("=", 60))
    print("  TEST SUMMARY")
    print("=" .. string.rep("=", 60))
    print()

    local total = 0
    local passed = 0

    for name, result in pairs(results) do
        total = total + 1
        local status = result and "✅ PASSED" or "❌ FAILED"
        print("  " .. name .. ": " .. status)
        if result then passed = passed + 1 end
    end

    print()
    print("  Total: " .. passed .. "/" .. total .. " tests passed")
    print()

    if passed == total then
        print("  🎉 All tests passed!")
        return true
    else
        print("  ⚠️  Some tests failed")
        return false
    end
end

-- Run tests
local success = runTests()
os.exit(success and 0 or 1)
