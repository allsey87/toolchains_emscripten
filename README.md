# toolchains_emscripten

The goal of this repository is to make it possible to build executables and static and shared libraries using the Emscripten toolchain from inside of Bazel.

## Motivation
The obvious question that needs to be answered is why not create patches for the [existing Bazel toolchain in emsdk](https://github.com/emscripten-core/emsdk/tree/main/bazel)? In short, the support for Bazel in the emsdk repository is quite old, perhaps older than Bazel (but not Blaze) itself. While the existing support has received patches from various developers over the past years, it has not received enough attention and now contains a lot of legacy code and is not well understood.

Another source of motivation is the ongoing migration to Bzlmod. Emscripten's support for Bazel relies on using a `WORKSPACE` which has already been disabled in Bazel 8 and will be removed in Bazel 9 (see [Bzlmod Migration Guide](https://bazel.build/external/migration)).

Considering these points and the goals below, creating a new module for the Emscripten toolchain in Bazel that follows modern guidelines and is not limited by backwards compatibility is worth the effort.

## Goals
- Create a module that can be contributed to the [Bazel Central Repository](https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/README.md) and added as a dependency using `bazel_dep`.
- No strange defaults such as [precise_long_double_printf](https://github.com/emscripten-core/emsdk/blob/85390ce88465e18c1c5d2f8d7f6ed21f3e8e8678/bazel/emscripten_toolchain/toolchain.bzl#L443-L446). This toolchain should behave like vanilla Emscripten.
- Use `py_binary` to run Emscripten tools. Emsdk currently uses the first interpreter found in `PATH` which is not hermetic and causes issues when interacting with Python-based build systems like Meson.
- Good interoperability with other build systems such as CMake, GNU Make, Meson, Ninja.
- Support for building static and shared libraries.
- Interoperability with `rules_rust` (e.g., for building Rust-based Python extensions).
- Comprehensive testing of build outputs (running compiled artifacts in nodejs).
- Decouple the versioning of this module from Emscripten and implement semantic versioning.
