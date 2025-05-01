load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "meson")

cc_binary(
    name = "c_binary",
    srcs = ["src/main.c"],
    deps = [":c_static_library"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE"],
)

filegroup(
    name = "c_static_library_srcs",
    srcs = [
        "meson.build",
        "src/test.c",
        "src/test.h"
    ],
)

# TODO Add support for generating the cross file to rules_foreign_cc
filegroup(
    name = "meson_cross_file",
    srcs = ["meson_cross_file.txt"]
)

meson(
    name = "c_static_library",
    lib_source = ":c_static_library_srcs",
    install = True,
    build_data = [
        ":meson_cross_file",
    ],
    env = {
        "LDFLAGS": "-sSTRICT",
    },
    setup_args = [
        "--cross-file=$(execpath :meson_cross_file)"
    ],
    out_static_libs = [
        "libc_static_library_out.a",
    ]
)

js_test(
    name = "validate",
    entry_point = "c_binary",
    data = [":c_binary"],
    timeout = "short",
)
