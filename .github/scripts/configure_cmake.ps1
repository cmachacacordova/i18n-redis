# Configure CMake with vcpkg toolchain for Windows
# Usage: .github\scripts\configure_cmake.ps1 -Preset <preset> [-ExtraArgs <args>]

param(
    [Parameter(Mandatory=$true)]
    [string]$Preset,

    [string[]]$ExtraArgs = @()
)

$ErrorActionPreference = "Stop"

# Determine JSON backend from preset name
if ($Preset -match "yyjson") {
    $FEATURE = "yyjson"
} else {
    $FEATURE = "simdjson"
}

Write-Host "[CONFIGURE] Configuring preset: $Preset" -ForegroundColor Cyan
Write-Host "[CONFIGURE] vcpkg feature: $FEATURE" -ForegroundColor Cyan

# Set defaults for vcpkg environment variables
$VcpkgHome = if ($env:VCPKG_HOME) { $env:VCPKG_HOME } else { "$env:GITHUB_WORKSPACE\extras\vcpkg" }
$OverlayTriplets = if ($env:VCPKG_OVERLAY_TRIPLETS) { $env:VCPKG_OVERLAY_TRIPLETS } else { "$env:GITHUB_WORKSPACE\extras\registry\triplets" }
$OverlayPorts = if ($env:VCPKG_OVERLAY_PORTS) { $env:VCPKG_OVERLAY_PORTS } else { "$env:GITHUB_WORKSPACE\extras\registry\ports" }

$TOOLCHAIN = "$VcpkgHome\scripts\buildsystems\vcpkg.cmake"

$cmakeArgs = @(
    "--preset", $Preset
    "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN"
    "-DVCPKG_MANIFEST_FEATURES=$FEATURE"
    "-DVCPKG_OVERLAY_TRIPLETS=$OverlayTriplets"
    "-DVCPKG_OVERLAY_PORTS=$OverlayPorts"
) + $ExtraArgs

& cmake @cmakeArgs

Write-Host "[CONFIGURE] Configuration complete" -ForegroundColor Green
