# WIP — 2026-01-05 [21:20]

## Git Status
```
M .claude/commands/jump.md
M .vscode/settings.json
M client/out/*.js*
M client/package*.json
M client/src/*.ts
M package.json
M robloxlsp-maoustan-1.7.0.vsix
M server/api/*.json
M server/def/env.luau (NEW: exploit globals)
M server/main.lua
M server/script/**/*.lua
?? server/script/core/diagnostics/invalid-import-path.lua
?? server/script/library/luau-types.lua
?? MaouData/ (official Roblox definitions)
```

## งานค้าง
- [ ] **Test exploit globals** - Reload extension and verify IntelliSense works
- [ ] **@import autocomplete** - Still needs debugging (see below)
- [ ] **Commit changes** - After testing

## Exploit Globals (JUST ADDED ✨)

### Changes Made
Just added Roblox exploit environment function support:

**`server/script/parser/compile.lua`** - Added to `specials` table:
- Environment: `getgenv`, `getrenv`, `getfenv`, `setfenv`
- Instance utils: `getcallingscript`, `getloadedmodules`, `getgc`, `getinstances`, `getnilinstances`, `setsimulationradius`, `cloneref`, `clonereference`, `compareinstances`
- Closure checks: `checkcaller`, `islclosure`, `iscclosure`, `is_synapse_function`, `newcclosure`, `isexecutorclosure`, `identifyexecutor`
- File I/O: `readfile`, `writefile`, `listfiles`, `makefolder`, `appendfile`, `isfile`, `isfolder`, `delfile`, `delfolder`

**`server/def/env.luau`** - Added type definitions with proper Luau types

### Super Global Pattern
Now supports:
```lua
local GG = (getgenv and getgenv()) or _G or shared or false
```

---

## @import AutoComplete (STILL IN PROGRESS 🔄)

### Status
Autocomplete for `---@import` annotations still not working.

### Next Steps
1. **Test exploit globals first** - Reload extension and verify
2. **Debug @import** - Enable `robloxLsp.debug.enable: true`
3. **Trace completion flow** - Check `[import]` logs

### Test File
```lua
---@import "./lib1.lua" as Utils
Utils.greet("test")
Utils.  -- <-- Should autocomplete 'greet', 'farewell'
```

---

## Context for Next Session
- Just added exploit environment globals (`getgenv`, `readfile`, etc.)
- Need to reload extension and test IntelliSense
- @import autocomplete still needs debugging
- All changes ready for commit after testing
