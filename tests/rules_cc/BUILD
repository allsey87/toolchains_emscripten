load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "test_binary",
    srcs = ["src/test.cc"],
    # both of these work
    # TODO move cache generate into a seperate test
    linkopts = ["-sSTRICT", "-sMAIN_MODULE"],
    copts = ["-fPIC"]
)
