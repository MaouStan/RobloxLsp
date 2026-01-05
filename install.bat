@echo off
REM Roblox LSP Install Script
REM Builds and installs the extension to VSCode

echo ========================================
echo   Roblox LSP Install Script
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "package.json" (
    echo ERROR: package.json not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [1/2] Building extension...
call build.bat
echo.

REM Find the latest .vsix file
for /f "delims=" %%i in ('dir /b /o-d robloxlsp-*.vsix 2^>nul') do (
    set "VSIX_FILE=%%i"
    goto :found
)

:found
if defined VSIX_FILE (
    echo [2/2] Installing: %VSIX_FILE%
    code --install-extension "%VSIX_FILE%" --force
    echo.
    echo ========================================
    echo   Installation complete!
    echo ========================================
    echo.
    echo Please reload VSCode:
    echo   Ctrl+Shift+P -^> "Developer: Reload Window"
) else (
    echo ERROR: No .vsix file found!
)

echo.
