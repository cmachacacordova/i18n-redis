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

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

set VCPKG_DIR=%ROOT_DIR%\external\vcpkg

if exist "%VCPKG_DIR%\vcpkg.exe" (
  set VCPKG_EXE=%VCPKG_DIR%\vcpkg.exe
  goto :vcpkg_found
)

if defined VCPKG_HOME (
  if exist "%VCPKG_HOME%\vcpkg.exe" (
    set VCPKG_EXE=%VCPKG_HOME%\vcpkg.exe
    goto :vcpkg_found
  )
)

echo vcpkg not found. Installing to %VCPKG_DIR%...
call "%SCRIPT_DIR%install_vcpkg.bat"

if exist "%VCPKG_DIR%\vcpkg.exe" (
  set VCPKG_EXE=%VCPKG_DIR%\vcpkg.exe
) else (
  echo Error: vcpkg installation failed
  exit /b 1
)

:vcpkg_found
echo Using vcpkg: %VCPKG_EXE%

for %%I in ("%VCPKG_EXE%") do set VCPKG_HOME=%%~dpI

echo Updating git submodules...
git -C "%ROOT_DIR%" submodule update --init --remote --merge 2>nul || echo Note: Could not update submodules

set PRESET=windows-msvc-%TYPE%-%MODE%

cmake --preset %PRESET% --fresh
cmake --build out\build --parallel

endlocal
