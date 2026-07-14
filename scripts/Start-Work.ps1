[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "Common.ps1")

Assert-Repository
Assert-Command git
Assert-CleanWorkingTree
$config = Get-JsonFile "config/project-config.json"

Push-Location (Get-RepositoryRoot)
try {
    $branch = (Get-GitOutput branch --show-current | Select-Object -First 1).Trim()
    if (-not $branch) {
        throw "Detached HEAD is not supported for normal work."
    }

    Write-Host "Fetching origin..."
    Invoke-GitNetwork fetch origin --prune

    $upstream = & git rev-parse --abbrev-ref "@{upstream}" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Branch '$branch' has no upstream. Push it with -u before starting work."
    }

    Write-Host "Updating '$branch' with fast-forward only..."
    Invoke-GitNetwork pull --ff-only

    $counts = (Get-GitOutput rev-list --left-right --count "HEAD...@{upstream}" | Select-Object -First 1) -split '\s+'
    if ([int]$counts[0] -ne 0 -or [int]$counts[1] -ne 0) {
        throw "Local branch and its upstream are not synchronized. Push pending commits before starting new work."
    }

    $project = Resolve-RepositoryPath ([string]$config.vivado.projectFile)
    if (-not (Test-Path -LiteralPath $project)) {
        throw "Vivado project was not found: $project"
    }

    Write-Host "Ready: $($config.projectName)"
    Write-Host "Branch: $branch"
    Write-Host "Vivado: $($config.vivado.requiredVersion)"
    Write-Host "Project: $($config.vivado.projectFile)"
}
finally {
    Pop-Location
}
