--[[
    @import Example - demonstrates the @import annotation for IntelliSense
]]

---@import "D:/Code/RobloxLsp/Example/lib1.lua" as Utils

-- Test: Using Utils as a global (the import alias should provide IntelliSense)
Utils.greet("Test")
Utils.gre