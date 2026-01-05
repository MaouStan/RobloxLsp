@echo off
REM Roblox LSP Build Script
REM Builds the VSCode extension and packages it as a .vsix file

echo ========================================
echo   Roblox LSP Build Script
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "package.json" (
    echo ERROR: package.json not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [1/4] Copying MaouData files to server...
if not exist "MaouData" (
    echo WARNING: MaouData directory not found!
    echo Skipping MaouData copy...
) else (
    if not exist "server\maou-data" mkdir server\maou-data
    copy /Y "MaouData\en-us.json" "server\maou-data\" >nul
    copy /Y "MaouData\globalTypes.d.luau" "server\maou-data\" >nul
    if exist "MaouData\luau-lsp.exe" (
        if not exist "server\bin\Windows" mkdir server\bin\Windows
        copy /Y "MaouData\luau-lsp.exe" "server\bin\Windows\luau-lsp.exe" >nul
    )
    echo Copied: en-us.json, globalTypes.d.luau
)
echo.

echo [2/4] Installing root dependencies...
call npm install --silent
echo.

echo [3/4] Installing client dependencies...
cd client
call npm install --silent
cd ..
echo.

echo [4/4] Packaging extension...
call npx vsce package
echo.

REM Find the latest .vsix file
for /f "delims=" %%i in ('dir /b /o-d robloxlsp-*.vsix 2^>nul') do (
    set "VSIX_FILE=%%i"
    goto :found
)

:found
if defined VSIX_FILE (
    echo ========================================
    echo   Created: %VSIX_FILE%
    echo ========================================
    echo.
    echo To install: code --install-extension %VSIX_FILE%
    echo Or run: install.bat
) else (
    echo WARNING: No .vsix file found!
)

echo.
