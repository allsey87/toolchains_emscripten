load(":revisions.bzl", "EMSCRIPTEN_TAGS")

EMSCRIPTEN_URL = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"

# This configuration file converts the relative paths from the BZL_VARIABLE environment variables
# into absolute paths, which are often needed for Emscripten to work properly. These absolute paths
# are written back into the environment variables to prevent issues with subprocesses re-running
# this script where the current working directory no longer lines up with the definitions of the
# BZL_VARIABLE environment variables.

# Checking EXT_BUILD_ROOT is for rules_foreign_cc which does not execute the compiler in the Bazel
# build root. Unfortunately this environment variable is not available when using rules_cc. This
# is getting quite hacky so it would be good to find a more robust solution to this problem.

# TODO how does rules_foreign_cc set EXT_BUILD_ROOT, is this something I can do and configure my
# toolchain to also set? I would have to use a slightly different variable name as to not
# conflict with rules_foreign_cc
# EMSCRIPTEN_CONFIG = """
# import sys
# import os

# sys.stderr.write("!! BZL_BINARYEN_ROOT = {}\\n".format(os.environ['BZL_BINARYEN_ROOT']))
# sys.stderr.write("!! BZL_LLVM_ROOT = {}\\n".format(os.environ['BZL_LLVM_ROOT']))
# sys.stderr.write("!! BZL_EMSCRIPTEN_ROOT = {}\\n".format(os.environ['BZL_EMSCRIPTEN_ROOT']))
# sys.stderr.write("!! BZL_CACHE = {}\\n".format(os.environ['BZL_CACHE']))
# sys.stderr.write("!! BZL_NODE_JS = {}\\n".format(os.environ['BZL_NODE_JS']))

# FROZEN_CACHE = True
# if os.environ.get('EXT_BUILD_ROOT'):
#     CACHE = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_CACHE'])
#     BINARYEN_ROOT = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_BINARYEN_ROOT'])
#     LLVM_ROOT = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_LLVM_ROOT'])
#     EMSCRIPTEN_ROOT = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_EMSCRIPTEN_ROOT'])
#     NODE_JS = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_NODE_JS'])
# else:
#     CACHE = os.path.abspath(os.environ['BZL_CACHE'])
#     BINARYEN_ROOT = os.path.abspath(os.environ['BZL_BINARYEN_ROOT'])
#     LLVM_ROOT = os.path.abspath(os.environ['BZL_LLVM_ROOT'])
#     EMSCRIPTEN_ROOT = os.path.abspath(os.environ['BZL_EMSCRIPTEN_ROOT'])
#     NODE_JS = os.path.abspath(os.environ['BZL_NODE_JS'])
#     os.environ.update(
#         BZL_CACHE = CACHE,
#         BZL_BINARYEN_ROOT = BINARYEN_ROOT,
#         BZL_LLVM_ROOT = LLVM_ROOT,
#         BZL_EMSCRIPTEN_ROOT = EMSCRIPTEN_ROOT,
#         BZL_NODE_JS = NODE_JS
#     )
# """

BUILD_HEADER_TEMPLATE = """
{load_statements}
embuilder_invocations = {{{invocations}}}
install_dir = "{install_dir}"
"""

def _emscripten_repository_impl(repository_ctx):  
    # revision = EMSCRIPTEN_TAGS[repository_ctx.attr.version]
    # TODO support and test other OSes
    # TODO support and test sha256 for other OSes
    #path = EMSCRIPTEN_URL.format("linux", revision.hash, "", "tar.xz")
    #repository_ctx.download_and_extract(path, sha256=revision.sha_linux)
    # TODO hack to speed up local development
    #repository_ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries-hack.tar.xz", sha256="7aff6b48b7da9a0cc68bc80395df1f3c82b49c40d6fc5af61892c8f9f492a7f7")
    repository_ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries.tar.xz", sha256="6c0a22dc52b3e0c30f1864d3d9794c142eb7590628c09b307e654d45ab8a7270")

    load_statements = []
    invocations = []
    for cache in repository_ctx.attr.caches:
        repo_name = cache.repo_name.replace("~", "_").replace("+", "_") + "_config"
        load_statement = "load('{cache}', {repo_name} = 'config')".format(
            cache = cache,
            repo_name = repo_name
        )
        load_statements.append(load_statement)
        invocations.append(repo_name)

    build_header = BUILD_HEADER_TEMPLATE.format(
        load_statements = "\n".join(load_statements),
        invocations = ", ".join(["'{}': {}".format(invocation, invocation) for invocation in invocations]),
        install_dir = str(repository_ctx.path('install'))
    )

    # Copy the script for generating the Emscripten configuration file
    repository_ctx.file("emscripten_config.py", repository_ctx.read(Label("emscripten_config.py")))
    #repository_ctx.file("install/emscripten/.emscripten", EMSCRIPTEN_CONFIG)
    
    # Create the BUILD.bazel file for the repository
    repository_ctx.file("BUILD.bazel", build_header + repository_ctx.read(Label("toolchain.BUILD.bazel")))

emscripten_repository = repository_rule(
    _emscripten_repository_impl,
    attrs = {
        "version": attr.string(),
        "caches": attr.label_list(),
    }
)

def _emscripten_impl(ctx):
    for module in ctx.modules:
        for toolchain in module.tags.toolchain:
            emscripten_repository(
                name = "emscripten_" + toolchain.version.replace(".", "_"),
                version = toolchain.version,
                caches = toolchain.caches,
            )
    
    return ctx.extension_metadata(reproducible = True)

_toolchain = tag_class(
    doc = "Tag class used to register Emscripten toolchains.",
    attrs = {
        "is_default": attr.bool(
            mandatory = False,
            doc = """\
Whether the toolchain is the default version
""",
        ),
        "version": attr.string(
            mandatory = True,
            doc = """\
The Emscripten version, in `major.minor.patch` format, e.g.
`3.1.73`), to create a toolchain for.
""",
        ),
        "caches": attr.label_list()
    },
)

emscripten = module_extension(
    doc = """Bzlmod extension that is used to register Emscripten toolchains.
""",
    implementation = _emscripten_impl,
    tag_classes = {
        "toolchain": _toolchain,
    },
    os_dependent=True,
    arch_dependent=True,
)