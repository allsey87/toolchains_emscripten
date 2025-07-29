load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "meson")

cc_binary(
    name = "c_main_module",
    srcs = ["src/main.c"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE", "-sMAIN_MODULE=1", "-lstubs"],
    copts = ["-fPIC"],
)

filegroup(
    name = "c_side_module_srcs",
    srcs = [
        "meson.build",
        "src/test.c"
    ],
)

# TODO Add support for generating the cross file to rules_foreign_cc
filegroup(
    name = "meson_cross_file",
    srcs = ["meson_cross_file.txt"]
)

meson(
    name = "c_side_module",
    lib_source = ":c_side_module_srcs",
    install = True,
    build_data = [
        ":meson_cross_file",
    ],
    env = {
        "CFLAGS": "-fPIC",
        "LDFLAGS": "-sSTRICT -sSIDE_MODULE=1",
    },
    setup_args = [
        "--cross-file=$(execpath :meson_cross_file)"
    ],
    out_shared_libs = [
        "libc_side_module_out.so",
    ]
)

js_test(
    name = "validate",
    entry_point = "c_main_module",
    data = [":c_main_module", ":c_side_module"],
    timeout = "short",
)
