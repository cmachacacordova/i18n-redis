# Configure and build script for i18n-redis (PowerShell)
# Usage: .\configure.ps1 [-Preset <name>] [-ConfigureOnly] [-CmakeArgs <args>]
#   -Preset <name>       Use specific CMake preset
#   -ConfigureOnly       Only configure, don't build
#   -CmakeArgs <args>    Extra arguments forwarded to cmake configure step
# If no preset specified, shows interactive selection menu

param(
    [string]$Preset = "",
    [switch]$UseVcpkg,
    [switch]$ConfigureOnly,
    [string[]]$CmakeArgs = @(),
    [switch]$Help
)

if ($Help) {
    @"
Configure and build i18n-redis

Usage: .\configure.ps1 [OPTIONS]

Options:
  -Preset <name>         Use specific CMake preset
  -UseVcpkg              Use vcpkg for dependency management
  -ConfigureOnly         Only configure, don't build
  -CmakeArgs <args>      Extra arguments forwarded to cmake configure step
  -Help                  Show this help message

Examples:
  .\configure.ps1                                                         # Interactive mode (system deps)
  .\configure.ps1 -Preset windows-msvc-static-release -UseVcpkg          # Use vcpkg
  .\configure.ps1 -Preset windows-msvc-static-release -CmakeArgs "-DFOO=BAR","-DBAZ=1"

Available presets can be found in CMakePresets.json
"@ | Write-Host
    exit 0
}

$PROJECT_ROOT = $PSScriptRoot
$VCPKG_DIR = ""
$PRESET_MODE = -not [string]::IsNullOrEmpty($Preset)

# Helper functions
function Info($msg) {
    if ($script:PRESET_MODE) {
        return
    }

    Write-Host "[INFO] " -ForegroundColor Green -NoNewline; Write-Host $msg
}

function Progress($msg) {
    Write-Host "[INFO] " -ForegroundColor Green -NoNewline; Write-Host $msg
}

function Invoke-WithInfoPrefix {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    & $Command @Arguments 2>&1 | ForEach-Object {
        Progress $_.ToString()
    }

    return $LASTEXITCODE
}

function Warn($msg) {
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $msg
}

function Error-Exit($msg) {
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $msg
    exit 1
}

function Test-Windows {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        return $IsWindows
    }

    return $true
}

function Get-PlatformName {
    if (Test-Windows) {
        return "windows"
    }

    if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
        return "macos"
    }

    if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
        return "linux"
    }

    return "unknown"
}

function Join-PathSegments {
    param([string[]]$Segments)

    $path = $Segments[0]
    for ($i = 1; $i -lt $Segments.Count; $i++) {
        $path = Join-Path $path $Segments[$i]
    }

    return $path
}

# Check whether a path is a git repository (normal repo or submodule)
function Test-GitRepo($candidate) {
    if (Test-Path (Join-Path $candidate ".git")) {
        return $true
    }

    $result = git -C $candidate rev-parse --git-dir 2>$null
    return ($LASTEXITCODE -eq 0)
}

# Check git is installed
function Test-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Error-Exit "git is not installed. git is required to obtain vcpkg dependencies."
    }
}

# Initialize vcpkg submodule
function Init-VcpkgSubmodule {
    Info "Git repository detected. Updating vcpkg submodule..."
    git submodule update --init --recursive extras/vcpkg
    if ($LASTEXITCODE -ne 0) {
        Error-Exit "Failed to initialize vcpkg submodule"
    }
    Info "vcpkg submodule initialized successfully."
}

# Initialize registry submodule for custom triplets
function Init-RegistrySubmodule {
    $registryDir = Join-PathSegments $PROJECT_ROOT, "extras", "registry"

    if ((Test-Path (Join-Path $registryDir ".git")) -or (Test-Path (Join-Path $registryDir "triplets"))) {
        Info "Registry already available at $registryDir"
        return
    }

    if (Test-GitRepo $PROJECT_ROOT) {
        Info "Initializing registry submodule..."
        git submodule update --init extras/registry
        if ($LASTEXITCODE -ne 0) {
            Warn "Failed to initialize registry submodule. Will try to clone..."
            Clone-Registry
        } else {
            Info "Registry submodule initialized successfully."
        }
    } else {
        Clone-Registry
    }
}

