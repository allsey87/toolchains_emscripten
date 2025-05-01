load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

cc_binary(
    name = "c_binary",
    srcs = ["src/main.c"],
    deps = [":c_static_library"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE"],
)

filegroup(
    name = "c_static_library_srcs",
    srcs = [
        "configure.ac",
        "Makefile.am",
        "src/test.c",
        "src/test.h"
    ],
)

configure_make(
    name = "c_static_library",
    lib_source = ":c_static_library_srcs",
    autoreconf = True,
    autoreconf_options = ["-i"],
    configure_in_place = True,
    configure_xcompile = True,
    env = {
        "LDFLAGS": "-sSTRICT",
    },
    out_static_libs = [
        "libc_static_library_out.a",
    ],
)

js_test(
    name = "validate",
    entry_point = "c_binary",
    data = [":c_binary"],
    timeout = "short",
)
