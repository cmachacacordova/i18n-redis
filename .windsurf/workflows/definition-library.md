---
description: Modernize and build C++ library project
---

# Constraints

## Language
- C++20. Use a lower standard only if a dependency explicitly requires it.
- No undefined behavior (UB).
- Prefer RAII, smart pointers, STL containers, constexpr, std::span, std::string_view.
- Reduce macro usage. Use scoped enums and strong typing.
- camelCase naming convention for all identifiers.
- Code style: strictly LLVM (2-space indent, K&R braces, `BasedOnStyle: LLVM` for clang-format).

## Portability
- Must compile on: MSVC, GCC, Clang.
- Must run on: Windows, Linux, macOS (when possible).
- No compiler-specific hacks unless strictly necessary.
- Prefer standard library features over external dependencies.
- Keep the codebase fully portable — avoid platform-specific code unless isolated behind abstractions.

## Build Policy
- Modern CMake >= 3.25. Target-based configuration only (no global flags).
- All build artifacts go to a single directory: `out/build`. No nested platform/compiler subdirs.
- All scripts, presets, CI/CD pipelines, and configs must use `out/build` consistently.
- Modify any existing config that violates this policy.

## Dependencies
- Consult official docs before modifying any dependency or toolchain config.
- All external deps must be declared in `vcpkg.json` and managed through vcpkg.
- Prefer official vcpkg packages. Replace outdated or unsafe deps.

## Tooling Requirements
- **Clang with LTO/IPO**: When using Clang compiler presets with LTO/IPO enabled, the CMake preset must define:
  - `CMAKE_CXX_COMPILER_AR: llvm-ar`
  - `CMAKE_CXX_COMPILER_RANLIB: llvm-ranlib`
  These tools are required for CMake's IPO/LTO test to pass when building static libraries with ThinLTO.
- **Strict warnings compliance**: With strict compiler warnings enabled (`-Werror`), ensure:
  - Exception specifications match between declarations and definitions (e.g., `noexcept`)
  - All virtual destructors have consistent specifiers
  - Fix all warnings rather than suppressing them

## Scope
- This workflow generates or fixes a library project from scratch. Do NOT use the current project state as context — treat every run as if starting from zero.

## Modification Policy
- You may modify any file, remove unused files, and restructure the project at discretion.
- Fix warnings instead of suppressing them.
- Prioritize maintainability, portability, clarity, and correctness over preserving legacy.

# Steps

1. **Analyze the project.** Read every source file, header, build script, and config. Identify: architecture, deps, ABI/API surface, threading, memory management, portability issues, install/export structure. Flag obsolete, deprecated, unsafe, or non-portable code.

2. **Analyze dependencies.** List all external deps. Verify each is maintained and portable. Prefer vcpkg packages. Replace outdated or unsafe deps. Check licensing.

3. **Audit performance.** Detect unnecessary allocations/copies, cache misses, contention, bad algorithms, excessive virtual dispatch, blocking ops, bad threading. Fix without harming maintainability.

4. **Audit security.** Detect buffer/integer overflows, dangling pointers, races, unsafe casts, UB, leaks, invalid ownership, unsafe FS/API usage, exception safety issues. Apply modern replacements.

5. **Modernize code.** Refactor to modern C++. Improve const-correctness, noexcept, encapsulation, API clarity. Reduce macros. Use scoped enums and strong typing. Remove legacy patterns.

6. **Clean the project.** Remove unused, obsolete, duplicated, dead, or generated files. Clean legacy build artifacts. Preserve project integrity.

7. **Configure the build system.** Use modern CMake >= 3.25 with target-based config (no global flags). Configure: static/shared libs, all build types (Debug, Release, RelWithDebInfo, MinSizeRel), install rules, export targets, package/version config, include dirs, interface/public/private deps.

8. **Add CMake options for examples and tests.** Create `BUILD_EXAMPLES` and `BUILD_TESTS` options (default OFF). They must not compile unless explicitly enabled.

9. **Set up the output directory.** All build artifacts go to `out/build` — CMake, presets, scripts, tests, CI/CD, everything. No nested platform/compiler subdirs. Modify any config that violates this.

