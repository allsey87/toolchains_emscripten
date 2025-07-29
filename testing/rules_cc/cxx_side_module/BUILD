load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_shared_library")
load("@toolchains_emscripten//toolchain:emscripten_binary.bzl", "emscripten_binary")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

cc_library(
    name = "cxx_side_module_lib",
    cxxopts = ["-fwasm-exceptions", "-fPIC"],
    srcs = ["src/test.cxx"],
)

cc_shared_library(
    name = "cxx_side_module",
    deps = [":cxx_side_module_lib"],
    user_link_flags = ["-fwasm-exceptions", "-sSIDE_MODULE", "-sSTRICT"]
)

cc_library(
    name = "cxx_main_module_lib",
    cxxopts = ["-fwasm-exceptions", "-fPIC"],
    srcs = ["src/main.cxx"],
)

emscripten_binary(
    name = "cxx_main_module",
    deps = [":cxx_main_module_lib"],
    linkopts = ["-fwasm-exceptions", "-sMAIN_MODULE",  "-sSTRICT", "-lstubs"],
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./cxx_main_module.js')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":cxx_main_module", ":cxx_side_module"],
    timeout = "short",
)