""

load("@rules_python//python:defs.bzl", "py_binary")
load("@toolchains_emscripten//toolchain:config.bzl", "emscripten_toolchain_config", "emscripten_combine_cache")
load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")

load("//:repo_config.bzl", "install_dir", "embuilder_invocations")

filegroup(
    name = "assets",
    srcs = glob([
        "install/bin/**/*",
        "install/emscripten/node_modules/**/*"
    ])
)

filegroup(
    name = "prebuilt_cache",
    srcs = glob([
        "install/emscripten/cache/**/*",
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

[
    run_binary(
        name = "generate_cache{}".format("".join(arguments).replace("-", "_")),
        tool = ":embuilder",
        args = arguments + ["build"] + targets,
        outs = [
            "install/emscripten/cache/sysroot/lib/" + cache_suffix + target + (
                ".a" if target.startswith("lib") else ".o"
            ) for target in targets
        ],
        env = {
            "BZL_BINARYEN_ROOT": install_dir,
            "BZL_LLVM_ROOT": install_dir + "/bin",
            "BZL_EMSCRIPTEN_ROOT": install_dir + "/emscripten",
            "BZL_NODE_JS": "/bin/false",
            "BZL_CACHE": "$(RULEDIR)/install/emscripten/cache",
            "EM_IGNORE_SANITY": "1",
            "EM_FROZEN_CACHE": "0",
        },
        progress_message = "Generating Emscripten cache",
        mnemonic = "EmscriptenCacheGenerate"
    )
    for arguments, cache_suffix, targets in embuilder_invocations
]

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

py_binary(
    name = "empp",
    deps = [":emscripten"],
    srcs = ["install/emscripten/em++.py"],
    main = "install/emscripten/em++.py",
)
filegroup(
  name = "empp_zip",
  srcs = [":empp"],
  output_group = "python_zip_file",
)
genrule(
  name = "empp_zip_executable",
  srcs = [":empp_zip"],
  outs = ["empp_zip_executable.zip"],
  # TODO add a cmd_ps: on Windows this should just be a no-op
  cmd_bash = "echo '#!/usr/bin/env python3' | cat - $< >$@",
  executable = True,
)


emscripten_combine_cache(
    name = "cache",
    prebuilt_cache = ":prebuilt_cache",
    generated_caches = [
        "generate_cache{}".format("".join(arguments).replace("-", "_"))
        for arguments, _, _ in embuilder_invocations
    ]
)

# this is just a simple rule that returns a CcToolchainConfigInfo
# only thing this is doing with :cache and :assets is setting up the environment variables like BZL_CACHE
# the actual making-available of these files occurs via the cc_toolchain options below
emscripten_toolchain_config(
    name = "emscripten_toolchain_config",
    assets = ":assets",
    cache = ":cache",
    emcc = ":emcc_zip_executable",
    empp = ":empp_zip_executable",
    node = "@nodejs//:node_bin",
)

filegroup(
    name = "empty",
)
filegroup(
    name = "compiler_files",
    srcs = [":emcc_zip_executable", ":empp_zip_executable", "@nodejs//:node_bin", ":assets", ":cache"]
)
filegroup(
    name = "linker_files",
    # NOTE assets only contains the prebuilt cache and not the generated PIC version of crt1.o
    srcs = [":emcc_zip_executable", ":empp_zip_executable", "@nodejs//:node_bin", ":assets", ":cache"]
)

# I think all_files, compiler_files etc. just require the DefaultInfo provider (file) since no other provider is specified
cc_toolchain(
    name = "emscripten_cc_toolchain",
    all_files = ":empty",
    compiler_files = ":compiler_files",
    dwp_files = ":empty",
    linker_files = ":linker_files",
    objcopy_files = ":empty",
    strip_files = ":empty",
    toolchain_config = ":emscripten_toolchain_config", # this input requires the CcToolchainConfigInfo provider
)

toolchain(
    name = "toolchain",
    target_compatible_with = ["@platforms//cpu:wasm32"],
    toolchain = ":emscripten_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
