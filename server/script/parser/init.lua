---@class parser
---@field grammar table Grammar parser
---@field parse function Parse Lua/Luau source code
---@field compile function Compile AST to bytecode
---@field split function Split code into tokens
---@field calcline function Calculate line positions
---@field lines table Line tracking utilities
---@field luadoc table LuaDoc annotation parser
local api = {
    grammar    = require 'parser.grammar',
    parse      = require 'parser.parse',
    compile    = require 'parser.compile',
    split      = require 'parser.split',
    calcline   = require 'parser.calcline',
    lines      = require 'parser.lines',
    luadoc     = require 'parser.luadoc',
}

return api
