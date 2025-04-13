load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

filegroup(
    name = "test_cxx_srcs",
    srcs = glob(["src/**"]),
)

cmake(
    name = "test_cxx_binary",
    lib_source = ":test_cxx_srcs",
    install = True,
    generate_crosstool_file = True,
    cache_entries = {
        "CMAKE_EXE_LINKER_FLAGS": "-sSTRICT -sSINGLE_FILE",
    },
    out_binaries = [
        "test_cxx_binary"
    ],
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./test_cxx_binary/bin/test_cxx_binary')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":test_cxx_binary"],
    timeout = "short",
)