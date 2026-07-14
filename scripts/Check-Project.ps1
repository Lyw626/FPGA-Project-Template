[CmdletBinding()]
param([switch]$Release)

. (Join-Path $PSScriptRoot "Common.ps1")

Assert-Repository
$config = Get-JsonFile "config/project-config.json"
$releaseFiles = Get-JsonFile "config/release-files.json"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) {
    $script:failures.Add($Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Add-Pass([string]$Message) {
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

$projectPath = Resolve-RepositoryPath ([string]$config.vivado.projectFile)
if (Test-Path -LiteralPath $projectPath) { Add-Pass "Vivado project exists." } else { Add-Failure "Vivado project is missing." }

$timingPath = Resolve-RepositoryPath ([string]$config.vivado.timingReport)
if (Test-Path -LiteralPath $timingPath) {
    $timing = Get-Content -LiteralPath $timingPath -Raw
    if ($timing -match [regex]::Escape("Vivado v.$($config.vivado.requiredVersion)")) {
        Add-Pass "Timing report uses Vivado $($config.vivado.requiredVersion)."
    }
    else {
        Add-Failure "Timing report does not match Vivado $($config.vivado.requiredVersion)."
    }
    if ($timing -match "All user specified timing constraints are met\.") {
        $wns = [regex]::Match($timing, "(?ms)WNS\(ns\).*?\r?\n\s*-+.*?\r?\n\s*([+-]?\d+\.\d+)")
        $wnsText = if ($wns.Success) { " WNS=$($wns.Groups[1].Value) ns." } else { "" }
        Add-Pass "Timing constraints are met.$wnsText"
    }
    else {
        Add-Failure "Timing constraints are not reported as met."
    }
}
else {
    Add-Failure "Timing report is missing."
}

$drcPath = Resolve-RepositoryPath ([string]$config.vivado.drcReport)
if (Test-Path -LiteralPath $drcPath) {
    $drc = Get-Content -LiteralPath $drcPath -Raw
    if ($drc -match "(?mi)^\|\s*\S+\s*\|\s*(Error|Critical Warning)\s*\|") {
        Add-Failure "DRC contains an Error or Critical Warning."
    }
    else {
        $violationMatch = [regex]::Match($drc, "Violations found:\s*(\d+)")
        $countText = if ($violationMatch.Success) { " Warnings/advisories=$($violationMatch.Groups[1].Value)." } else { "" }
        Add-Pass "DRC has no Error or Critical Warning.$countText"
    }
}
else {
    Add-Failure "DRC report is missing."
}

$routePath = Resolve-RepositoryPath ([string]$config.vivado.routeStatusReport)
if (Test-Path -LiteralPath $routePath) {
    $route = Get-Content -LiteralPath $routePath -Raw
    if ($route -match "# of nets with routing errors\.+\s*:\s*0\s*:") {
        Add-Pass "Routing completed with zero routing errors."
    }
    else {
        Add-Failure "Routing report does not show zero routing errors."
    }
}
else {
    Add-Failure "Route status report is missing."
}

foreach ($artifact in $releaseFiles.artifacts) {
    $path = Resolve-RepositoryPath ([string]$artifact.path)
    if (Test-Path -LiteralPath $path) {
        Add-Pass "Artifact exists: $($artifact.name)"
    }
    elseif ([bool]$artifact.required) {
        Add-Failure "Required artifact is missing: $($artifact.path)"
    }
    else {
        Write-Warning "Optional artifact is missing: $($artifact.path)"
    }
}

if ($Release) {
    try { Assert-CleanWorkingTree; Add-Pass "Working tree is clean." } catch { Add-Failure $_.Exception.Message }
    Push-Location (Get-RepositoryRoot)
    try {
        $branch = (Get-GitOutput branch --show-current | Select-Object -First 1).Trim()
        if ($branch -eq "main") { Add-Pass "Current branch is main." } else { Add-Failure "Release must run from main." }
    }
    finally { Pop-Location }
}

if ($failures.Count -gt 0) {
    throw "Project check failed with $($failures.Count) error(s)."
}

Write-Host "Project check completed successfully."
