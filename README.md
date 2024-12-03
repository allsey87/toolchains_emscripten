# toolchains_emscripten

The goal of this repository is to make it possible to build executables and static and shared libraries using the Emscripten toolchain from inside of Bazel. The goal is to support C/C++ and Rust and, in addition to being compatible with the functions from `rules_cc` and `rules_rust`, to support all build systems and configurations which are provided via `rules_foreign_cc`.
