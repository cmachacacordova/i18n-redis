# Script to package Windows binary artifacts for i18n-redis
# This script is used by GitHub Actions - not intended for direct user use.
# Usage: .github\scripts\package_windows.ps1 -Variant <variant> [-OutputDir <dir>]

param(
    [Parameter(Mandatory=$true)]
    [string]$Variant,

    [string]$OutputDir = "release",
    [string]$InstallDir = "out\install",
    [string]$Compiler = "msvc"
)

$ErrorActionPreference = "Stop"

# Get version from .version file
$VersionFile = ".version"
if (Test-Path $VersionFile) {
    $Version = (Get-Content $VersionFile).Trim()
} else {
    $Version = "unknown"
}

$InstallPath = Join-Path $InstallDir $Variant

Write-Host "[PACKAGER] Creating Windows binary package" -ForegroundColor Cyan
Write-Host "[PACKAGER] Variant: $Variant" -ForegroundColor Cyan
Write-Host "[PACKAGER] Install directory: $InstallPath" -ForegroundColor Cyan
Write-Host "[PACKAGER] Version: $Version" -ForegroundColor Cyan
Write-Host "[PACKAGER] Output directory: $OutputDir" -ForegroundColor Cyan

# Verify install directory exists
if (-not (Test-Path $InstallPath)) {
    Write-Error "[PACKAGER] Install directory not found: $InstallPath"
    exit 1
}

# Create package directory structure
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$PkgName = "i18n-redis-$Version-$Compiler-$Variant.zip"
$PkgPath = Join-Path $OutputDir $PkgName

$TempPkgDir = "pkg_temp"
if (Test-Path $TempPkgDir) {
    Remove-Item -Path $TempPkgDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $TempPkgDir | Out-Null

Write-Host "[PACKAGER] Copying install tree..." -ForegroundColor Green
Copy-Item -Path (Join-Path $InstallPath "*") -Destination $TempPkgDir -Recurse -Force

# Copy license and readme
Copy-Item -Path "LICENSE" -Destination "$TempPkgDir\" -Force
Copy-Item -Path "README.md" -Destination "$TempPkgDir\" -Force

# Create the zip package
Write-Host "[PACKAGER] Creating zip archive..." -ForegroundColor Green
Compress-Archive -Path "$TempPkgDir\*" -DestinationPath $PkgPath -Force

# Cleanup temp directory
Remove-Item -Path $TempPkgDir -Recurse -Force

Write-Host "[PACKAGER] Created package: $PkgPath" -ForegroundColor Green
Get-ChildItem $PkgPath

# Validate the package
Write-Host "[PACKAGER] Validating package..." -ForegroundColor Cyan

$errors = 0

# Check for binary files
$zipContent = unzip -l $PkgPath 2>$null
if (-not ($zipContent | Select-String -Pattern "\.(lib|dll|exe)$" -Quiet)) {
    Write-Warning "[PACKAGER] No binary files (.lib, .dll, .exe) found in package"
    $errors++
}

# Check for headers
if (-not ($zipContent | Select-String -Pattern "include/" -Quiet)) {
    Write-Warning "[PACKAGER] No include directory found in package"
    $errors++
}

# Check for cmake config
if (-not ($zipContent | Select-String -Pattern "(cmake/|share/)" -Quiet)) {
    Write-Warning "[PACKAGER] No cmake configuration found in package"
    $errors++
}

$excludedFiles = $zipContent | Select-String -Pattern "(src/.*\.cpp$|extras/registry|\.github/|vcpkg_installed/|out/|CMakeLists\.txt|CMakePresets\.json|vcpkg\.json|vcpkg-configuration\.json)"
if ($excludedFiles) {
    $count = ($excludedFiles | Measure-Object).Count
    Write-Warning "[PACKAGER] Found $count non-runtime/build-source files in package"
    $errors++
}

if ($errors -eq 0) {
    Write-Host "[PACKAGER] Package validation: PASSED" -ForegroundColor Green
} else {
    Write-Host "[PACKAGER] Package validation: FAILED ($errors errors)" -ForegroundColor Red
    exit 1
}

exit 0
