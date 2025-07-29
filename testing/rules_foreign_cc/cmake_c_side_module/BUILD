load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cc_binary(
    name = "c_main_module",
    srcs = ["src/main.c"],
    linkopts = ["-sSTRICT", "-sSINGLE_FILE", "-sMAIN_MODULE=1", "-lstubs"],
    copts = ["-fPIC"],
)

filegroup(
    name = "c_side_module_srcs",
    srcs = [
        "CMakeLists.txt",
        "src/test.c"
    ],
)

cmake(
    name = "c_side_module",
    lib_source = ":c_side_module_srcs",
    install = True,
    generate_crosstool_file = True,
    cache_entries = {
        "CMAKE_C_FLAGS": "-fPIC",
        "CMAKE_MODULE_LINKER_FLAGS": "-sSTRICT -sSIDE_MODULE=1",
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
