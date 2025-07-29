load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "meson")

cc_binary(
    name = "cxx_main_module",
    srcs = ["src/main.cxx"],
    linkopts = ["-fwasm-exceptions", "-sSTRICT", "-sSINGLE_FILE", "-sMAIN_MODULE=1", "-lstubs"],
    cxxopts = ["-fwasm-exceptions", "-fPIC"],
)

filegroup(
    name = "cxx_side_module_srcs",
    srcs = [
        "meson.build",
        "src/test.cxx"
    ],
)

# TODO Add support for generating the cross file to rules_foreign_cc
filegroup(
    name = "meson_cross_file",
    srcs = ["meson_cross_file.txt"]
)

meson(
    name = "cxx_side_module",
    lib_source = ":cxx_side_module_srcs",
    install = True,
    build_data = [
        ":meson_cross_file",
    ],
    env = {
        "CXXFLAGS": "-fwasm-exceptions -fPIC",
        "LDFLAGS": "-fwasm-exceptions -sSTRICT -sSIDE_MODULE=1",
    },
    setup_args = [
        "--cross-file=$(execpath :meson_cross_file)"
    ],
    out_shared_libs = [
        "libcxx_side_module_out.so",
    ]
)

js_test(
    name = "validate",
    entry_point = "cxx_main_module",
    data = [":cxx_main_module", ":cxx_side_module"],
    timeout = "short",
)
