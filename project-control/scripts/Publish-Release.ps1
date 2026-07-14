[CmdletBinding()]
param(
    [string]$Notes,
    [switch]$Yes,
    [switch]$DryRun
)

. (Join-Path $PSScriptRoot "Common.ps1")

Assert-Repository
Assert-Command git
$gh = Get-GhCommand
$config = Get-JsonFile "project-control/config/project-config.json"
$releaseFiles = Get-JsonFile "project-control/config/release-files.json"

& (Join-Path $PSScriptRoot "Check-Project.ps1") -Release

if ([bool]$config.release.cfgDateConfirmationRequired) {
    Confirm-Exact -Prompt "Confirm the cfg module version-date register was updated." -AssumeYes:$Yes
}
Confirm-Exact -Prompt "Confirm board-level functional validation passed." -AssumeYes:$Yes

Push-Location (Get-RepositoryRoot)
try {
    Invoke-GitNetwork fetch origin --prune
    $counts = (Get-GitOutput rev-list --left-right --count "HEAD...origin/main" | Select-Object -First 1) -split '\s+'
    if ([int]$counts[0] -ne 0 -or [int]$counts[1] -ne 0) {
        throw "Local main and origin/main are not synchronized."
    }

    $datePrefix = "v" + (Get-Date -Format "yyyy.MM.dd") + "."
    $numbers = @(Get-GitOutput tag --list "$datePrefix*" | ForEach-Object {
        if ($_ -match ('^' + [regex]::Escape($datePrefix) + '(\d+)$')) { [int]$Matches[1] }
    })
    $next = if ($numbers.Count -gt 0) { ($numbers | Measure-Object -Maximum).Maximum + 1 } else { 1 }
    $version = "$datePrefix$next"
    $sourceCommit = (Get-GitOutput rev-parse HEAD | Select-Object -First 1).Trim()
    $repoUrl = (& $gh repo view ([string]$config.repository) --json url --jq .url).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Unable to read GitHub repository metadata." }

    Write-Host "Release version: $version"
    if ($DryRun) {
        Write-Host "Dry run complete. No files, tags, or releases were created."
        exit 0
    }

    $stageRelative = "output/generated/release/$version"
    $stagePath = Resolve-RepositoryPath $stageRelative
    if (Test-Path -LiteralPath $stagePath) {
        Remove-Item -LiteralPath $stagePath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stagePath -Force | Out-Null

    foreach ($artifact in $releaseFiles.artifacts) {
        $source = Resolve-RepositoryPath ([string]$artifact.path)
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $stagePath ([string]$artifact.name))
        }
        elseif ([bool]$artifact.required) {
            throw "Required artifact disappeared: $($artifact.path)"
        }
    }

    if ([bool]$releaseFiles.bootImage.enabled) {
        $templatePath = Resolve-RepositoryPath ([string]$config.release.bifTemplate)
        $generatedBif = Resolve-RepositoryPath ([string]$config.release.generatedBif)
        $bif = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
        foreach ($property in $releaseFiles.bootImage.PSObject.Properties) {
            if ($property.Name -eq "enabled") { continue }
            $absolute = (Resolve-RepositoryPath ([string]$property.Value)) -replace '\\', '/'
            $bif = $bif.Replace("{{$($property.Name)}}", $absolute)
        }
        $bifDirectory = Split-Path -Parent $generatedBif
        New-Item -ItemType Directory -Path $bifDirectory -Force | Out-Null
        Set-Content -LiteralPath $generatedBif -Value $bif -Encoding ASCII
        Copy-Item -LiteralPath $generatedBif -Destination (Join-Path $stagePath "boot.bif")
    }

    $hashLines = Get-ChildItem -LiteralPath $stagePath -File | Sort-Object Name | ForEach-Object {
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $($_.Name)"
    }
    $hashLines | Set-Content -LiteralPath (Join-Path $stagePath "SHA256SUMS.txt") -Encoding ASCII

    if (-not $Notes) {
        $Notes = Read-Host "Short release notes"
    }
    if (-not $Notes) { $Notes = "Validated FPGA release." }

    $manifestDirectory = Resolve-RepositoryPath "project-control/releases/$version"
    New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
    $manifestPath = Join-Path $manifestDirectory "README.md"
    $manifest = @(
        "# $version",
        "",
        "- Project: $($config.projectName)",
        "- Date: $(Get-Date -Format 'yyyy-MM-dd')",
        "- Vivado: $($config.vivado.requiredVersion)",
        "- Source commit: [$sourceCommit]($repoUrl/commit/$sourceCommit)",
        "- Download: [$version]($repoUrl/releases/tag/$version)",
        "",
        "## Notes",
        "",
        $Notes,
        "",
        "## SHA-256",
        "",
        '```text',
        ($hashLines -join [Environment]::NewLine),
        '```'
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding UTF8

    $zipPath = Resolve-RepositoryPath "output/generated/$($config.projectName)-$version.zip"
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    Compress-Archive -Path (Join-Path $stagePath "*") -DestinationPath $zipPath -CompressionLevel Optimal

    Invoke-Git add "project-control/releases/$version/README.md"
    $releasePrefix = ([char]0x53D1) + ([char]0x5E03) + ([char]0xFF1A)
    Invoke-Git commit -m "$releasePrefix$version"
    Invoke-Git tag -a $version -m "Release $version"
    Invoke-GitNetwork push origin main
    Invoke-GitNetwork push origin $version

    & $gh release create $version $zipPath --repo ([string]$config.repository) --title $version --notes-file $manifestPath --verify-tag
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub Release creation failed. The commit and tag were already pushed."
    }

    Write-Host "Published: $repoUrl/releases/tag/$version"
}
finally {
    Pop-Location
}
