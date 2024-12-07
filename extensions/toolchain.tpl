""

#load("@rules_python//python:defs.bzl", "py_binary")
load("@toolchains_emscripten//toolchain:config.bzl", "emscripten_toolchain_config")

# How do I stop this from using the toolchain that I am trying to define??
py_binary(
    name = "emcc",
    srcs = ["install/emscripten/emcc.py"],
    main = "install/emscripten/emcc.py",
    
    # this breaks the loop when we bazel run emcc but does not allow us to invoke it
    # as a compiler
    # https://bazel.build/extending/toolchains#toolchain-resolution
    # exec_compatible_with = ["@platforms//os:linux"],
)

# # This might be needed to if the shebang is not in place / if runfiles are not accepted
# # https://stackoverflow.com/questions/78703242/how-do-i-provide-a-py-binarys-runfiles-to-a-c-toolchain-in-bazel
# filegroup(
#   name = "emcc_wrapper_zip",
#   srcs = [":emcc"],
#   output_group = "python_zip_file",
# )
# genrule(
#   name = "emcc_wrapper_zip_executable",
#   srcs = [":emcc_wrapper_zip"],
#   outs = ["emcc_wrapper_zip_executable.zip"],
#   cmd = "echo '#!/usr/bin/env python3' | cat - $< >$@",
#   executable = True,
# )

# using attrs I can set all the binaries here.
emscripten_toolchain_config(
    name = "emscripten_toolchain_config",
    emcc = ":emcc"
    # override attributes specified above
)

# Define our cc_toolchain
# (https://bazel.build/reference/be/c-cpp#cc_toolchain).
# The cc_toolchain rule is pre-defined by the C++ rule owners. It uses these
# parameters to construct a ToolchainInfo provider, as required by Bazel's
# platform/toolchain APIs.

# dummy group, to be replaced with Emscripten
filegroup(name = "toolchain_files")

cc_toolchain(
    name = "emscripten_cc_toolchain",
    all_files = ":toolchain_files",
    compiler_files = ":toolchain_files",
    dwp_files = ":toolchain_files",
    linker_files = ":toolchain_files",
    objcopy_files = ":toolchain_files",
    strip_files = ":toolchain_files",
    toolchain_config = ":emscripten_toolchain_config",
)

# Bazel's platform/toolchain APIs require this wrapper around the actual
# toolchain defined above. It serves two purposes: declare which
# constraint_values it supports (which can be matched to appropriate platforms)
# and tell Bazel what language this toolchain is for.
#
# So when you're building a cc_binary, Bazel has all the info it needs to give
# that cc_binary the right toolchain: it knows cc_binary requires a "C++-type
# toolchain" (this is encoded in the cc_binary rule definition) and needs to
# use a toolchain that matches whatever you set --platforms to at the command
# line.
toolchain(
    name = "toolchain",
    target_compatible_with = ["@platforms//cpu:wasm32"],   
    toolchain = ":emscripten_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
