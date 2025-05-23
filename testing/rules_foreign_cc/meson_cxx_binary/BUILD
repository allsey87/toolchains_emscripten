load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "meson")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

filegroup(
    name = "cxx_binary_srcs",
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

# NOTE Meson currently ignores `artifact_name_pattern`. Some effort on the meson
# side was made https://github.com/mesonbuild/meson/pull/5518 here. If this
# were merged we could configure extensions properly via the cross file
meson(
    name = "cxx_binary",
    lib_source = ":cxx_binary_srcs",
    install = True,
    build_data = [
        ":meson_cross_file",
    ],
    env = {
        "LDFLAGS": "-sSTRICT -sSINGLE_FILE",
    },
    setup_args = [
        "--cross-file=$(execpath :meson_cross_file)"
    ],
    out_binaries = [
        "cxx_binary_out.js",
    ]
)

write_file(
    name = "wrapper",
    out = "wrapper.js",
    content = [
        "require('./cxx_binary/bin/cxx_binary_out.js')"
    ]
)

js_test(
    name = "validate",
    entry_point = "wrapper.js",
    data = [":cxx_binary"],
    timeout = "short",
)