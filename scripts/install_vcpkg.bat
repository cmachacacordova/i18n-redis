@echo off
setlocal
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd
set VCPKG_DIR=%ROOT_DIR%\external\vcpkg

if exist "%VCPKG_DIR%" (
    echo vcpkg ya esta instalado en %VCPKG_DIR%
    goto :eof
)

mkdir "%ROOT_DIR%\external" 2>NUL

echo Clonando vcpkg en %VCPKG_DIR%...
git clone https://github.com/microsoft/vcpkg.git "%VCPKG_DIR%"

call "%VCPKG_DIR%\bootstrap-vcpkg.bat" -disableMetrics

echo vcpkg instalado en %VCPKG_DIR%
endlocal
