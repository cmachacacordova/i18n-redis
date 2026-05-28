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

11. **Integrate vcpkg.** Maintain `vcpkg.json` with proper deps. Detect vcpkg via `VCPKG_HOME` env var — use it if valid, otherwise auto-install into `external/vcpkg`. Provide `install_vcpkg` script (clone, bootstrap, validate) for Windows/Linux/macOS. All presets and scripts must auto-detect the vcpkg instance.

12. **Enable strict compiler warnings** on MSVC, GCC, and Clang. Fix warnings instead of suppressing them.

13. **Configure testing.** CTest integration. Portable tests. Add or improve as needed.

14. **Write documentation in English.** Cover: build/install instructions, dependency setup, vcpkg usage, API usage, export/import, platform notes, preset usage, static/shared examples, enabling examples/tests.

15. **Configure CI/CD.** GitHub Actions: multi-platform, multi-compiler, static/shared, Debug/Release. Must use `out/build` and the same presets as local builds. Optimize vcpkg caching. CI triggers on tag push (`push.tags: ['*-SNAPSHOT', '*-RELEASE']`) and **only creates the GitHub Release** (with build artifacts). CI does NOT create tags.

16. **Create a versioning script** (name and language at discretion — no Python — placed in `scripts/`). The script must:
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

17. **Build and validate.** Compile all four variants (static/shared x debug/release). Verify install/export and downstream consumption. Validate on multiple compilers when possible.

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