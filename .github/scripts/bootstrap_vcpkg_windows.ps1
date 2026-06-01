# Bootstrap vcpkg on Windows
# Usage: .github\scripts\bootstrap_vcpkg_windows.ps1 [vcpkg_path]

param(
    [string]$VcpkgDir = "extras\vcpkg"
)

$vcpkgExe = Join-Path $VcpkgDir "vcpkg.exe"

if (Test-Path $vcpkgExe) {
  Write-Host "vcpkg is already bootstrapped at $VcpkgDir"
  exit 0
}

$bootstrapBat = Join-Path $VcpkgDir "bootstrap-vcpkg.bat"
if (-not (Test-Path $bootstrapBat)) {
  Write-Error "ERROR: vcpkg bootstrap script not found at $bootstrapBat"
  exit 1
}

Write-Host "Bootstrapping vcpkg..."
& $bootstrapBat -disableMetrics
