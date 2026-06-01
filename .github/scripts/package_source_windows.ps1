# Package source distribution for Windows (zip)
# Creates a clean source package without binaries, build artifacts, or extras/
# Usage: package_source_windows.ps1 [output_dir]

param(
    [string]$OutputDir = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GithubDir = Split-Path -Parent $ScriptDir
$ProjectRoot = Split-Path -Parent $GithubDir

if (-not $OutputDir) {
    $OutputDir = Join-Path $ProjectRoot "release"
}

$VersionFile = Join-Path $ProjectRoot ".version"
if (-not (Test-Path $VersionFile)) {
    Write-Error "[ERROR] Version file not found: $VersionFile"
    exit 1
}

$Version = (Get-Content $VersionFile -Raw).Trim()
$PkgName = "i18n-redis-${Version}-windows.zip"
$PkgPath = Join-Path $OutputDir $PkgName

Write-Host "[PACKAGER] Creating Windows source package"
Write-Host "[PACKAGER] Version: $Version"
Write-Host "[PACKAGER] Output: $PkgPath"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$TempStaging = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
$StagingDirName = "i18n-redis-$Version"
$StagingDir = Join-Path $TempStaging $StagingDirName
New-Item -ItemType Directory -Path $StagingDir | Out-Null

# Copy essential build files
$FilesToCopy = @(
    "CMakeLists.txt",
    "CMakePresets.json",
    "vcpkg.json",
    "vcpkg-configuration.json",
    "configure.ps1",
    "LICENSE",
    "README.md",
    ".version"
)

foreach ($file in $FilesToCopy) {
    $src = Join-Path $ProjectRoot $file
    if (Test-Path $src) {
        Copy-Item $src $StagingDir
    }
}

# Copy directories needed for building
$DirsToCopy = @("include", "src", "cmake", "locales", "example", "tests")

foreach ($dir in $DirsToCopy) {
    $src = Join-Path $ProjectRoot $dir
    if (Test-Path $src) {
        $dst = Join-Path $StagingDir $dir
        Copy-Item -Recurse $src $dst
    }
}

# Remove any binary artifacts if they exist (just in case)
$BinaryPatterns = @('*.o', '*.a', '*.so', '*.dll', '*.exe', '*.lib', '*.pdb', '*.ilk')
foreach ($pattern in $BinaryPatterns) {
    Get-ChildItem -Path $StagingDir -Recurse -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
}

# Create zip
Compress-Archive -Path "$StagingDir\*" -DestinationPath $PkgPath -Force

Remove-Item -Recurse -Force $TempStaging

Write-Host "[PACKAGER] Package created: $PkgPath"
$Size = (Get-Item $PkgPath).Length
Write-Host "[PACKAGER] Size: $Size bytes"

# Verify package contents
Write-Host "[PACKAGER] Verifying package contents..."
$ZipContent = & { try { & tar -tzf $PkgPath 2>$null } catch { $null } }
if ($ZipContent -match '\.(o|a|so|dll|exe|lib|pdb)$') {
    Write-Error "[ERROR] Package contains binary files!"
    exit 1
}
if ($ZipContent -match 'extras/') {
    Write-Error "[ERROR] Package contains extras/ directory!"
    exit 1
}
Write-Host "[PACKAGER] Verification passed: no binaries or extras found"
