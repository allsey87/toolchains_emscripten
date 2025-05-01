load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

cc_binary(
    name = "c_main_module",
    srcs = ["src/main.c"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE", "-sMAIN_MODULE=1"],
    copts = ["-fPIC"],
)

filegroup(
    name = "c_side_module_srcs",
    srcs = [
        "configure.ac",
        "Makefile.am",
        "src/test.c"
    ],
)

configure_make(
    name = "c_side_module",
    lib_source = ":c_side_module_srcs",
    autoreconf = True,
    autoreconf_options = ["-i"],
    configure_in_place = True,
    configure_xcompile = True,
    env = {
        "CFLAGS": "-fPIC",
        "LDFLAGS": "-sSTRICT -sSIDE_MODULE",
    },
    out_shared_libs = [
        "libc_side_module_out.so",
    ],
)

js_test(
    name = "validate",
    entry_point = "c_main_module",
    data = [":c_main_module", ":c_side_module"],
    timeout = "short",
)
