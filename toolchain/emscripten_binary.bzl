load("@rules_cc//cc:defs.bzl", "cc_common", "CcInfo")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")

def _emscripten_binary_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    link_environment = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_link_executable,
        variables = cc_common.create_link_variables(
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
        )
    )

    linker = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_link_executable,
    )

    static_libraries = []
    for dep in ctx.attr.deps:
        dep_inputs = dep[CcInfo].linking_context.linker_inputs.to_list()
        for input in dep_inputs:
            # https://github.com/bazelbuild/bazel/issues/8118
            if hasattr(input.libraries, "to_list"):
                libraries = input.libraries.to_list()
            else:
                libraries = input.libraries
            for library in libraries:
                if library.static_library:
                    static_libraries.append(library.static_library)
    
    arguments = ctx.actions.args()
    arguments.add_all(static_libraries)
    
    output_wasm = ctx.actions.declare_file(ctx.label.name + ".wasm")
    outputs = [output_wasm]

    if ctx.attr.standalone_wasm:
        arguments.add("-o", output_wasm)
    else:
        output_js = ctx.actions.declare_file(ctx.label.name + ".js")
        outputs.append(output_js)
        arguments.add("-o", output_js)

    # append all linkopts
    arguments.add_all(ctx.attr.linkopts)
    
    ctx.actions.run(
        executable = linker,
        inputs = static_libraries,
        arguments = [arguments],
        outputs = outputs,
        tools = cc_toolchain.all_files.to_list(),
        env = link_environment,
    )
    
    return DefaultInfo(files = depset(outputs))

emscripten_binary = rule(
    implementation = _emscripten_binary_impl,
    attrs = {
        "deps": attr.label_list(cfg = "target", providers = [CcInfo]),
        "linkopts": attr.string_list(),
        "standalone_wasm": attr.bool()
    },
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"]
)