10. **Create CMake presets.** Use naming pattern `{platform}-{compiler}-{linkage}-{config}`:
    - MSVC: `windows-msvc-{static,shared}-{debug,release}`
    - GCC: `linux-gcc-{static,shared}-{debug,release}`
    - Clang: `linux-clang-{static,shared}-{debug,release}`, `macos-clang-{static,shared}-{debug,release}`
    - Optional: ASan, UBSan, LTO/IPO presets.
    - All presets use `binaryDir: out/build`. Support clean rebuilds. Document usage.

11. **Integrate vcpkg.** Maintain `vcpkg.json` with proper deps. All scripts, presets, and CMake configs must follow this vcpkg detection order:
    1. Check `VCPKG_HOME` env var — if set and points to a valid vcpkg installation, use it.
    2. Otherwise, install vcpkg locally into `external/vcpkg`.
    - Provide an `install_vcpkg` script (name at discretion, in `scripts/`) that clones, bootstraps, and validates vcpkg. Must work on Windows, Linux, and macOS.
    - **Important:** vcpkg isolates packages by triplet (e.g., `x64-linux` vs `x64-linux-dynamic`). Switching between static/shared builds requires reinstalling all dependencies. To avoid unnecessary rebuilds when a system `VCPKG_HOME` exists but has incompatible triplets, the build script should prefer the local `external/vcpkg` installation.

12. **Create build scripts** (in `scripts/`, for Windows `.bat` and Linux/macOS `.sh`). Each build script must:
    - Accept arguments for linkage (static/shared) and config (debug/release).
    - Detect vcpkg using this order: check local `external/vcpkg` first, then fall back to `VCPKG_HOME` env var. This prevents unnecessary dependency reinstallations when switching between static/shared builds.
    - If vcpkg is not found anywhere, call the `install_vcpkg` script automatically.
    - Configure and build with CMake using the correct preset (vcpkg toolchain handles dependency installation automatically during CMake configure).
    - All output goes to `out/build`.

13. **Enable strict compiler warnings** on MSVC, GCC, and Clang. Fix warnings instead of suppressing them.

14. **Configure testing.** CTest integration. Portable tests. Add or improve as needed.

15. **Write documentation in English.** Cover: build/install instructions, dependency setup, vcpkg usage, API usage, export/import, platform notes, preset usage, static/shared examples, enabling examples/tests.

16. **Configure CI/CD.** GitHub Actions: multi-platform, multi-compiler, static/shared, Debug/Release. Must use `out/build` and the same presets as local builds. Optimize vcpkg caching. CI triggers on tag push (`push.tags: ['*-SNAPSHOT', '*-RELEASE']`) and **only creates the GitHub Release** (with build artifacts). CI does NOT create tags.

17. **Create a versioning script** (name and language at discretion — no Python — placed in `scripts/`). The script must:
    - Accept one argument: `snapshot` or `release`.
    - Accept an optional version argument (e.g. `1.2.3`). If omitted, read current version from `CMakeLists.txt` (`project(... VERSION X.Y.Z ...)`).
    - Generate the full version string:
      - `snapshot` → `X.Y.Z-<7-char git hash>-SNAPSHOT`
      - `release` → `X.Y.Z-RELEASE`
    - Update `CMakeLists.txt` project VERSION and `vcpkg.json` version field to the generated string.
    - **`vcpkg.json` must use `"version-string"` (not `"version"`)** because the custom format (`X.Y.Z-hash-SNAPSHOT`, `X.Y.Z-RELEASE`) does not conform to relaxed semver. This is the official vcpkg scheme for arbitrary version strings.
    - Commit the version changes and create the tag locally.
    - Push the commit and tag to origin.
    - The script must be portable (run on Linux/macOS; Windows via Git Bash).

18. **Build and validate.** Compile all four variants (static/shared x debug/release). Verify install/export and downstream consumption. Validate on multiple compilers when possible.

# Expected Structure

```
project/
├── CMakeLists.txt
├── CMakePresets.json
├── vcpkg.json
├── include/
├── src/
├── tests/
├── examples/
├── docs/
├── cmake/
├── out/build/
└── external/vcpkg/
```