# Clone registry directly
function Clone-Registry {
    $registryDir = Join-PathSegments $PROJECT_ROOT, "extras", "registry"

    if (Test-Path (Join-Path $registryDir ".git")) {
        Info "Registry already exists at $registryDir"
        return
    }

    if (Test-Path $registryDir) {
        Warn "Registry directory exists but is not a git repo. Removing..."
        Remove-Item -Recurse -Force $registryDir
    }

    Info "Cloning vcpkg-registry from GitHub..."
    git clone --depth=1 -b vcpkg https://github.com/cmachacacordova/vcpkg-registry.git $registryDir
    if ($LASTEXITCODE -ne 0) {
        Error-Exit "Failed to clone registry"
    }
    Info "Registry cloned successfully."
}

# List of custom triplets that require the overlay registry
function Get-CustomTriplets {
    return @("x64-linux-dynamic", "x64-linux-clang", "x64-linux-clang-dynamic", "x64-linux-one-api", "x64-linux-one-api-dynamic", "x64-osx-dynamic")
}

# Check if a triplet requires the overlay registry
function Test-CustomTriplet($triplet) {
    $customTriplets = Get-CustomTriplets
    return $customTriplets -contains $triplet
}

# Extract VCPKG_TARGET_TRIPLET from a preset using cmake
function Get-PresetTriplet($preset) {
    # Try to get triplet from cmake preset output
    $output = cmake --preset $preset 2>&1
    $triplet = $null

    foreach ($line in $output) {
        if ($line -match 'VCPKG_TARGET_TRIPLET=(\S+)') {
            $triplet = $matches[1]
            break
        }
    }

    # If not found, try parsing CMakePresets.json
    if (-not $triplet) {
        $presetsFile = Join-Path $PROJECT_ROOT "CMakePresets.json"
        if (Test-Path $presetsFile) {
            $content = Get-Content $presetsFile -Raw
            # Simple regex to find VCPKG_TARGET_TRIPLET in the preset
            $pattern = '"name":\s*"' + [regex]::Escape($preset) + '".*?(?:"VCPKG_TARGET_TRIPLET":\s*"([^"]+)")'
            if ($content -match $pattern) {
                $triplet = $matches[1]
            }
        }
    }

    return $triplet
}

# Clone vcpkg
function Clone-Vcpkg {
    $vcpkgDir = Join-PathSegments $PROJECT_ROOT, "extras", "vcpkg"

    if (Test-Path (Join-Path $VCPKG_DIR ".git")) {
        Info "vcpkg already exists at $VCPKG_DIR"
        return
    }

    if (Test-Path $vcpkgDir) {
        Warn "vcpkg directory exists but is not a git repo. Removing..."
        Remove-Item -Recurse -Force $vcpkgDir
    }

    Info "Cloning vcpkg from GitHub..."
    git clone --depth=1 https://github.com/microsoft/vcpkg.git $vcpkgDir
    if ($LASTEXITCODE -ne 0) {
        Error-Exit "Failed to clone vcpkg"
    }
    Info "vcpkg cloned successfully."
}

function Test-VcpkgSourceDir($candidate) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { return $false }
    if (-not (Test-Path $candidate -PathType Container)) { return $false }
    if (-not (Test-Path (Join-PathSegments $candidate, "scripts", "buildsystems", "vcpkg.cmake"))) { return $false }
    if (-not ((Test-Path (Join-Path $candidate "bootstrap-vcpkg.bat")) -or (Test-Path (Join-Path $candidate "bootstrap-vcpkg.sh")))) { return $false }

    return $true
}

function Test-BootstrappedVcpkgDir($candidate) {
    if (-not (Test-VcpkgSourceDir $candidate)) { return $false }

    if (Test-Windows) {
        return (Test-Path (Join-Path $candidate "vcpkg.exe"))
    }

    return (Test-Path (Join-Path $candidate "vcpkg"))
}

