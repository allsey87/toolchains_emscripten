""

load("@rules_python//python:defs.bzl", "py_binary")
load("@toolchains_emscripten//toolchain:config.bzl", "emscripten_toolchain_config")

filegroup(
    name = "assets",
    srcs = glob([
        "install/bin/**/*",
        "install/emscripten/cache/**/*",
        "install/emscripten/node_modules/**/*"
    ])
)

py_library(
    name = "emscripten",
    data = glob([
            "install/**/*"
        ],
        exclude = [
            "install/emscripten/**/*.py",
            "install/bin/**/*",
            "install/emscripten/cache/**/*",
            "install/emscripten/test/**/*",
            # it would be nice if we could also exclude install/emscripten/node_modules from here
            # https://stackoverflow.com/a/26293141/5164339 I would have to be able to set NODE_PATH
            # NOTE this seems to work, but it is unclear why
            "install/emscripten/node_modules/**/*",
        ]
    ),
    srcs = glob([
            "install/emscripten/**/*.py"
        ]
    ),
    imports = [
        "install/emscripten",
        "install/emscripten/third_party"
    ],
)

py_binary(
    name = "emcc_wrapper",
    deps = [":emscripten"],
    srcs = ["install/emscripten/emcc.py"],
    main = "install/emscripten/emcc.py",
)

filegroup(
  name = "emcc_wrapper_zip",
  srcs = [":emcc_wrapper"],
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
    assets = ":assets",
    emcc = ":emcc_wrapper_zip_executable",
    node = "@nodejs//:node_bin",
)

filegroup(
    name = "empty",
)
filegroup(
    name = "compiler_files",
    srcs = [":emcc_wrapper_zip_executable", "@nodejs//:node_bin", ":assets"]
)
filegroup(
    name = "linker_files",
    srcs = [":emcc_wrapper_zip_executable", "@nodejs//:node_bin", ":assets"]
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
