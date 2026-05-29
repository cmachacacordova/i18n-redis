@echo off
setlocal EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

set VCPKG_DIR=%ROOT_DIR%\external\vcpkg
set CUSTOM_REGISTRY_DIR=%ROOT_DIR%\vcpkg

:: Initialize and update custom vcpkg registry submodule
echo Initializing custom vcpkg registry submodule...
if exist "%ROOT_DIR%\.git" (
  git -C "%ROOT_DIR%" submodule update --init vcpkg 2>nul || echo Note: Could not update submodule
  :: Pull latest from vcpkg branch if submodule exists
  if exist "%CUSTOM_REGISTRY_DIR%\.git" (
    git -C "%CUSTOM_REGISTRY_DIR%" fetch origin vcpkg 2>nul || echo Note: Could not fetch vcpkg branch
    git -C "%CUSTOM_REGISTRY_DIR%" checkout origin/vcpkg 2>nul || echo Note: Could not checkout vcpkg branch
  )
)

if exist "%VCPKG_DIR%\vcpkg.exe" (
  echo vcpkg already installed at %VCPKG_DIR%
  goto :vcpkg_bootstrap
)

mkdir "%ROOT_DIR%\external" 2>nul

echo Cloning vcpkg to %VCPKG_DIR%...
git clone https://github.com/microsoft/vcpkg.git "%VCPKG_DIR%"

:vcpkg_bootstrap

call "%VCPKG_DIR%\bootstrap-vcpkg.bat" -disableMetrics

echo vcpkg installed at %VCPKG_DIR%
endlocal
