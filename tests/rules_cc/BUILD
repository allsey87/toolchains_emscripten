load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "hello-world",
    srcs = ["hello-world.cc"],
    # both of these work
    linkopts = ["-sMAIN_MODULE"],
    copts = ["-fPIC"]
)

# bazel build --platforms=@toolchains_emscripten//platform:wasm32-emscripten //:hello-world