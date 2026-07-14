Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RepositoryRoot = Split-Path -Parent $PSScriptRoot

function Get-RepositoryRoot {
    return $script:RepositoryRoot
}

function Resolve-RepositoryPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepositoryRoot $Path))
}

function Invoke-Git {
    $gitArguments = @($args)
    & git @gitArguments
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed: git $($gitArguments -join ' ')"
    }
}

function Get-GitOutput {
    $gitArguments = @($args)
    $output = & git @gitArguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed: git $($gitArguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function Invoke-GitNetwork {
    $gitArguments = @($args)
    $maximumAttempts = 3
    for ($attempt = 1; $attempt -le $maximumAttempts; $attempt++) {
        & git @gitArguments
        if ($LASTEXITCODE -eq 0) {
            return
        }
        if ($attempt -lt $maximumAttempts) {
            $delay = $attempt * 2
            Write-Warning "Git network command failed (attempt $attempt/$maximumAttempts). Retrying in $delay seconds."
            Start-Sleep -Seconds $delay
        }
    }
    throw "git network command failed after $maximumAttempts attempts: git $($gitArguments -join ' ')"
}

function Assert-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command was not found: $Name"
    }
}

function Get-GhCommand {
    $command = Get-Command gh -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $installed = Join-Path $env:ProgramFiles "GitHub CLI\gh.exe"
    if (Test-Path -LiteralPath $installed) {
        return $installed
    }

    throw "GitHub CLI was not found. Install GitHub CLI and run gh auth login."
}

function Get-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    $fullPath = Resolve-RepositoryPath $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Configuration file was not found: $Path"
    }
    return Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Assert-Repository {
    Push-Location $script:RepositoryRoot
    try {
        $root = (Get-GitOutput rev-parse --show-toplevel | Select-Object -First 1).Trim()
        if ([System.IO.Path]::GetFullPath($root) -ne [System.IO.Path]::GetFullPath($script:RepositoryRoot)) {
            throw "Scripts must run from their own repository."
        }
    }
    finally {
        Pop-Location
    }
}

function Get-WorkingTreeStatus {
    Push-Location $script:RepositoryRoot
    try {
        return @(Get-GitOutput status --porcelain=v1 --untracked-files=all)
    }
    finally {
        Pop-Location
    }
}

function Assert-CleanWorkingTree {
    $status = @(Get-WorkingTreeStatus)
    if ($status.Count -gt 0) {
        $details = $status -join [Environment]::NewLine
        throw "The working tree is not clean:`n$details"
    }
}

function Confirm-Exact {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string]$Expected = "YES",
        [switch]$AssumeYes
    )
    if ($AssumeYes) {
        return
    }
    $answer = Read-Host "$Prompt Type $Expected to continue"
    if ($answer -cne $Expected) {
        throw "Operation cancelled."
    }
}

function Wait-ChangedFilesStable {
    param([int]$Seconds = 2)

    Push-Location $script:RepositoryRoot
    try {
        $changedPaths = @(Get-GitOutput diff --name-only)
        $untrackedPaths = @(Get-GitOutput ls-files --others --exclude-standard)
        $paths = @(($changedPaths + $untrackedPaths) |
                Where-Object { $_ } |
                Sort-Object -Unique)

        if ($paths.Count -eq 0) {
            return
        }

        $before = @{}
        foreach ($path in $paths) {
            $fullPath = Resolve-RepositoryPath $path
            if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                $file = Get-Item -LiteralPath $fullPath
                $before[$path] = "$($file.Length):$($file.LastWriteTimeUtc.Ticks)"
            }
        }

        Start-Sleep -Seconds $Seconds

        foreach ($path in $before.Keys) {
            $fullPath = Resolve-RepositoryPath $path
            if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
                throw "A changed file disappeared while waiting: $path"
            }
            $file = Get-Item -LiteralPath $fullPath
            $after = "$($file.Length):$($file.LastWriteTimeUtc.Ticks)"
            if ($after -ne $before[$path]) {
                throw "A file is still changing: $path"
            }
        }
    }
    finally {
        Pop-Location
    }
}
