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
EMSCRIPTEN_CONFIG = """
import os
FROZEN_CACHE = True
if os.environ.get('EXT_BUILD_ROOT'):
    CACHE = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_CACHE'])
    BINARYEN_ROOT = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_BINARYEN_ROOT'])
    LLVM_ROOT = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_LLVM_ROOT'])
    EMSCRIPTEN_ROOT = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_EMSCRIPTEN_ROOT'])
    NODE_JS = os.path.join(os.environ['EXT_BUILD_ROOT'], os.environ['BZL_NODE_JS'])
else:
    CACHE = os.path.abspath(os.environ['BZL_CACHE'])
    BINARYEN_ROOT = os.path.abspath(os.environ['BZL_BINARYEN_ROOT'])
    LLVM_ROOT = os.path.abspath(os.environ['BZL_LLVM_ROOT'])
    EMSCRIPTEN_ROOT = os.path.abspath(os.environ['BZL_EMSCRIPTEN_ROOT'])
    NODE_JS = os.path.abspath(os.environ['BZL_NODE_JS'])
    os.environ.update(
        BZL_CACHE = CACHE,
        BZL_BINARYEN_ROOT = BINARYEN_ROOT,
        BZL_LLVM_ROOT = LLVM_ROOT,
        BZL_EMSCRIPTEN_ROOT = EMSCRIPTEN_ROOT,
        BZL_NODE_JS = NODE_JS
    )
"""

REPO_CONFIG_BZL = """
install_dir = "{install_dir}"
embuilder_invocations = [{invocations}]
"""

def _emscripten_repository_impl(repository_ctx):
    revision = EMSCRIPTEN_TAGS[repository_ctx.attr.version]
    # TODO support and test other OSes
    # TODO support and test sha256 for other OSes
    #path = EMSCRIPTEN_URL.format("linux", revision.hash, "", "tar.xz")
    #repository_ctx.download_and_extract(path, sha256=revision.sha_linux)
    # TODO hack to speed up local development
    #repository_ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries-hack.tar.xz", sha256="8c3f19c7a154f04bcdc744ba1b4264bd17f106512018ec629220ba5c18cec488")
    repository_ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries.tar.xz", sha256="7c2ea588a5b44dcff93e8b72de31db57aa6c13e6e5944b01c4cf5b43dae04dba")

    # Helper functions for embuilder configuration and outputs
    def cache_suffix(invocation):
        if invocation["wasm64"]:
            cache_suffix = "wasm64-emscripten/"
        else:
            cache_suffix = "wasm32-emscripten/"
        if invocation["lto_thin"]:
            cache_suffix += "thinlto-pic/" if invocation["pic"] else "thinlto/"
        elif invocation["lto"]:
            cache_suffix += "lto-pic/" if invocation["pic"] else "lto/"
        elif invocation["pic"]:
            cache_suffix += "pic/"
        return cache_suffix

    def arguments(invocation):
        arguments = []
        if invocation["wasm64"]:
            arguments.append("--wasm64")
        if invocation["lto_thin"]:
            arguments.append("--lto=thin")
        elif invocation["lto"]:
            arguments.append("--lto")
        if invocation["pic"]:
            arguments.append("--pic")
        return arguments

    def targets(invocation):
        return invocation["targets"]
    
    # Configure the repository build file
    invocations = []
    for invocation in repository_ctx.attr.embuilder_invocations:
        invocation = json.decode(invocation)
        invocation = "({argument_list}, {cache_suffix}, {target_list})".format(
            argument_list = "[\"{}\"]".format("\", \"".join(arguments(invocation))),
            cache_suffix = "\"{}\"".format(cache_suffix(invocation)),
            target_list = "[\"{}\"]".format("\", \"".join(targets(invocation)))
        )
        invocations.append(invocation)
    repository_ctx.file("repo_config.bzl", REPO_CONFIG_BZL
        .format(
            install_dir = str(repository_ctx.path('install')),
            invocations = ", ".join(invocations)
        )
    )

    # Create the Emscripten config file
    repository_ctx.file("install/emscripten/.emscripten", EMSCRIPTEN_CONFIG)
    
    # Create the BUILD.bazel file for the repository
    repository_ctx.file("BUILD.bazel", repository_ctx.read(Label("toolchain.BUILD.bazel")))

emscripten_repository = repository_rule(
    _emscripten_repository_impl,
    attrs = {
        "version": attr.string(),
        "embuilder_invocations": attr.string_list(),
    }
)

def _emscripten_impl(ctx):
    for module in ctx.modules:
        if len(module.tags.toolchain) != 1:
            # NOTE reasons for this limitation are that toolchain repo needs
            # have multiple cache invocations for different combinations of
            # LTO PIC etc
            fail("Exactly one toolchain for Emscripten must be specified")
        version = module.tags.toolchain[0].version
        emscripten_repository(
            name = "emscripten_" + version.replace(".", "_"),
            version = version,
            embuilder_invocations = [
                json.encode(cache) for cache in module.tags.cache
            ],
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
    },
)

_cache = tag_class(
    doc = "Tag class used to build and cache Emscripten dependencies.",
    attrs = {
        "lto": attr.bool(
            default = False,
            doc = "Build with link-time optimization",
        ),
        "lto_thin": attr.bool(
            default = False,
            doc = "Build with thin link-time optimization",
        ),
        "pic": attr.bool(
            default = False,
            doc = "Build position independent code",
        ),
        "wasm64": attr.bool(
            default = False,
            doc = "Build for wasm64-unknown-emscripten",
        ),
        "targets": attr.string_list(
            doc = "The targets to be built",
        ),
    },
)

emscripten = module_extension(
    doc = """Bzlmod extension that is used to register Emscripten toolchains.
""",
    implementation = _emscripten_impl,
    tag_classes = {
        "toolchain": _toolchain,
        "cache": _cache,
    },
    os_dependent=True,
    arch_dependent=True,
)