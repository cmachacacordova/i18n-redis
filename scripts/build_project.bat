@echo off
setlocal EnableDelayedExpansion

if "%~2"=="" (
  echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^> [simdjson^|yyjson]
  echo.
  echo   If VCPKG_HOME is unset, the bundled submodule (extras\vcpkg) is used automatically.
  exit /b 1
)

set TYPE=%1
set MODE=%2
set JSON_BACKEND=%3
if "%~3"=="" set JSON_BACKEND=simdjson

if /I "%TYPE%"=="static" (
  echo Building static library
) else if /I "%TYPE%"=="shared" (
  echo Building shared library
) else (
  echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^> [simdjson^|yyjson]
  exit /b 1
)

if /I "%MODE%"=="debug" (
  set MODE=debug
) else if /I "%MODE%"=="release" (
  set MODE=release
) else (
  echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^> [simdjson^|yyjson]
  exit /b 1
)

if /I "%JSON_BACKEND%"=="simdjson" (
  echo Using JSON backend: simdjson
) else if /I "%JSON_BACKEND%"=="yyjson" (
  echo Using JSON backend: yyjson
) else (
  echo Usage: %~nx0 ^<static^|shared^> ^<debug^|release^> [simdjson^|yyjson]
  exit /b 1
)

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%.."
set ROOT_DIR=%CD%
popd

if "%VCPKG_HOME%"=="" (
  set SUBMODULE_VCPKG=%ROOT_DIR%\extras\vcpkg
  echo VCPKG_HOME is not set -- using bundled submodule at extras\vcpkg
  git -C "%ROOT_DIR%" submodule update --init --recursive extras/vcpkg
  if not exist "%ROOT_DIR%\extras\vcpkg\vcpkg.exe" (
    echo Bootstrapping vcpkg...
    call "%ROOT_DIR%\extras\vcpkg\bootstrap-vcpkg.bat" -disableMetrics
  )
  set VCPKG_HOME=%ROOT_DIR%\extras\vcpkg
  echo   VCPKG_HOME set to: %VCPKG_HOME%
  echo.
)

if /I "%JSON_BACKEND%"=="yyjson" (
  set PRESET=windows-msvc-%TYPE%-%MODE%-yyjson
) else (
  set PRESET=windows-msvc-%TYPE%-%MODE%
)

echo Build configuration:
echo   Type:         %TYPE%
echo   Mode:         %MODE%
echo   JSON backend: %JSON_BACKEND%
echo   VCPKG_HOME:   %VCPKG_HOME%
echo.

cmake --preset %PRESET% --fresh -S "%ROOT_DIR%"
cmake --build --preset %PRESET% --parallel

endlocal
