@echo off
REM Test @import feature by running the LSP server directly

setlocal enabledelayedexpansion

echo ========================================
echo   @import Feature Test
echo ========================================
echo.

REM Find the LSP server executable
set "LSP_SERVER=server\bin\Windows\lua-language-server.exe"

if not exist "%LSP_SERVER%" (
    echo ERROR: LSP server not found at %LSP_SERVER%
    pause
    exit /b 1
)

echo Found LSP server: %LSP_SERVER%
echo.

REM Create test files
echo Creating test files...
echo.

set "TEST_DIR=%TEMP%\RobloxLspTest"
if exist "%TEST_DIR%" rd /s /q "%TEST_DIR%"
mkdir "%TEST_DIR%"

REM Create lib1.lua
(
echo local GG = {}
echo.
echo function GG.greet^(name^)
echo     return "Hello, " .. name .. "!"
echo end
echo.
echo function GG.farewell^(name^)
echo     return "Goodbye, " .. name .. "!"
echo end
echo.
echo return GG
) > "%TEST_DIR%\lib1.lua"

echo Created lib1.lua

REM Create main.lua
(
echo --@import "./lib1.lua" as lib1
echo.
echo lib1.    -- Cursor here - should show greet and farewell
) > "%TEST_DIR%\main.lua"

echo Created main.lua
echo.

REM Convert to file URI (PowerShell is easier for this)
for /f "delims=" %%i in ('powershell -Command "''file:///%TEST_DIR:\=/%/main.lua'''" 2^>nul') do set "MAIN_URI=%%i"
for /f "delims=" %%i in ('powershell -Command "''file:///%TEST_DIR:\=/%/lib1.lua'''" 2^>nul') do set "LIB_URI=%%i"

echo Test URIs:
echo   main: %MAIN_URI%
echo   lib1:  %LIB_URI%
echo.

echo ========================================
echo   Starting LSP Server...
echo ========================================
echo.

REM Start the server with debug logging
REM Note: This will start the server in interactive mode
"%LSP_SERVER%""

echo.
echo ========================================
echo   Test Complete
echo ========================================
echo.
echo Check the output above for @import debug logs.
echo.
echo Look for:
echo   [@import] Processing docs for URI:
echo   [@import] Doc type: doc.import
echo   [@import] Registered import alias:
echo   [@import] getFields:
echo   [@import] getImportedExports:
echo.

pause
