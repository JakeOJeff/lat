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

set SCRIPT_DIR="%~dp0"
set COMPILER_DIR=%SCRIPT_DIR%..\compiler 

if not exist %COMPILER_DIR% (
    echo [lat] ERROR: compiler\ folder not found. Run this from lat repo root.
    exit /b 1
)