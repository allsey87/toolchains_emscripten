load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "cxx_binary",
    srcs = ["src/test.cxx"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE"],
)

js_test(
    name = "validate",
    entry_point = "cxx_binary",
    data = [":cxx_binary"],
    timeout = "short",
)