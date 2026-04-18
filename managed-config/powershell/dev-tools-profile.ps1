# Repo-managed PowerShell snippet for ai-dev-setup.
# The installer copies this file to %USERPROFILE%\.ai-dev-setup\powershell\
# and user profiles source it via a single include block.

if (Get-Command mise -ErrorAction SilentlyContinue) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { zoxide init powershell | Out-String })
}
