@echo off
setlocal EnableDelayedExpansion

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

if not defined VCPKG_HOME (
  echo Error: VCPKG_HOME is not set. >&2
  echo        set VCPKG_HOME=C:\path\to\vcpkg >&2
  exit /b 1
)

if not exist "%VCPKG_HOME%\vcpkg.exe" (
  echo Error: vcpkg.exe not found in VCPKG_HOME=%VCPKG_HOME% >&2
  exit /b 1
)

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

echo Using vcpkg: %VCPKG_HOME%\vcpkg.exe

echo Updating git submodules...
git -C "%ROOT_DIR%" submodule update --init --remote --merge 2>nul || echo Note: Could not update submodules

set PRESET=windows-msvc-%TYPE%-%MODE%

cmake --preset %PRESET% --fresh
cmake --build out\build --parallel

endlocal
