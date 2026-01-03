# Roblox LSP for MaouStan

**Customized version of Roblox Luau Language Server by MaouStan**

---

## Credits

[Original Project](https://github.com/sumneko/lua-language-server) by [sumneko](https://github.com/sumneko)
[Original Roblox LSP](https://github.com/NightrainsRbx/RobloxLsp) by [Nightrains](https://github.com/NightrainsRbx)

## What's New in This Version

### Custom Features Added by MaouStan:
- **`---@import` annotation** - Import variables from external files
  ```lua
  ---@import "Utils/ScriptLoader/init.luau"
  local GG = loadstring(readfile("Utils/ScriptLoader/init.luau"))()
  ```
- **Auto-detection of `loadstring(readfile(...))()`** pattern
- **Security improvements**: Path traversal protection, circular import detection
- **Performance improvements**: LRU cache for imported globals

## Install In VSCode

Make sure you don't have both [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) by sumneko and Roblox LSP enabled.

### From Marketplace (Original)
https://marketplace.visualstudio.com/items?itemName=Nightrains.robloxlsp

### Build from Source (MaouStan's Version)
See Build section below.

## More Info
https://devforum.roblox.com/t/roblox-lsp-full-intellisense-for-roblox-and-luau/717745

## Get Help

Roblox OS Community Discord Server: https://discord.gg/c4nPcZHwFU

## Alternatives
This project doesn't support Luau static typing and never will, you should always prefer [Luau Language Server](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp) for that.

## Features

- Full Roblox Environment
- Full support for [Rojo](https://github.com/Roblox/rojo)
- Built-in support for Roact, Rodux, and TestEz.
- Auto-completion for instances in Roblox Studio
- Auto-updatable API
- Color3 Preview and Picker
- Module Auto-import
- IntelliSense
- Inlay Hints
- Goto Definition
- Find All References
- Hover
- Diagnostics
- Rename
- Signature Help
- Document Symbols
- Workspace Symbols
- Syntax Check
- Highlight
- Code Action
- Multi Workspace
- Semantic Tokens
- **@import annotation for variable imports** (NEW)

### Preview

![avatar](https://i.imgur.com/4sgYDii.gif)
![avatar](https://i.imgur.com/vHbKIJ0.gif)
![avatar](https://cdn.discordapp.com/attachments/434146484758249482/778145929345368064/test.gif)

## Build

### Prerequisites
- Node.js and npm
- vsce (VSCode Extension Manager)
  ```bash
  npm install -g @vscode/vsce
  ```

### Build Steps
1. Install client dependencies:
   ```bash
   cd client
   npm install
   ```

2. Package extension:
   ```bash
   cd ..
   vsce package
   ```

3. Install the generated `.vsix` file:
   ```bash
   code --install-extension robloxlsp-maoustan-1.7.0.vsix
   ```

## Credit

* [lua-language-server](https://github.com/sumneko/lua-language-server)
* [vscode-luau](https://github.com/Dekkonot/vscode-luau)
* [bee.lua](https://github.com/actboy168/bee.lua)
* [luamake](https://github.com/actboy168/luamake)
* [lni](https://github.com/actboy168/lni)
* [LPegLabel](https://github.com/sqmedeiros/lpeglabel)
* [LuaParser](https://github.com/sumneko/LuaParser)
* [rcedit](https://github.com/electron/rcedit)
* [ScreenToGif](https://github.com/NickeManarin/ScreenToGif)
* [vscode-languageclient](https://github.com/microsoft/vscode-languageserver-node)
* [lua.tmbundle](https://github.com/textmate/lua.tmbundle)
* [EmmyLua](https://emmylua.github.io)
* [lua-glob](https://github.com/sumneko/lua-glob)
* [utility](https://github.com/sumneko/utility)
* [json.lua](https://github.com/actboy168/json.lua)

## Acknowledgement

* [sumneko](https://github.com/sumneko)
* [actboy168](https://github.com/actboy168)
* [Dekkonot](https://github.com/Dekkonot)
* [Dmitry Sannikov](https://github.com/dasannikov)
* [Jayden Charbonneau](https://github.com/Reshiram110)
* [Stjepan Bakrac](https://github.com/z16)
* [Peter Young](https://github.com/young40)
* [Li Xiaobin](https://github.com/Xiaobin0860)
* [Fedora7](https://github.com/Fedora7)
* [Allen Shaw](https://github.com/shuxiao9058)
* [Bartel](https://github.com/Letrab)
* [Ruin0x11](https://github.com/Ruin0x11)
* [uhziel](https://github.com/uhziel)
* [火凌之](https://github.com/PhoenixZeng)
* [CppCXY](https://github.com/CppCXY)
* [Ketho](https://github.com/Ketho)
* [Folke Lemaitre](https://github.com/folke)
