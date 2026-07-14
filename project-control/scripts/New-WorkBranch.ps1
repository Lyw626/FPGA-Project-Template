[CmdletBinding()]
param([string]$Name)

. (Join-Path $PSScriptRoot "Common.ps1")

Assert-Repository
Assert-CleanWorkingTree

if (-not $Name) {
    $Name = Read-Host "Work branch name"
}
$Name = ($Name.Trim() -replace '\s+', '-')
if (-not $Name -or $Name.Contains('..') -or $Name.StartsWith('-')) {
    throw "Invalid branch name."
}
$branch = "work/$Name"

Push-Location (Get-RepositoryRoot)
try {
    Invoke-GitNetwork fetch origin --prune
    Invoke-Git switch main
    Invoke-GitNetwork pull --ff-only
    Invoke-Git switch -c $branch
    Invoke-GitNetwork push -u origin $branch
    Write-Host "Created and published branch: $branch"
}
finally {
    Pop-Location
}
