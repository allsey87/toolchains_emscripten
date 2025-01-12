""

load("@rules_python//python:defs.bzl", "py_binary")
load("@toolchains_emscripten//toolchain:config.bzl", "emscripten_toolchain_config")
load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")

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
    name = "embuilder",
    deps = [":emscripten"],
    srcs = ["install/emscripten/embuilder.py"],
    main = "install/emscripten/embuilder.py",
)

# NOTE I could use list comprehension here to create N instances of this rule for each invocation
# However, this would probably be inefficient since the cache is always locked and it requires
# a lot of starting and stopping
run_binary(
    name = "generate_cache",
    tool = ":embuilder",
    args = ["--pic", "build", "crt1"],
    # NOTE I need to merge this output with the prebuilt cache and pass it to the toolchain
    outs = ["cache/sysroot/lib/wasm32-emscripten/pic/crt1.o"],
    env = {
        "BZL_BINARYEN_ROOT": "@@INSTALL_DIR@@",
        "BZL_LLVM_ROOT":"@@INSTALL_DIR@@/bin",
        "BZL_EMSCRIPTEN_ROOT": "@@INSTALL_DIR@@/emscripten",
        "BZL_NODE_JS": "/bin/false",
        "BZL_CACHE": "$(RULEDIR)/cache",
        "EM_IGNORE_SANITY": "1",
        "EM_FROZEN_CACHE": "0",
    },
    progress_message = "Generating Emscripten cache",
    mnemonic = "EmscriptenCacheGenerate"
)

### emcc ###
py_binary(
    name = "emcc",
    deps = [":emscripten"],
    srcs = ["install/emscripten/emcc.py"],
    main = "install/emscripten/emcc.py",
)
filegroup(
  name = "emcc_zip",
  srcs = [":emcc"],
  output_group = "python_zip_file",
)
genrule(
  name = "emcc_zip_executable",
  srcs = [":emcc_zip"],
  outs = ["emcc_zip_executable.zip"],
  # TODO add a cmd_ps: on Windows this should just be a no-op
  cmd_bash = "echo '#!/usr/bin/env python3' | cat - $< >$@",
  executable = True,
)

emscripten_toolchain_config(
    name = "emscripten_toolchain_config",
    assets = ":assets",
    emcc = ":emcc_zip_executable",
    node = "@nodejs//:node_bin",
)

filegroup(
    name = "empty",
)
filegroup(
    name = "compiler_files",
    srcs = [":emcc_zip_executable", "@nodejs//:node_bin", ":assets"]
)
filegroup(
    name = "linker_files",
    # NOTE assets only contains the prebuilt cache and not the generated PIC version of crt1.o
    srcs = [":emcc_zip_executable", "@nodejs//:node_bin", ":assets"]
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
