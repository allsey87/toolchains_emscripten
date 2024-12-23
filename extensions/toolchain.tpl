""

load("@rules_python//python:defs.bzl", "py_binary")
load("@toolchains_emscripten//toolchain:config.bzl", "emscripten_toolchain_config")
#load("@toolchains_emscripten//toolchain:node_config.bzl", "node_config")
# load("@bazel_skylib//rules:write_file.bzl", "write_file")
#load("@bazel_skylib//rules/directory:directory.bzl", "directory")

# Note that this file is executed by emcc/Python, hence I can put custom logic here to help find llvm root etc.
# This is considerably more powerful than setting environment variables.
# I can even use a combination of reading environment variables from this script
# However, it is limiting in that I don't think there is a way to get the working directory of the current script
# since I am running inside of of exec which is quite limited. I can read some environment variables perhaps?
# but there I have the same problem with not having absolute paths.
# write_file(
#     name = "rule_name",
#     out = "path/to/file.txt",
#     content = [
#     ]
# )
# TODO I should be able to pass directories, I just need to set DirectoryInfo as a provider

# directory(
#     name = "llvm_root",
#     srcs = glob([
#         "install/bin/*"
#     ])
# )

# filegroup(
#     name = "llvm_root",
    # srcs = glob([
    #     "install/bin/*"
    # ])
# )

# write_file(
#     name = "node_config",
#     out = "install/node_config",
#     content = [
#         "NODE_PATH=",

#     ]
# )

# node_config(
#     name = "node_config",
#     install_dir = "@@INSTALL_DIR@@",
#     node = "@nodejs//:node_bin",
# )

# genrule(
#     name = "repository_nodejs",
#     outs = ["repository_nodejs.txt"],
#     cmd = "echo $(rlocationpath @nodejs//:node_bin) >> $(OUTS)",
#     tools = [
#         "@nodejs//:node_bin"
#     ]
# )

py_library(
    name = "emscripten",
    data = glob([
            "install/**/*"
        ],
        exclude = [
            "install/bin/**/*",
            "install/emscripten/cache/**/*",
            "install/emscripten/test/**/*",
            # it would be nice if we could also exclude install/emscripten/node_modules from here
            # https://stackoverflow.com/a/26293141/5164339 I would have to be able to set NODE_PATH
        ]
    ),
    srcs = glob([
            "install/emscripten/tools/**/*.py"
        ]
    ),
    imports = [
        "install/emscripten",
        "install/emscripten/third_party"
    ],
)

py_binary(
    name = "emcc",
    deps = [":emscripten"],
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
    install_dir = "@@INSTALL_DIR@@",
    emcc = ":emcc_wrapper_zip_executable",
    # this can be just expanded inside the rule using expand_location (but it still needs to be passed)
    node = "@nodejs//:node_bin",
)

# TODO I probably need to include the system headers and libraries and pass them
# into the toolchain here
filegroup(
    name = "empty",
)

# It is also possible to pass :emcc_wrapper_zip_executable directly to compiler files
# TODO delete this?
filegroup(
    name = "compiler_files",
    srcs = [":emcc_wrapper_zip_executable", "@nodejs//:node_bin"]
)

filegroup(
    name = "linker_files",
    srcs = [":emcc_wrapper_zip_executable", "@nodejs//:node_bin"]
)

cc_toolchain(
    name = "emscripten_cc_toolchain",
    all_files = ":empty",
    compiler_files = ":compiler_files",
    dwp_files = ":empty",
    linker_files = ":linker_files",
    objcopy_files = ":empty",
    strip_files = ":empty",
    toolchain_config = ":emscripten_toolchain_config",
)

toolchain(
    name = "toolchain",
    target_compatible_with = ["@platforms//cpu:wasm32"],
    toolchain = ":emscripten_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
