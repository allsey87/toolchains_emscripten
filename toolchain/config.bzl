"bazel-contrib/toolchains_emscripten/toolchain"

load(
    "@rules_cc//cc:action_names.bzl",
    "ACTION_NAME_GROUPS",
    "ACTION_NAMES"
)
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "action_config",
    "artifact_name_pattern",
    "env_entry",
    "env_set",
    "tool",
    "feature",
    "flag_group",
    "flag_set",
    "variable_with_value"
)
load("//toolchain:emscripten_cache.bzl", "EmscriptenCacheInfo")

def _impl(ctx):
    emcc = tool(tool = ctx.executable.emcc)
    emxx = tool(tool = ctx.executable.emxx)
    emar = tool(tool = ctx.executable.emar)

    action_configs = [
        action_config(
            action_name = ACTION_NAMES.c_compile,
            tools = [emcc],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_compile,
            tools = [emxx],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_static_library,
            tools = [emar],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_dynamic_library,
            tools = [emxx],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_nodeps_dynamic_library,
            tools = [emxx],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_module_codegen,
            tools = [emxx],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_module_compile,
            tools = [emxx],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_executable,
            tools = [emxx],
        ),
    ]

    toolchain_root = ctx.attr.llvm.label.workspace_root + "/install"

    env_entries_emscripten = [
        env_entry(
            key = "BZL_BINARYEN_ROOT",
            value = toolchain_root,
        ),
        env_entry(
            key = "BZL_LLVM_ROOT",
            value = toolchain_root + "/bin",
        ),
        env_entry(
            key = "BZL_EMSCRIPTEN_ROOT",
            value = toolchain_root + "/emscripten",
        ),
        env_entry(
            key = "BZL_CACHE",
            value = ctx.files.cache[0].dirname,
        ),
        env_entry(
            key = "BZL_NODE_JS",
            value = ctx.executable.node.path,
        ),
    ]

    archiver_flags_feature = feature(
        name = "archiver_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        flags = ["rcs", "%{output_execpath}"],
                        expand_if_available = "output_execpath",
                    ),
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.object_files}"],
                                iterate_over = "libraries_to_link.object_files",
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                        ],
                        expand_if_available = "libraries_to_link",
                    ),
                ],
            ),
        ],
    )

    # TODO I can directly set these on the action configs which would be much cleaner
    default_feature = feature(
        name = "default",
        enabled = True,
        env_sets = [
            env_set(
                actions = \
                    ACTION_NAME_GROUPS.all_cc_compile_actions + \
                    ACTION_NAME_GROUPS.all_cc_link_actions + \
                    [ACTION_NAMES.cpp_link_static_library],
                env_entries = env_entries_emscripten,
            )
        ],
        flag_sets = [
            flag_set(
                actions = ACTION_NAME_GROUPS.all_cc_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-nobuiltininc",
                        ]
                    )
                ]
            ),
            flag_set(
                actions = [ACTION_NAMES.c_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-isystem",
                            toolchain_root + "/lib/clang/19/include",
                       ]
                    )
                ]
            ),
        ],
    )

    dbg_feature = feature(name = "dbg")
    opt_feature = feature(name = "opt")

    # Override Bazel's built-in shared_flag feature to prevent -shared from being added
    shared_flag_feature = feature(
        name = "shared_flag",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = []  # Empty flag_groups - prevents -shared
            )
        ]
    )

    features = [
        dbg_feature,
        opt_feature,
        default_feature,
        archiver_flags_feature,
        shared_flag_feature,
    ]

    artifact_name_patterns = [
        artifact_name_pattern(
            category_name = "executable",
            prefix = None,
            extension = None,
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
        builtin_sysroot = toolchain_root + "/emscripten/cache/sysroot",
        toolchain_identifier = "wasm32-emscripten",
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
    attrs = {
        "emcc": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
        "emxx": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
        "emar": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
        "llvm": attr.label(mandatory = True, cfg = "exec"),
        "cache": attr.label(mandatory = True, cfg = "exec", providers = [EmscriptenCacheInfo]),
        "node": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
    },
    provides = [CcToolchainConfigInfo],
)
