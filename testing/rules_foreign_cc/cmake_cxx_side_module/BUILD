load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cc_binary(
    name = "cxx_main_module",
    srcs = ["src/main.cxx"],
    linkopts = ["-fwasm-exceptions", "-sSTRICT", "-sSINGLE_FILE", "-sMAIN_MODULE=1"],
    copts = ["-fwasm-exceptions", "-fPIC"],
)

filegroup(
    name = "cxx_side_module_srcs",
    srcs = [
        "CMakeLists.txt",
        "src/test.cxx"
    ],
)

cmake(
    name = "cxx_side_module",
    lib_source = ":cxx_side_module_srcs",
    install = True,
    generate_crosstool_file = True,
    cache_entries = {
        "CMAKE_CXX_FLAGS": "-fwasm-exceptions -fPIC",
        "CMAKE_MODULE_LINKER_FLAGS": "-fwasm-exceptions -sSTRICT -sSIDE_MODULE=1",
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
