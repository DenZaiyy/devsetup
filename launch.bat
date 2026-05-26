@echo off
:: Lance install.ps1 en demandant automatiquement les droits admin

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Elevation des privileges en cours...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