function Resolve-Vcpkg {
    if (-not [string]::IsNullOrWhiteSpace($env:VCPKG_HOME)) {
        if (Test-BootstrappedVcpkgDir $env:VCPKG_HOME) {
            $script:VCPKG_DIR = $env:VCPKG_HOME
            Info "Using vcpkg from VCPKG_HOME: $script:VCPKG_DIR"
            return
        }

        if (Test-VcpkgSourceDir $env:VCPKG_HOME) {
            $script:VCPKG_DIR = $env:VCPKG_HOME
            Info "Using vcpkg source from VCPKG_HOME: $script:VCPKG_DIR"
            return
        }

        Warn "VCPKG_HOME is set but does not point to a valid vcpkg root: $env:VCPKG_HOME"
    }

    $script:VCPKG_DIR = Join-PathSegments $PROJECT_ROOT, "extras", "vcpkg"

    if (Test-BootstrappedVcpkgDir $script:VCPKG_DIR) {
        Info "Using local vcpkg from $script:VCPKG_DIR"
        return
    }

    if (Test-GitRepo $PROJECT_ROOT) {
        Init-VcpkgSubmodule
    } else {
        if (Test-VcpkgSourceDir $script:VCPKG_DIR) {
            Info "Using local vcpkg source from $script:VCPKG_DIR"
        } else {
            Clone-Vcpkg
        }
    }
}

# Bootstrap vcpkg
function Bootstrap-Vcpkg {
    $vcpkgExe = Join-Path $VCPKG_DIR "vcpkg.exe"
    if (-not (Test-Windows)) {
        $vcpkgExe = Join-Path $VCPKG_DIR "vcpkg"
    }

    if (Test-Path $vcpkgExe) {
        Info "vcpkg is already bootstrapped."
        return
    }

    if (Test-Windows) {
        $bootstrapScript = Join-Path $VCPKG_DIR "bootstrap-vcpkg.bat"
    } else {
        $bootstrapScript = Join-Path $VCPKG_DIR "bootstrap-vcpkg.sh"
    }

    if (-not (Test-Path $bootstrapScript)) {
        Error-Exit "vcpkg bootstrap script not found at $bootstrapScript"
    }

    Info "Bootstrapping vcpkg..."
    & $bootstrapScript -disableMetrics
    if ($LASTEXITCODE -ne 0) {
        Error-Exit "Failed to bootstrap vcpkg"
    }
    Info "vcpkg bootstrapped successfully."
}

# Get available presets using cmake --list-presets
function Get-AvailablePresets {
    $presets = @()
    $platform = Get-PlatformName

    # Get presets from cmake output
    $cmakeOutput = cmake --list-presets=configure 2>$null
    if ($LASTEXITCODE -eq 0) {
        foreach ($line in $cmakeOutput) {
            if ($line -match '^\s*"([^"]+)"\s*-\s*(.*)$') {
                $name = $Matches[1]
                $displayName = $Matches[2]

                if ($platform -eq "linux" -and $name -notmatch "^linux-") { continue }
                if ($platform -eq "windows" -and $name -notmatch "^windows-") { continue }
                if ($platform -eq "macos" -and $name -notmatch "^macos-") { continue }

                $presets += [PSCustomObject]@{
                    name = $name
                    displayName = $displayName
                }
            }
        }
    }

    if ($presets.Count -eq 0) {
        Error-Exit "No presets found. Make sure CMakePresets.json exists and is valid."
    }

    return $presets
}

function Test-PresetExists($preset) {
    $allPresets = Get-AvailablePresets
    foreach ($availablePreset in $allPresets) {
        if ($availablePreset.name -eq $preset) {
            return $true
        }
    }

    return $false
}

function Validate-Preset($preset) {
    if (Test-PresetExists $preset) {
        return
    }

    Write-Host "[ERROR] Preset not found: $preset" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available presets:"
    foreach ($availablePreset in (Get-AvailablePresets)) {
        Write-Host "  $($availablePreset.name) - $($availablePreset.displayName)"
    }
    exit 1
}

# Interactive preset selection
function Select-PresetInteractive {
    $platform = Get-PlatformName

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Available presets for ${platform}:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $presets = Get-AvailablePresets

    for ($i = 0; $i -lt $presets.Count; $i++) {
        $num = $i + 1
        $name = $presets[$i].name
        $display = $presets[$i].displayName
        Write-Host "  $num) $name" -NoNewline
        Write-Host "  $display" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan

    while ($true) {
        $selection = Read-Host "Select preset (1-$($presets.Count))"
        if ($selection -match "^\d+$") {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $presets.Count) {
                return $presets[$index].name
            }
        }
        Warn "Invalid selection. Please enter a number between 1 and $($presets.Count)"
    }
}

# Determine vcpkg feature from preset name
function Get-VcpkgFeature($preset) {
    if ($preset -match "yyjson") {
        return "yyjson"
    }
    return "simdjson"
}

