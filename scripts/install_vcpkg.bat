@echo off
setlocal EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

set VCPKG_DIR=%ROOT_DIR%\external\vcpkg

if exist "%VCPKG_DIR%\vcpkg.exe" (
  echo vcpkg already installed at %VCPKG_DIR%
  goto :eof
)

mkdir "%ROOT_DIR%\external" 2>nul

echo Cloning vcpkg to %VCPKG_DIR%...
git clone https://github.com/microsoft/vcpkg.git "%VCPKG_DIR%"

call "%VCPKG_DIR%\bootstrap-vcpkg.bat" -disableMetrics

echo vcpkg installed at %VCPKG_DIR%
endlocal
