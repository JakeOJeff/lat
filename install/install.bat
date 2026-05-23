@echo off

setlocal enabledelayedexpansion

echo [lat] Windows Installer

where ruby >nul 2>&1

if errorlevel 1 (
    echo [lat] ERROR: Ruby not found. Install from https://rubyinstaller.org
    exit /b 1
)

for /f "tokens=*" %%i in ('where ruby') do set RUBY_PATH=%%i 
echo [lat] Found Ruby at %RUBY_PATH%

set SCRIPT_DIR=%~dp0

pushd "%SCRIPT_DIR%.."
set REPO_DIR=%CD%
popd

set COMPILER_DIR=%REPO_DIR%\compiler

if not exist "%COMPILER_DIR%" (
    echo [lat] ERROR: compiler\ folder not found. Run this from lat repo root.
    exit /b 1
)

if not exist "%COMPILER_DIR%\compile.rb" (
    echo [lat] ERROR: compiler\compile.rb not found.
    exit /b 1
)


set INSTALL_DIR=%USERPROFILE%\bin
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"


set LAUNCHER=%INSTALL_DIR%\lat.bat

(
    echo @echo off
    echo "%RUBY_PATH%" "%COMPILER_DIR%\compile.rb" %%*
) > "%LAUNCHER%"

echo [lat] Installed lat to %LAUNCHER%


echo %PATH% | find /i "%INSTALL_DIR%" >nul
if errorlevel 1 (
    setx PATH "%INSTALL_DIR%" >nul
    echo [lat] Added %INSTALL_DIR% to your PATH
    echo [lat] Restart your terminal, then run: lat ^<file.lat^>
) else (
    echo [lat] %INSTALL_DIR% already in PATH.
    echo [lat] Run: lat ^<file.lat^>
)
