"bazel-contrib/toolchains_emscripten/toolchain"

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "artifact_name_pattern",
    "tool_path",
    "feature",
    "flag_group",
    "flag_set",
    "with_feature_set",
)

# these groupings of actions come from https://github.com/vvviktor/bazel-mingw-toolchain/
# but are identical to those in the existing Emscripten toolchain, except where noted below:
all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

# These rules are included in the bazel-mingw-toolchain but not in the Emscripten toolchain
lto_index_actions = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

# These rules are included in the Emscripten toolchain but not in the bazel-mingw-toolchain
# preprocessor_compile_actions = [
#     ACTION_NAMES.c_compile,
#     ACTION_NAMES.cpp_compile,
#     ACTION_NAMES.linkstamp_compile,
#     ACTION_NAMES.preprocess_assemble,
#     ACTION_NAMES.cpp_header_parsing,
#     ACTION_NAMES.cpp_module_compile,
#     ACTION_NAMES.clif_match,
# ]

def _impl(ctx):
    # this where things are going to get a little bit different since I need to download
    # my tools and set up py_binaries using them

    # I need to download the emscripten tools and have defined by py_binaries before I reach
    # here!
    print('at this point, here! I need my python binaries to set up')
    print("""
        these binaries could be passed via ctx.attr.emcc labels or hardcoded if this whole file is part of a template
        that is being generated
    """)
    

    MINGW_PATH = "" #ctx.var.get("MINGW_PATH")
    GCC_VERSION = "" #ctx.var.get("GCC_VERSION")
    
    tool_paths_dict = {
        "ar" : MINGW_PATH + "/bin/ar",
        "cpp" : MINGW_PATH + "/bin/cpp",
        "gcc" : MINGW_PATH + "/bin/g++",
        "gcov" : MINGW_PATH + "/bin/gcov",
        "ld" : MINGW_PATH + "/bin/ld",
        "nm" : MINGW_PATH + "/bin/nm",
        "objdump" : MINGW_PATH + "/bin/objdump",
        "strip" : MINGW_PATH + "/bin/strip",
    }

    tool_paths = [
        tool_path(name = name, path = path)
        for name, path in tool_paths_dict.items()
    ]

    cxx_builtin_include_directories = [
        # MINGW_PATH + "/include",
        # MINGW_PATH + "/lib/gcc/x86_64-w64-mingw32/" + GCC_VERSION + "/include-fixed",
        # MINGW_PATH + "/lib/gcc/x86_64-w64-mingw32/" + GCC_VERSION + "/include",
        # MINGW_PATH + "/lib/gcc/x86_64-w64-mingw32/" + GCC_VERSION + "/install-tools/include",
        # MINGW_PATH + "/x86_64-w64-mingw32/include",
    ]

    abi_version = "gcc-" + GCC_VERSION

    action_configs = []

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            # flag_set(
            #     actions = all_compile_actions,
            #     flag_groups = ([
            #         flag_group(
            #             flags = ctx.attr.compile_flags,
            #         ),
            #     ] if ctx.attr.compile_flags else []),
            # ),
            # flag_set(
            #     actions = all_compile_actions,
            #     flag_groups = ([
            #         flag_group(
            #             flags = ctx.attr.dbg_compile_flags,
            #         ),
            #     ] if ctx.attr.dbg_compile_flags else []),
            #     with_features = [with_feature_set(features = ["dbg"])],
            # ),
            # flag_set(
            #     actions = all_compile_actions,
            #     flag_groups = ([
            #         flag_group(
            #             flags = ctx.attr.opt_compile_flags,
            #         ),
            #     ] if ctx.attr.opt_compile_flags else []),
            #     with_features = [with_feature_set(features = ["opt"])],
            # ),
            # flag_set(
            #     actions = all_cpp_compile_actions + [ACTION_NAMES.lto_backend],
            #     flag_groups = ([
            #         flag_group(
            #             flags = ctx.attr.cxx_flags,
            #         ),
            #     ] if ctx.attr.cxx_flags else []),
            # ),
        ],
    )

    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            # flag_set(
            #     actions = all_link_actions + lto_index_actions,
            #     flag_groups = ([
            #         flag_group(
            #             flags = ctx.attr.link_flags,
            #         ),
            #     ] if ctx.attr.link_flags else []),
            # ),
            # flag_set(
            #     actions = all_link_actions + lto_index_actions,
            #     flag_groups = ([
            #         flag_group(
            #             flags = ctx.attr.opt_link_flags,
            #         ),
            #     ] if ctx.attr.opt_link_flags else []),
            #     with_features = [with_feature_set(features = ["opt"])],
            # ),
        ],
    )

    dbg_feature = feature(name = "dbg")

    opt_feature = feature(name = "opt")

    features = [
        default_compile_flags_feature,
        default_link_flags_feature,
        dbg_feature,
        opt_feature,
    ]

    artifact_name_patterns = [
        artifact_name_pattern(
            category_name = "executable",
            prefix = "",
            extension = ".wasm",
        ),
        artifact_name_pattern(
            category_name = "dynamic_library",
            prefix = "lib",
            extension = ".so",
        )
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        toolchain_identifier = "wasm32-emscripten",
        host_system_name = "i686-unknown-linux-gnu",
        target_system_name = "wasm32-unknown-emscripten",
        target_cpu = "wasm32",
        target_libc = "musl/js",
        compiler = "emscripten",
        abi_version = abi_version,
        abi_libc_version = "default",
        tool_paths = tool_paths,
        artifact_name_patterns = artifact_name_patterns,
    )

emscripten_toolchain_config = rule(
    implementation = _impl,
    # These attributes are available in the _impl function above under ctx. IMPORTANT:
    # NOTE: that when passing labels into this function, e.g.:
    # "emscripten_binaries": attr.label(mandatory = True, cfg = "exec"),
    # it is possible to set the exec configuration. This is important for transitioning
    # between host and exec configurations.
    # Here I can specify which arguments are mandatory, their types, and default values

    attrs = {
        "emcc": attr.label(executable = True, cfg = "exec")
        # "abi_libc_version": attr.string(mandatory = True),
        # "compile_flags": attr.string_list(),
        # "compiler": attr.string(mandatory = True),
        # "coverage_compile_flags": attr.string_list(),
        # "coverage_link_flags": attr.string_list(),
        # "cpu": attr.string(mandatory = True),
        # "cxx_flags": attr.string_list(),
        # "dbg_compile_flags": attr.string_list(),
        # "host_system_name": attr.string(mandatory = True),
        # "link_flags": attr.string_list(),
        # "link_libs": attr.string_list(),
        # "opt_compile_flags": attr.string_list(),
        # "opt_link_flags": attr.string_list(),
        # "supports_start_end_lib": attr.bool(),
        # "target_libc": attr.string(mandatory = True),
        # "target_system_name": attr.string(mandatory = True),
        # "toolchain_identifier": attr.string(mandatory = True),
        # "unfiltered_compile_flags": attr.string_list(),
    },
    provides = [CcToolchainConfigInfo],
)
