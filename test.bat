@echo off
REM Quick test runner for @import feature
REM Run this from VSCode with the extension installed

echo ========================================
echo   @import Feature Quick Test
echo ========================================
echo.

echo Opening Example folder with VSCode...
echo.

REM Use VSCode to open the Example folder
code "D:\Code\RobloxLsp\Example"

echo.
echo ========================================
echo   Test Instructions:
echo ========================================
echo.
echo 1. Open main.lua in the Example folder
echo 2. Type after "lib1." - should show "greet" completion
echo 3. Type after "Utils." - should show "greet" completion
echo 4. Check "Output" -^> "Roblox LSP Server" for debug logs
echo.
echo Look for logs starting with [@import]:
echo   [@import] Processing docs for URI:
echo   [@import] Doc type: doc.import
echo   [@import] getFields:
echo   [@import] getImportedExports:
echo.
pause
