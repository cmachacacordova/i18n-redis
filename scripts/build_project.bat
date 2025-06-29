@echo off
setlocal

if "%~2"=="" (
    echo Uso: %~nx0 ^<static^|shared^|both^> ^<release^|debug^>
    exit /b 1
)

set TYPE=%1
set MODE=%2

if /I "%TYPE%"=="static" (
    set PRESET=windows-static
    set TRIPLET=x64-windows-static-md
) else if /I "%TYPE%"=="shared" (
    set PRESET=windows-shared
    set TRIPLET=x64-windows
) else if /I "%TYPE%"=="both" (
    set PRESET=windows-both
    set TRIPLET=x64-windows-static-md
) else (
    echo Uso: %~nx0 ^<static^|shared^|both^> ^<release^|debug^>
    exit /b 1
)

if /I "%MODE%"=="debug" (
    set MODE=debug
) else if /I "%MODE%"=="release" (
    set MODE=release
) else (
    echo Uso: %~nx0 ^<static^|shared^|both^> ^<release^|debug^>
    exit /b 1
)

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

call "%SCRIPT_DIR%install_vcpkg.bat"

set VCPKG_EXE=%ROOT_DIR%\external\vcpkg\vcpkg.exe

call "%VCPKG_EXE%" install --triplet %TRIPLET%

set PRESET=%PRESET%-%MODE%

cmake --preset %PRESET%
cmake --build out\%PRESET%

endlocal
