load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

cc_binary(
    name = "cxx_main_module",
    srcs = ["src/main.cxx"],
    linkopts = ["-fwasm-exceptions", "-sSTRICT", "-sSINGLE_FILE", "-sMAIN_MODULE=1"],
    copts = ["-fwasm-exceptions", "-fPIC"],
)

filegroup(
    name = "cxx_side_module_srcs",
    srcs = [
        "configure.ac",
        "Makefile.am",
        "src/test.cxx"
    ],
)

configure_make(
    name = "cxx_side_module",
    lib_source = ":cxx_side_module_srcs",
    autoreconf = True,
    autoreconf_options = ["-i"],
    configure_in_place = True,
    configure_xcompile = True,
    env = {
        "CXXFLAGS": "-fwasm-exceptions -fPIC",
        "LDFLAGS": "-fwasm-exceptions -sSTRICT -sSIDE_MODULE",
    },
    out_shared_libs = [
        "libcxx_side_module_out.so",
    ],
)

js_test(
    name = "validate",
    entry_point = "cxx_main_module",
    data = [":cxx_main_module", ":cxx_side_module"],
    timeout = "short",
)
