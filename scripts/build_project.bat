@echo off
setlocal

if "%~2"=="" (
    echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^>
    exit /b 1
)

set TYPE=%1
set MODE=%2

if /I "%TYPE%"=="static" (
    set TRIPLET=x64-windows-static-md
) else if /I "%TYPE%"=="shared" (
    set TRIPLET=x64-windows
) else (
    echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^>
    exit /b 1
)

if /I "%MODE%"=="debug" (
    set MODE=debug
) else if /I "%MODE%"=="release" (
    set MODE=release
) else (
    echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^>
    exit /b 1
)

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

call "%SCRIPT_DIR%install_vcpkg.bat"

set VCPKG_EXE=%ROOT_DIR%\external\vcpkg\vcpkg.exe
set OVERLAY=%ROOT_DIR%\ports-overlay

call "%VCPKG_EXE%" install --triplet %TRIPLET% --overlay-ports=%OVERLAY%

set PRESET=windows-msvc-%TYPE%-%MODE%

cmake --preset %PRESET%
cmake --build --preset %PRESET% --clean-first --parallel

endlocal
