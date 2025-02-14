load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

filegroup(
    name = "test_srcs",
    srcs = glob(["src/**"]),
)

cmake(
    name = "test_binary",
    lib_source = ":test_srcs",
    install = True,
    generate_crosstool_file = True, # False?
    out_binaries = [
        "test.wasm"
    ]
)
