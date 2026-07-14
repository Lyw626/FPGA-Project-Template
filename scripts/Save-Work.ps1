[CmdletBinding()]
param(
    [string]$Message,
    [switch]$Yes,
    [switch]$NoPush
)

. (Join-Path $PSScriptRoot "Common.ps1")

Assert-Repository
Assert-Command git

Confirm-Exact -Prompt "Confirm Vivado Save All is complete and no build or simulation task is running." -AssumeYes:$Yes
Wait-ChangedFilesStable

Push-Location (Get-RepositoryRoot)
try {
    Invoke-Git add -A
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes to commit."
        exit 0
    }
    if ($LASTEXITCODE -ne 1) {
        throw "Unable to inspect staged changes."
    }

    Invoke-Git diff --cached --stat
    if (-not $Message) {
        $Message = Read-Host "Commit message (Chinese recommended)"
    }
    if (-not $Message.Trim()) {
        throw "Commit message cannot be empty."
    }

    Invoke-Git commit -m $Message

    if (-not $NoPush) {
        $branch = (Get-GitOutput branch --show-current | Select-Object -First 1).Trim()
        & git rev-parse --abbrev-ref "@{upstream}" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Invoke-GitNetwork push
        }
        else {
            Invoke-GitNetwork push -u origin $branch
        }
    }

    $remaining = @(Get-WorkingTreeStatus)
    if ($remaining.Count -gt 0) {
        Write-Warning "Files changed after the commit and remain for the next commit:"
        $remaining | ForEach-Object { Write-Warning $_ }
    }
    else {
        Write-Host "Work saved and synchronized."
    }
}
finally {
    Pop-Location
}
