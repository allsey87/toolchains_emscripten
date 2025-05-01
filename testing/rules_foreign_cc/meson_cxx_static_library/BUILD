load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "meson")

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
        "meson.build",
        "src/test.cxx",
        "src/test.h"
    ],
)

# TODO Add support for generating the cross file to rules_foreign_cc
filegroup(
    name = "meson_cross_file",
    srcs = ["meson_cross_file.txt"]
)

meson(
    name = "cxx_static_library",
    lib_source = ":cxx_static_library_srcs",
    install = True,
    build_data = [
        ":meson_cross_file",
    ],
    env = {
        "CXXFLAGS": "-fwasm-exceptions",
        "LDFLAGS": "-fwasm-exceptions -sSTRICT",
    },
    setup_args = [
        "--cross-file=$(execpath :meson_cross_file)"
    ],
    out_static_libs = [
        "libcxx_static_library_out.a",
    ]
)

js_test(
    name = "validate",
    entry_point = "cxx_binary",
    data = [":cxx_binary"],
    timeout = "short",
)
