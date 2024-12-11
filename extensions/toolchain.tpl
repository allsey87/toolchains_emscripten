""

load("@rules_python//python:defs.bzl", "py_binary")
load("@toolchains_emscripten//toolchain:config.bzl", "emscripten_toolchain_config")

py_binary(
    name = "emcc",
    srcs = ["install/emscripten/emcc.py"],
    main = "install/emscripten/emcc.py",
)
filegroup(
  name = "emcc_wrapper_zip",
  srcs = [":emcc"],
  output_group = "python_zip_file",
)
genrule(
  name = "emcc_wrapper_zip_executable",
  srcs = [":emcc_wrapper_zip"],
  outs = ["emcc_wrapper_zip_executable.zip"],
  cmd_bash = "echo '#!/usr/bin/env python3' | cat - $< >$@",
  executable = True,
)

emscripten_toolchain_config(
    name = "emscripten_toolchain_config",
    emcc = ":emcc_wrapper_zip_executable"
)

# TODO I probably need to include the system headers and libraries and pass them
# into the toolchain here
filegroup(
    name = "toolchain_files",
)

cc_toolchain(
    name = "emscripten_cc_toolchain",
    all_files = ":toolchain_files",
    compiler_files = ":emcc_wrapper_zip_executable",
    dwp_files = ":toolchain_files",
    linker_files = ":toolchain_files",
    objcopy_files = ":toolchain_files",
    strip_files = ":toolchain_files",
    toolchain_config = ":emscripten_toolchain_config",
)

toolchain(
    name = "toolchain",
    target_compatible_with = ["@platforms//cpu:wasm32"],
    toolchain = ":emscripten_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
