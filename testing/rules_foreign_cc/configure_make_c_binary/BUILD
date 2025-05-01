load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

filegroup(
    name = "c_binary_srcs",
    srcs = [
        "configure.ac",
        "Makefile.am",
        "src/test.c"
    ],
)

configure_make(
    name = "c_binary",
    lib_source = ":c_binary_srcs",
    autoreconf = True,
    autoreconf_options = ["-fiv"],
    configure_in_place = True,
    configure_xcompile = True,
    env = {
        "LDFLAGS": "-sSTRICT -sSINGLE_FILE",
    },
    out_binaries = [
        "c_binary_out"
    ]
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./c_binary/bin/c_binary_out')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":c_binary"],
    timeout = "short",
)