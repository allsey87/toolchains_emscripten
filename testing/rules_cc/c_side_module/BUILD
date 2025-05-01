load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_shared_library")
load("@toolchains_emscripten//toolchain:emscripten_binary.bzl", "emscripten_binary")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

cc_library(
    name = "c_side_module_lib",
    copts = ["-fPIC"],
    srcs = ["src/test.c"],
)

cc_shared_library(
    name = "c_side_module",
    deps = [":c_side_module_lib"],
    user_link_flags = ["-sSIDE_MODULE", "-sSTRICT"]
)

cc_library(
    name = "c_main_module_lib",
    copts = ["-fPIC"],
    srcs = ["src/main.c"],
)

emscripten_binary(
    name = "c_main_module",
    deps = [":c_main_module_lib"],
    linkopts = ["-sMAIN_MODULE",  "-sSTRICT"],
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./c_main_module.js')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":c_main_module", ":c_side_module"],
    timeout = "short",
)