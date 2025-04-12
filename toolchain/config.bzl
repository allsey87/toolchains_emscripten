"bazel-contrib/toolchains_emscripten/toolchain"

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "artifact_name_pattern",
    "env_entry",
    "env_set",
    "tool",
    "feature",
    "flag_group",
    "flag_set",
)

EmscriptenCacheInfo = provider(doc = "Location of the Emscripten cache", fields = ['path'])

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
    emxx = tool(tool = ctx.executable.emxx)
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
            value = ctx.files.cache[0].dirname,
            #value = ""
        ),
        env_entry(
            key = "BZL_NODE_JS",
            value = ctx.executable.node.path,
        ),
    ]

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
                actions = [ACTION_NAMES.c_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-nobuiltininc",
                        ]
                    )
                ]
            ),
            flag_set(
                actions = [ACTION_NAMES.cpp_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-nobuiltininc",
                        ]
                    )
                ]
            ),
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
        flag_sets = [],
    )

    dbg_feature = feature(name = "dbg")
    opt_feature = feature(name = "opt")

    features = [
        dbg_feature,
        opt_feature,
        default_compile_flags_feature,
        default_link_flags_feature,
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
   
    builtin_sysroot = ctx.files.cache[0].dirname + "/sysroot"
    
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        builtin_sysroot = builtin_sysroot,
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
    # These attributes are available in the _impl function above under ctx. IMPORTANT:
    # NOTE: that when passing labels into this function, e.g.:
    # "emscripten_binaries": attr.label(mandatory = True, cfg = "exec"),
    # it is possible to set the exec configuration. This is important for transitioning
    # between host and exec configurations.
    # Here I can specify which arguments are mandatory, their types, and default values

    attrs = {
        "emcc": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
        "emxx": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
        "assets": attr.label(mandatory = True, cfg = "exec"), # TODO is this cfg attribute necessary?
        "cache": attr.label(mandatory = True, cfg = "exec", providers = [EmscriptenCacheInfo]), # TODO is this cfg attribute necessary?
        "node": attr.label(mandatory = True, executable = True, allow_files = True, cfg = "exec"),
    },
    provides = [CcToolchainConfigInfo],
)

def _emscripten_combine_cache_impl(ctx):
    cache = []
    for prebuilt_asset in ctx.attr.prebuilt_cache.files.to_list():
        prebuilt_asset_link = ctx.actions.declare_file(prebuilt_asset.path)
        ctx.actions.symlink(output=prebuilt_asset_link, target_file=prebuilt_asset)
        cache.append(prebuilt_asset_link)
    # Note: for some reason, the prebuilt cache must be added to `cache` first. It is unclear why, but if this
    # is not the case, the cache is directory is wrong (debug with print in .emscripten_config)
    for generated_cache in ctx.attr.generated_caches:
        for generated_asset in generated_cache.files.to_list():
            generated_asset_link = ctx.actions.declare_file(generated_asset.path.removeprefix(generated_asset.root.path + "/"))
            ctx.actions.symlink(output=generated_asset_link, target_file=generated_asset)
            cache.append(generated_asset_link)
    return [
        DefaultInfo(files = depset(cache)),
        EmscriptenCacheInfo(path = ctx.genfiles_dir.path)
    ]

emscripten_combine_cache = rule(
    implementation = _emscripten_combine_cache_impl,
    attrs = {
        "prebuilt_cache": attr.label(mandatory = True, cfg = "exec"),
        "generated_caches": attr.label_list(cfg = "exec"),
    },
    provides = [DefaultInfo, EmscriptenCacheInfo],
)