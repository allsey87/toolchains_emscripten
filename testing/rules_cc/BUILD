load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "test_binary",
    srcs = ["src/test.cc"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE"], #  "-sMAIN_MODULE",
    #copts = ["-fPIC"]
)

js_test(
    name = "validate",
    entry_point = "test_binary",
    data = [":test_binary"],
    timeout = "short",
)