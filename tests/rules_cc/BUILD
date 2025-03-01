load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "test_binary",
    srcs = ["src/test.cc"],
    linkopts = ["-sSTRICT", "-sMAIN_MODULE", "-sSINGLE_FILE"],
    copts = ["-fPIC"]
)

js_test(
    name = "validate",
    entry_point = "test_binary",
    data = [":test_binary"],
    timeout="short",
)