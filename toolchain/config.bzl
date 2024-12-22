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

    #emscripten_dir = ctx.attr.emscripten_binaries.label.workspace_root
    cxx_builtin_include_directories = [
        ctx.attr.install_dir + "/emscripten/cache/sysroot/include/",
        ctx.attr.install_dir + "/lib/clang/20/include"
    ]

    emcc = tool(tool = ctx.executable.emcc)
    action_configs = [
        action_config(
            action_name = ACTION_NAMES.cpp_compile,
            tools = [emcc],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_module_codegen,
            tools = [emcc]
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_module_compile,
            tools = [emcc],
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_executable,
            tools = [emcc]
            #tools = [emcc],
        )
    ]

    # print("ctx.executable.nodejs.path = {}".format(ctx.executable.nodejs.path))
    # print("ctx.executable.nodejs.root = {}".format(ctx.executable.nodejs.root.path))
    # print("ctx.executable.nodejs.dirname = {}".format(ctx.executable.nodejs.dirname))
    # print("ctx.executable.nodejs.short_path = {}".format(ctx.executable.nodejs.short_path))
    
    # TODO create a genrule that just writes the location of nodejs to a file?

    # print('ctx.attr.node.label.name = {}'.format(ctx.attr.node.label.name)) # bin/nodejs/bin/node
    # print('ctx.attr.node.label.package = {}'.format(ctx.attr.node.label.package)) #
    # print('ctx.attr.node.label.repo_name = {}'.format(ctx.attr.node.label.repo_name)) # rules_nodejs~~node~nodejs_linux_amd64
    # print('ctx.attr.node.label.workspace_name = {}'.format(ctx.attr.node.label.workspace_name)) # rules_nodejs~~node~nodejs_linux_amd64
    # print('ctx.attr.node.label.workspace_root = {}'.format(ctx.attr.node.label.workspace_root)) # external/rules_nodejs~~node~nodejs_linux_amd64

    # This could be a way to use Embuilder?
    # output = ctx.actions.declare_file("out.txt")
    # ctx.actions.run(
    #     outputs = [output],
    #     executable = ctx.executable.nodejs,
    #     arguments = ["aaaa"],
    # )

    # nodejs = ctx.actions.declare_file("xxxnodexxx")
    # ctx.actions.symlink(
    #     output = nodejs,
    #     target_file = ctx.executable.nodejs,
    #     is_executable= True,
    # )

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        env_sets = [
            env_set(
                actions = all_compile_actions + all_link_actions,
                env_entries = [
                    # Ideally this would just be set on the py_binary, however,
                    # due to the python_zip_file trick, the `env` attribute is lost
                    env_entry(
                        key = "EM_NODE_JS",
                        # Is there a cleaner way to do this? Perhaps using symlinks?
                        #value = "../../../../../" + ctx.executable.node.path,
                        value = ctx.executable.node.path,
                    ),
                ],
            )
        ],
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
        "install_dir": attr.string(mandatory = True),
        # these are needed for emscripten config
        #"llvm_root": attr.label(mandatory = True, providers = [DirectoryInfo]),
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
