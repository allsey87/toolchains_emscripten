load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "hello-world",
    srcs = ["hello-world.cc"],
)

# bazel build --platforms=@toolchains_emscripten//platform:wasm32-emscripten //:hello-world