load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

cc_binary(
    name = "cxx_binary",
    srcs = ["src/main.cxx"],
    deps = [":cxx_static_library"],
    linkopts = ["-fwasm-exceptions", "-sSTRICT", "-sSINGLE_FILE"],
    copts = ["-fwasm-exceptions"],
)

filegroup(
    name = "cxx_static_library_srcs",
    srcs = [
        "configure.ac",
        "Makefile.am",
        "src/test.cxx",
        "src/test.h"
    ],
)

configure_make(
    name = "cxx_static_library",
    lib_source = ":cxx_static_library_srcs",
    autoreconf = True,
    autoreconf_options = ["-i"],
    configure_in_place = True,
    configure_xcompile = True,
    env = {
        "CXXFLAGS": "-fwasm-exceptions",
        "LDFLAGS": "-fwasm-exceptions -sSTRICT",
    },
    out_static_libs = [
        "libcxx_static_library_out.a",
    ],
)

js_test(
    name = "validate",
    entry_point = "cxx_binary",
    data = [":cxx_binary"],
    timeout = "short",
)
