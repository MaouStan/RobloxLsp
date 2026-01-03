# Work In Progress

**Saved**: 2026-01-03
**Session**: Variable Import via @import Annotation

## Current Task
Implement variable import feature for Roblox LSP extension - allows importing variables from external files using `---@import` annotation or auto-detecting `loadstring(readfile(...))()` pattern.

## Progress

### Completed
- [x] **Task 1**: Add `@import` annotation parser to luadoc.lua
  - Added `parseImport()` function
  - Registered in `convertTokens()`
  - Supports both `"path"` and `'path'` syntax

- [x] **Task 2**: Store import annotations in AST binding
  - Handled by existing `bindDocs()` function

- [x] **Task 3**: Implement import resolution in getGlobals.lua
  - Added `resolveImportPath()` - resolves relative paths
  - Added `getImportedGlobals()` - extracts globals from @import
  - Modified `vm.getGlobals()` to include imported globals

- [x] **Task 4**: Handle loadstring() pattern detection
  - Added `detectLoadstringImports()` - finds loadstring(readfile(...))() patterns
  - Added `getLoadstringImports()` - extracts globals from those patterns

- [x] **Task 5**: Update undefined-global diagnostic
  - Automatically handled - uses `vm.getGlobalSets()` which now includes imports

## Next Steps
1. **Test the build** - Ensure no syntax errors
2. **Commit changes** - Push to repository
3. **Test with Example folder** - Verify it works with `./Example/main.luau`
4. **Update README** - Document the new `@import` feature

## Important Context
- **Repository**: MaouStan/RobloxLsp (forked from NightrainsRbx/RobloxLsp)
- **Issue**: #1 - "Plan: Variable Import via @import Annotation"
- **Remote**: `origin` = MaouStan/RobloxLsp (your fork)
- **Branch**: master

## Files Modified
- `server/script/parser/luadoc.lua` - Added `parseImport()` function (lines ~1025-1048)
- `server/script/vm/getGlobals.lua` - Added:
  - `resolveImportPath()` - resolve relative file paths
  - `getImportedGlobals()` - extract globals from @import annotations
  - `detectLoadstringImports()` - find loadstring patterns
  - `getLoadstringImports()` - extract globals from loadstring patterns
  - Modified `vm.getGlobals()` to include imported globals

## Example Usage

```lua
---@import "Utils/ScriptLoader/init.luau"
local GG = loadstring(readfile("Utils/ScriptLoader/init.luau"))()

print(GG.selff)  -- No "undefined global" diagnostic
```

Auto-detection also works:
```lua
local ScriptLoader = loadstring(readfile("Utils/ScriptLoader/init.luau"))()
-- Variables from init.luau are automatically recognized
```

## Oracle Framework
- Installed: `/awaken` - Oracle commands, agents, skills
- Commands: trace, recap, rrr, snapshot, forward, wip, standup, now, hours, jump, pending
- Use `/recap` at start of next session to restore context
