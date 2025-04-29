load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

filegroup(
    name = "c_binary_srcs",
    srcs = [
        "CMakeLists.txt",
        "src/test.c"
    ],
)

cmake(
    name = "c_binary",
    lib_source = ":c_binary_srcs",
    install = True,
    generate_crosstool_file = True,
    cache_entries = {
        "CMAKE_EXE_LINKER_FLAGS": "-sSTRICT -sSINGLE_FILE",
    },
    out_binaries = [
        "c_binary_out",
    ],
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./c_binary/bin/c_binary_out')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":c_binary"],
    timeout = "short",
)