# Roblox LSP - AI Team Configuration

This directory contains the Roblox Language Server Protocol (LSP) project, providing IntelliSense, diagnostics, and language support for Roblox Luau development in VSCode.

## Project Structure

### Client (VSCode Extension)
- **Location**: `client/`
- **Language**: TypeScript
- **Purpose**: VSCode extension client, handles UI, language client communication, and API updates

### Server (Language Server)
- **Location**: `server/script/`
- **Language**: Lua
- **Purpose**: Core language server implementing LSP features
- **Key Components**:
  - `parser/` - Lua/Luau parser and AST compiler
  - `core/` - LSP feature implementations (completion, diagnostics, hover, etc.)
  - `vm/` - Virtual machine for runtime analysis
  - `provider/` - LSP protocol handlers
  - `library/` - Roblox API definitions and standard libraries

### API Definitions
- **Location**: `server/api/` and `server/maou-data/`
- **Files**:
  - `API-Dump.json` - Complete Roblox API reflection
  - `API-Docs.json` - Roblox API documentation (legacy, fallback)
  - `DataTypes.json` - Roblox data type definitions
  - `Corrections.json` - API corrections and overrides
  - `version.txt` - Current API version

### MaouData (Official Roblox Type Definitions)
- **Location**: `MaouData/` (source), `server/maou-data/` (bundled)
- **Purpose**: Official Roblox Luau LSP type definitions and binaries
- **Files**:
  - `en-us.json` - Official API documentation (6.4MB, newer format)
  - `globalTypes.d.luau` - Complete Luau type definitions (650KB)
  - `luau-lsp.exe` - Official Roblox Luau LSP server binary (10MB)
- **Usage**: Build scripts automatically copy these files during `build.bat`/`build.sh`

#### MaouData Integration
The extension automatically uses MaouData when available:
- **Documentation**: `en-us.json` is preferred over `API-Docs.json`
- **Type Definitions**: `globalTypes.d.luau` provides official type inference
- **Optional LSP**: Set `robloxLsp.useOfficialLsp: true` to use `luau-lsp.exe`

**Configuration**:
```json
{
  "robloxLsp.useOfficialLsp": false,
  "robloxLsp.useMaouDataTypes": true
}
```

## Custom Features (MaouStan's Version)

### @import Annotation
The LSP supports a custom `---@import` annotation that allows importing variables from external files:

```lua
---@import "Utils/ScriptLoader/init.luau"
local GG = loadstring(readfile("Utils/ScriptLoader/init.luau"))()
```

**Implementation Files**:
- `server/script/core/diagnostics/invalid-import-path.lua` - Validates import paths
- `server/script/parser/luadoc.lua` - Parses @import annotations
- `server/script/vm/init.lua` - Resolves imported globals
- `server/script/library/luau-types.lua` - Parses MaouData type definitions

### Other Enhancements
- Path traversal protection for imports
- Circular import detection
- LRU cache for imported globals
- Auto-detection of `loadstring(readfile(...))()` pattern

## Development Workflow

### Building the Extension
```bash
cd client
npm install
cd ..
vsce package
```

### Testing LSP Features
1. Make changes to server code
2. Reload VSCode window (Ctrl+Shift+P > "Reload Window")
3. Test with example files in `Example/`

### Updating Roblox API
The extension auto-updates Roblox API definitions on startup. Manually trigger by examining:
- `client/src/extension.ts` - Update logic
- API URLs from CloneTrooper1019's Roblox-Client-Tracker

## File Conventions

### Lua Files
- Use `.lua` extension for standard Lua files
- Use `.luau` extension for Roblox Luau files
- Follow EmmyLua annotation style for type hints

### Diagnostics
Diagnostic implementations are in `server/script/core/diagnostics/`:
- Each diagnostic has its own file
- Must return a function: `function(uri, callback)`
- Use `lang.script()` for i18n messages

### Completion
Completion logic in `server/script/core/completion.lua`:
- Integrates with Roblox API definitions
- Supports workspace symbols
- Handles module imports

## Key Dependencies

### Client
- `vscode-languageclient` - LSP client library
- `express` - Local API server
- `node-fetch` - API update fetching

### Server (Lua)
- `bee.lua` - Utility library
- `json.lua` - JSON parsing
- LPegLabel - Parser generator

## Debugging

### Enable Debug Mode
In VSCode settings:
```json
{
  "robloxLsp.develop.enable": true,
  "robloxLsp.develop.debuggerPort": 11412
}
```

### Log Files
Check VSCode Output panel:
- Select "Roblox LSP Server" from dropdown
- Shows server initialization, diagnostics, and errors

## Common Tasks

### Adding a New Diagnostic
1. Create file in `server/script/core/diagnostics/<name>.lua`
2. Implement diagnostic function
3. Register in `server/script/core/diagnostics/init.lua`
4. Add i18n strings to `server/script/locale-loader.lua`

### Extending Completion
1. Modify `server/script/core/completion.lua`
2. Add completion logic for new types
3. Test with various code contexts

### Updating API Definitions
API definitions auto-update from GitHub. To manually update:
1. Fetch from `https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json`
2. Place in `server/api/API-Dump.json`
3. Update `server/api/version.txt`

---

## AI Team Configuration (autogenerated by team-configurator, 2026-01-03)

**Important: YOU MUST USE subagents when available for the task.**

### Detected Tech Stack
- **Language Server**: Lua (server-side)
- **Extension Client**: TypeScript/JavaScript
- **Platform**: VSCode Extension API
- **Parser**: Custom Lua/Luau parser with LPeg
- **Build Tools**: vsce, npm
- **API**: Language Server Protocol (LSP)
- **Runtime**: Bee.lua, Luau VM

### AI Team Assignments

| Task | Agent | Notes |
|------|-------|-------|
| Lua/Luau server development | General Assistant | Core LSP features in `server/script/` |
| TypeScript client development | General Assistant | VSCode extension in `client/src/` |
| Parser modifications | General Assistant | Grammar and compilation in `server/script/parser/` |
| Diagnostic implementation | General Assistant | Add to `server/script/core/diagnostics/` |
| API updates | General Assistant | Update JSON definitions in `server/api/` |
| Code review | marie-kondo | File placement and organization reviews |
| Context search | context-finder | Git history, file discovery |
| Test execution | executor | Run test plans and bash commands |

### Project-Specific Guidelines

1. **Lua Module System**: The project uses a custom require() system. Modules are referenced with `require 'module.path'` syntax.
2. **LSP Protocol**: All features must conform to the LSP specification defined in `server/script/proto/`.
3. **Roblox API**: Always check `API-Dump.json` before assuming Roblox API structure.
4. **Import Feature**: The `---@import` annotation is custom. Modify `server/script/parser/luadoc.lua` to change parsing.
5. **File Extensions**: Support both `.lua` and `.luau` extensions throughout the codebase.

### Workflow Tips

- When adding diagnostics, check existing ones in `server/script/core/diagnostics/` for patterns
- Completion logic relies heavily on the VM (virtual machine) for type inference
- The parser is custom-built; modifications may affect multiple features
- Client and server communicate via JSON-RPC; check `server/script/jsonrpc.lua` for protocol handling

---

**For contributors**: This is a customized fork of the original Roblox LSP by NightrainsRbx, which itself was based on sumneko/lua-language-server. Credit to the original authors.
