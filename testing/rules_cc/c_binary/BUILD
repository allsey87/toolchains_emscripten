load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "c_binary",
    srcs = ["src/test.c"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE"],
)

js_test(
    name = "validate",
    entry_point = "c_binary",
    data = [":c_binary"],
    timeout = "short",
)