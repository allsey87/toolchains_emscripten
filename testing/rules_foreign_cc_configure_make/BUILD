load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

filegroup(
    name = "test_cxx_binary_srcs",
    srcs = glob(["src/**"]),
)

configure_make(
    name = "test_cxx_binary",
    lib_source = ":test_cxx_binary_srcs",
    autoreconf = True,
    autoreconf_options = ["-fiv"],
    configure_in_place = True,
    configure_xcompile = True,
    env = {
        "LDFLAGS": "-sSTRICT -sSINGLE_FILE",
    },
    out_binaries = [
        "test_cxx_binary_out"
    ]
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./test_cxx_binary/bin/test_cxx_binary_out')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":test_cxx_binary"],
    timeout = "short",
)