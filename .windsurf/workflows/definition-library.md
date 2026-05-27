---
description: Modernize and build C++ library project
---

Role: Senior Software Engineer specialized in Modern C++ and Cross-Platform Architecture.

Primary Objectives:
- Analyze, modernize, secure, optimize, document, and build the entire project.
- The project must become portable, maintainable, easy to integrate, and production-ready.
- The final result must compile successfully as both static and shared libraries.
- The library must generate both Debug and Release binaries.

Global Rules:
- Use only C++.
- Use the C++ version currently adopted by most modern compilers (prefer C++20 unless a dependency requires otherwise).
- Before modifying code, search and consult the official documentation of all libraries, frameworks, toolchains, and dependencies used by the project.
- Prefer modern tooling, modern CMake practices, and portable solutions.
- Avoid compiler-specific hacks unless absolutely required.
- Maintain compatibility with:
  - MSVC
  - GCC
  - Clang
- Maintain compatibility with:
  - Windows
  - Linux
  - macOS (when possible)
- Avoid undefined behavior (UB).
- Prefer RAII, smart pointers, STL containers, constexpr, spans, string_view, and modern language features when appropriate.
- Use camelCase naming convention.
- Keep the codebase fully portable.
- Avoid unnecessary external dependencies.
- Prefer standard library features whenever possible.

Required Tasks:

1. Project Analysis
- Analyze the entire codebase.
- Analyze:
  - architecture,
  - dependencies,
  - frameworks,
  - build system,
  - compiler requirements,
  - ABI/API exposure,
  - threading model,
  - memory management,
  - portability issues,
  - platform-specific code,
  - binary compatibility,
  - install/export structure.
- Identify obsolete, deprecated, unsafe, or non-portable code.

2. Dependency Analysis
- Identify all external dependencies.
- Verify if dependencies are maintained and portable.
- Prefer official packages from vcpkg whenever possible.
- Replace outdated or unsafe dependencies when appropriate.
- Verify licensing compatibility if needed.

3. Performance Analysis
- Detect:
  - unnecessary allocations,
  - copies,
  - cache inefficiencies,
  - locking/contention problems,
  - inefficient algorithms,
  - excessive virtual dispatch,
  - blocking operations,
  - bad threading patterns.
- Optimize where appropriate without harming maintainability.

4. Security Analysis
- Detect:
  - buffer overflows,
  - integer overflows,
  - dangling pointers,
  - race conditions,
  - unsafe casts,
  - UB,
  - memory leaks,
  - invalid ownership models,
  - unsafe filesystem usage,
  - insecure APIs,
  - exception safety problems.
- Apply secure and modern replacements.

5. Modernization
- Refactor old-style C++ into modern C++.
- Remove legacy patterns when possible.
- Improve const-correctness.
- Improve noexcept usage where applicable.
- Reduce macro usage.
- Use scoped enums and strong typing.
- Improve encapsulation and API clarity.

6. Project Cleanup
- Detect unused, obsolete, duplicated, temporary, generated, dead, or irrelevant files.
- Remove files and directories that are not truly used by the project.
- Clean legacy build artifacts and unnecessary configurations.
- Remove unused source files, headers, scripts, assets, examples, or dependencies when appropriate.
- Perform cleanup at your own discretion while preserving project integrity and required functionality.

7. Build System
- Use modern CMake.
- Minimum recommended CMake version: 3.25+.
- Configure:
  - static library,
  - shared library,
  - Debug builds,
  - Release builds,
  - RelWithDebInfo builds,
  - MinSizeRel builds,
  - install rules,
  - export targets,
  - package config files,
  - version config files,
  - proper include directories,
  - interface/public/private dependencies.
- Avoid global compiler flags.
- Use target-based CMake configuration.

8. Optional Examples and Tests
- Configure the project so examples and tests can be enabled or disabled independently through CMake options.
- Create configurable options such as:
  - BUILD_EXAMPLES
  - BUILD_TESTS
- Examples and tests must not be compiled unless explicitly enabled.
- Ensure the project can be used as a dependency without forcing examples or tests to build.
- Document all available CMake options.

9. Build Outputs
The build system must generate:
- Static Debug library
- Static Release library
- Shared Debug library
- Shared Release library

The output naming and structure must avoid collisions between configurations.

10. CMake Presets
Create presets that allow selecting:
- Library type:
  - Static
  - Shared/Dynamic
- Build configuration:
  - Debug
  - Release
  - RelWithDebInfo
  - MinSizeRel
- Compiler/toolchain:
  - MSVC
  - GCC
  - Clang
- Generator:
  - Ninja
  - Platform default generators

Required preset coverage:

MSVC:
- windows-msvc-static-debug
- windows-msvc-static-release
- windows-msvc-shared-debug
- windows-msvc-shared-release

GCC:
- linux-gcc-static-debug
- linux-gcc-static-release
- linux-gcc-shared-debug
- linux-gcc-shared-release

Clang:
- linux-clang-static-debug
- linux-clang-static-release
- linux-clang-shared-debug
- linux-clang-shared-release
- macos-clang-static-debug
- macos-clang-static-release
- macos-clang-shared-debug
- macos-clang-shared-release

Also create optional presets for:
- AddressSanitizer
- UndefinedBehaviorSanitizer
- LTO/IPO

Presets must be easy to use and properly documented.

11. vcpkg Integration
- Configure the project for vcpkg.
- Create:
  - vcpkg.json
  - proper dependency declarations
- Ensure dependencies can be installed reproducibly.
- Ensure clean integration with CMake toolchains.

12. Compiler Warnings and Quality
Enable strict warnings for all compilers:
- MSVC
- GCC
- Clang

Treat warnings seriously.
Fix warnings instead of suppressing them whenever possible.

13. Testing
- Configure test support using CTest.
- Add or improve tests when needed.
- Ensure tests are portable.

14. Documentation
Generate documentation entirely in English.

Include:
- Build instructions
- Installation instructions
- Dependency setup
- vcpkg usage
- Example integration
- API usage
- Export/import usage
- Platform notes
- Compiler requirements
- Preset usage
- Shared/static linking examples
- Debug/Release usage examples
- How to build static/shared variants
- How to use CMake presets
- How to enable/disable examples and tests

15. CI/CD (Optional but Recommended)
If possible, configure:
- GitHub Actions
- Multi-platform builds
- Multi-compiler validation

16. Deliverables
The final project structure should be clean and maintainable, for example:

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
└── third_party/

17. Final Validation
- Compile the project successfully.
- Generate all library variants:
  - static debug
  - static release
  - shared debug
  - shared release
- Validate builds on different compilers when possible.
- Ensure installation/export works correctly.
- Ensure downstream projects can consume the library cleanly.

18. Modification Policy
- You are allowed to modify any configuration, source code, build scripts, project structure, or architecture when necessary.
- You are also allowed to remove unused or obsolete files and configurations at your own discretion.
- Prioritize long-term maintainability, portability, clarity, and correctness over preserving legacy structure.