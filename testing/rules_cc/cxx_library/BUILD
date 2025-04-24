load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("@toolchains_emscripten//toolchain:emscripten_binary.bzl", "emscripten_binary")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

cc_library(
    name = "cxx_library",
    srcs = ["src/test.cxx"],
)

emscripten_binary(
    name = "emscripten_output",
    deps = [":cxx_library"],
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./emscripten_output.js')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":emscripten_output"],
    timeout = "short",
)