@echo off
where pwsh.exe >nul 2>&1 && (
    pwsh.exe -ExecutionPolicy Bypass -File "%~dp0install-dev-tools.ps1" -InstallAgentTemplates
) || (
    echo PowerShell 7 not found, falling back to Windows PowerShell 5...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-dev-tools.ps1" -InstallAgentTemplates
)
pause
