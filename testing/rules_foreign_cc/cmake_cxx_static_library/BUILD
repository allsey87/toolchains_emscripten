load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

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
        "CMakeLists.txt",
        "src/test.cxx",
        "src/test.h"
    ],
)

cmake(
    name = "cxx_static_library",
    lib_source = ":cxx_static_library_srcs",
    install = True,
    generate_crosstool_file = True,
    cache_entries = {
        "CMAKE_CXX_FLAGS": "-fwasm-exceptions",
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
