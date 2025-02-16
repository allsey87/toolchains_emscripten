load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "test_binary",
    srcs = ["src/test.cc"],
    # both of these work
    # TODO move cache generate into a seperate test
    linkopts = ["-sSTRICT", "-sMAIN_MODULE"],
    copts = ["-fPIC"]
)

# https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_test

js_test(
    name = "validate",
    entry_point = "main.js",
    data = [
        ":test_binary"
    ],
)