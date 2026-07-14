[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "Common.ps1")

Assert-Repository
Assert-Command git
$gh = Get-GhCommand
$config = Get-JsonFile "project-control/config/project-config.json"

Write-Host "Checking Git LFS..."
$lfsVersionLines = @(& git lfs version)
$lfsExitCode = $LASTEXITCODE
if ($lfsExitCode -ne 0) {
    throw "Git LFS is not installed."
}
$lfsVersionOutput = $lfsVersionLines | Select-Object -First 1
Write-Host $lfsVersionOutput
if ($lfsVersionOutput -notmatch "git-lfs/(\d+\.\d+\.\d+)") {
    throw "Unable to determine the Git LFS version."
}
$installedLfsVersion = [version]$Matches[1]
$minimumLfsVersion = [version]([string]$config.tools.minimumGitLfsVersion)
if ($installedLfsVersion -lt $minimumLfsVersion) {
    throw "Git LFS $minimumLfsVersion or newer is required. Installed: $installedLfsVersion"
}

Write-Host "Checking GitHub authentication..."
& $gh auth status
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run gh auth login."
}

Invoke-Git lfs install

$version = [string]$config.vivado.requiredVersion
$vivadoCandidates = @()
if ($env:XILINX_VIVADO) {
    $vivadoCandidates += Join-Path $env:XILINX_VIVADO "bin\vivado.bat"
}
$vivadoCommands = @(Get-Command vivado.bat -All -ErrorAction SilentlyContinue)
$vivadoCandidates += $vivadoCommands | ForEach-Object { $_.Source }
$vivadoCandidates += Join-Path ${env:ProgramFiles} "Xilinx\Vivado\$version\bin\vivado.bat"
foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
    $vivadoCandidates += Join-Path $drive.Root "Xilinx\Vivado\$version\bin\vivado.bat"
}
$versionPattern = "[\\/]" + [regex]::Escape($version) + "[\\/]"
$vivado = $vivadoCandidates |
    Where-Object { $_ -and (Test-Path -LiteralPath $_) -and ($_ -match $versionPattern) } |
    Select-Object -Unique |
    Select-Object -First 1
if ($vivado) {
    Write-Host "Vivado $version found: $vivado"
}
else {
    Write-Warning "Vivado $version was not found in the standard install locations."
}

$project = Resolve-RepositoryPath ([string]$config.vivado.projectFile)
if (-not (Test-Path -LiteralPath $project)) {
    throw "Vivado project was not found: $project"
}

Write-Host "Computer setup check completed."
