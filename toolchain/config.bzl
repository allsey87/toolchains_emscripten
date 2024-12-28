"bazel-contrib/toolchains_emscripten/toolchain"

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
#load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo")

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "artifact_name_pattern",
    "env_entry",
    "env_set",
    "tool_path",
    "tool",
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
# lto_index_actions = [
#     ACTION_NAMES.lto_index_for_executable,
#     ACTION_NAMES.lto_index_for_dynamic_library,
#     ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
# ]

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
    emcc = tool(tool = ctx.executable.emcc)
    action_configs = [
        action_config(
            action_name = ACTION_NAMES.cpp_compile,
            tools = [emcc],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_module_codegen,
            tools = [emcc],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_module_compile,
            tools = [emcc],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_executable,
            tools = [emcc],
            #tools = [emcc],
        )
    ]

    # This could be a way to use Embuilder?
    # output = ctx.actions.declare_file("out.txt")
    # ctx.actions.run(
    #     outputs = [output],
    #     executable = ctx.executable.nodejs,
    #     arguments = ["aaaa"],
    # )

    # Set various configuration paths and parameters for Emscripten. Paths are
    # relative but are converted to absolute paths via emcc_wrapper.py (generated)
    env_entries_emscripten = [
        env_entry(
            key = "BZL_BINARYEN_ROOT",
            value = ctx.attr.assets.label.workspace_root + "/install",
        ),
        env_entry(
            key = "BZL_LLVM_ROOT",
            value = ctx.attr.assets.label.workspace_root + "/install/bin",
        ),
        env_entry(
            key = "BZL_EMSCRIPTEN_ROOT",
            value = ctx.attr.assets.label.workspace_root + "/install/emscripten",
        ),
        env_entry(
            key = "BZL_CACHE",
            value = ctx.attr.assets.label.workspace_root + "/install/emscripten/cache",
        ),
        env_entry(
            key = "BZL_NODE_JS",
            value = ctx.executable.node.path,
        ),
    ]

    # default_preprocessor_flags_feature = feature(
    #     name = "default_preprocessor_flags",
    #     enabled = True,
    #     env_sets = [
    #         env_set(
    #             actions = all_compile_actions,
    #             env_entries = env_entries_emscripten,
    #         )
    #     ]
    # )

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        env_sets = [
            env_set(
                actions = all_compile_actions,
                env_entries = env_entries_emscripten,
            )
        ],
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-iwithsysroot{}".format("/include/c++/v1"),
                            "-iwithsysroot{}".format("/include/compat"),
                            "-iwithsysroot{}".format("/include")
                        ]
                    )
                ]
            )
        ],
    )

    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        env_sets = [
            env_set(
                actions = all_link_actions,
                env_entries = env_entries_emscripten,
            )
        ],
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

    sysroot_feature = feature(
        name = "sysroot",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    # TODO does this match one of the groups above?
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot=%{sysroot}"],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

    features = [
        dbg_feature,
        opt_feature,
        sysroot_feature,
        default_compile_flags_feature,
        default_link_flags_feature,
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

    builtin_sysroot = ctx.attr.assets.label.workspace_root + "/install/emscripten/cache/sysroot"

    # cxx_builtin_include_directories = [
    #     #ctx.attr.assets.label.workspace_root + "%sysroot%/include/",
    #     #ctx.attr.assets.label.workspace_root + "/install/lib/clang/20/include"
    # ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        builtin_sysroot = builtin_sysroot,
        #cxx_builtin_include_directories = cxx_builtin_include_directories,
        toolchain_identifier = "wasm32-emscripten",
        #host_system_name = "i686-unknown-linux-gnu",
        target_system_name = "wasm32-unknown-emscripten",
        target_cpu = "wasm32",
        target_libc = "musl/js",
        compiler = "emscripten",
        abi_version = "emscripten",
        abi_libc_version = "default",
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
        "emcc": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
        #"install_dir": attr.string(mandatory = True),
        # these are needed for emscripten config
        "assets": attr.label(mandatory = True, cfg = "exec"), # TODO is this cfg attribute necessary?
        # "node_modules": attr.label(mandatory = True, cfg = "exec"),
        # "llvm_root": attr.label(mandatory = True, cfg = "exec"),
        "node": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
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
