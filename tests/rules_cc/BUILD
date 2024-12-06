load("@rules_cc//cc:defs.bzl", "cc_binary")

load("@emscripten_3_1_73//:xyz.bzl", "test")
test()

cc_binary(
    name = "hello-world",
    srcs = ["hello-world.cc"],
)

# load("//emscripten_toolchain:wasm_rules.bzl", "wasm_cc_binary")
# wasm_cc_binary(
#     name = "hello-world-wasm",
#     cc_target = ":hello-world",
# )