# Configure with CMake
function Configure-CMake($preset) {
    $vcpkgArgs = @()

    if ($UseVcpkg) {
        $feature = Get-VcpkgFeature $preset
        $toolchainFile = Join-Path $VCPKG_DIR "scripts\buildsystems\vcpkg.cmake"

        $vcpkgArgs += "-DCMAKE_TOOLCHAIN_FILE=$toolchainFile"
        $vcpkgArgs += "-DVCPKG_MANIFEST_FEATURES=$feature"

        # Check if preset uses a custom triplet that needs overlay
        $triplet = Get-PresetTriplet $preset

        if ($triplet -and (Test-CustomTriplet $triplet)) {
            Info "Preset uses custom triplet: $triplet"
            Init-RegistrySubmodule

            $registryDir = Join-PathSegments $PROJECT_ROOT, "extras", "registry"
            $vcpkgArgs += "-DVCPKG_OVERLAY_TRIPLETS=$registryDir\triplets"
            $vcpkgArgs += "-DVCPKG_OVERLAY_PORTS=$registryDir\ports"
            Info "Using overlay registry for custom triplet"
        }

        $env:VCPKG_HOME = $VCPKG_DIR
        Progress "Configuring with preset: $preset (vcpkg enabled, feature: $feature)"
    } else {
        Progress "Configuring with preset: $preset (system deps)"
    }

    $cmakeInvokeArgs = @("--fresh", "--preset", $preset) + $vcpkgArgs + $CmakeArgs
    $exitCode = Invoke-WithInfoPrefix "cmake" $cmakeInvokeArgs
    if ($exitCode -ne 0) {
        Error-Exit "CMake configuration failed"
    }
    Info "Configuration completed successfully"
}

# Build the project
function Build-Project($preset) {
    Progress "Building project with preset: $preset"

    $exitCode = Invoke-WithInfoPrefix "cmake" @("--build", "--preset", $preset, "--parallel")
    if ($exitCode -ne 0) {
        Error-Exit "Build failed"
    }
    Info "Build completed successfully"
}

# Main
if (-not $PRESET_MODE) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "i18n-redis Configure & Build" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    if ($UseVcpkg) {
        Write-Host "Mode: Using vcpkg for dependencies" -ForegroundColor Green
    } else {
        Write-Host "Mode: Using system packages (default)" -ForegroundColor Green
    }
    Write-Host ""
}

# Check for required files
if (-not (Test-Path (Join-Path $PROJECT_ROOT "CMakeLists.txt"))) {
    Error-Exit "CMakeLists.txt not found. Are you in the right directory?"
}

if (-not (Test-Path (Join-Path $PROJECT_ROOT "CMakePresets.json"))) {
    Error-Exit "CMakePresets.json not found."
}

# vcpkg operations only when -UseVcpkg is specified
if ($UseVcpkg) {
    # Check git is installed (required for vcpkg)
    Test-Git

    # Check vcpkg.json exists
    if (-not (Test-Path (Join-Path $PROJECT_ROOT "vcpkg.json"))) {
        Error-Exit "vcpkg.json not found. Are you in the right directory?"
    }

    $gitDir = Join-Path $PROJECT_ROOT ".git"
    if (Test-GitRepo $PROJECT_ROOT) {
        Info "Project git repository detected at $gitDir"
    } else {
        Info "Project git repository not detected at $gitDir"
    }

    if ($PRESET_MODE) {
        Progress "Preparing vcpkg..."
    }

    Resolve-Vcpkg

    # Bootstrap vcpkg
    Bootstrap-Vcpkg
}

# Select preset
if ([string]::IsNullOrEmpty($Preset)) {
    $Preset = Select-PresetInteractive
} else {
    Validate-Preset $Preset
}

if (-not $PRESET_MODE) {
    Write-Host ""
    Write-Host "Selected preset: $Preset"
    Write-Host ""
}

# Configure
Configure-CMake $Preset

# Build (unless -ConfigureOnly)
if (-not $ConfigureOnly) {
    Build-Project $Preset
    if (-not $PRESET_MODE) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Build completed successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "To run tests: ctest --preset $Preset"
        Write-Host "To install:   cmake --install out/build --prefix <install_dir>"
    }
} else {
    if (-not $PRESET_MODE) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "Configuration completed (build skipped)" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To build:     cmake --build --preset $Preset"
        Write-Host "To run tests: ctest --preset $Preset"
    }
}
