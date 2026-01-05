# WIP — Monday 05 January 2026 [21:15]

## Git Status
```
M .claude/commands/jump.md
D .claude/scripts/jump.sh
D .claude/scripts/tracks.sh
D .gitignore
D .vscode/settings.json
D Example/init.luau
D Example/main.luau
M client/out/extension.js (compiled)
M client/src/extension.ts
M client/package.json
M package.json
M server/main.lua
M server/api/* (API definitions updated)
M server/script/**/* (many modifications)
?? psi/ (new - context tracking)
?? Example/lib1.lua (new - test file)
?? server/maou-data/ (new - Roblox type definitions)
?? server/script/core/diagnostics/invalid-import-path.lua (new - import validation)
?? server/script/debug.lua (new - debug logging)
?? build.bat, build.sh, install.bat, install.sh (new - build scripts)
```

## งานค้าง

✅ **COMPLETED** - `@import` annotation feature for Roblox LSP

### Implemented Feature
**Syntax:**
```lua
---@import "./lib1.lua" as Utils
```

**What works:**
- ✅ Parse `@import` annotations with path and alias
- ✅ Resolve relative paths (`./file.lua`) and absolute paths (`/Core/Utils`)
- ✅ Auto-detect file extensions (`.lua`, `.luau`)
- ✅ No "undefined variable" warnings for import aliases
- ✅ **Autocomplete** works - `Utils.` shows `greet` from imported file
- ✅ Files read from filesystem even if not opened in VSCode

### Key Files Modified
1. **server/script/parser/luadoc.lua** - Parse `@import` annotations
2. **server/script/vm/getGlobals.lua** - Create virtual globals for import aliases
3. **server/script/vm/eachField.lua** - Handle import detection in completion
4. **server/script/files.lua** - Load files from filesystem
5. **server/script/core/diagnostics/invalid-import-path.lua** - Validate import paths
6. **server/script/debug.lua** - Added debug logging

## Context

### Project: Roblox LSP
- **Fork of**: NightrainsRbx robloxlsp, based on sumneko/lua-language-server
- **Purpose**: VSCode extension providing IntelliSense for Luau/Rbx development
- **Languages**: Lua (server), TypeScript (client)
- **Key Tech**: LSP protocol, Lua VM, AST parsing

### Import Resolution
- **Relative paths**: `./lib1.lua` → resolved from current file directory
- **Absolute paths**: `/Core/Utils` → resolved from workspace root
- **Security**: Path traversal protection (cannot escape workspace)
- **Caching**: Import aliases cached per URI, docs processed once per compilation

### Virtual Global Creation
When `@import` is parsed:
1. Create virtual global with `special='import'`
2. Store in `importAliasCache[uri][alias]`
3. Autocomplete uses `getImportedExports()` to get exported fields

### Known Issues (All Resolved)
- ✅ `ast.docs` was `nil` → Fixed by checking `ast.ast.docs`
- ✅ Leading whitespace in paths → Fixed with `path:match('^%s*(.-)%s*$')`
- ✅ File not in LSP map → Fixed by checking actual filesystem
- ✅ `compileAst()` failed for unopened files → Fixed by using `files.setText()` first

## Next Steps

1. ✅ Feature complete - ready for production use
2. Consider: Add `@import` to workspace-relative imports
3. Consider: Cache imported file ASTs longer
4. Consider: Handle circular imports more elegantly

## Testing
```lua
---@import "./lib1.lua" as Utils

Utils.greet("Test")  -- ✅ Autocomplete works
Utils.             -- ✅ Autocomplete shows "greet"
```

**Test files:**
- `Example/main.lua` - Uses `@import`
- `Example/lib1.lua` - Returns `GG` table with `greet` function
