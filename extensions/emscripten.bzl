load(":revisions.bzl", "EMSCRIPTEN_TAGS")

EMSCRIPTEN_URL = "https://storage.googleapis.com/webassembly/emscripten-releases-builds/{}/{}/wasm-binaries{}.{}"

# This configuration file converts the relative paths from the BZL_VARIABLE environment variables
# into absolute paths, which are often needed for Emscripten to work properly. These absolute paths
# are written back into the environment variables to prevent issues with subprocesses re-running
# this script where the current working directory no longer lines up with the definitions of the
# BZL_VARIABLE environment variables.
EMSCRIPTEN_CONFIG = """
import os
FROZEN_CACHE = True
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

def _emscripten_repository_impl(repository_ctx):
    revision = EMSCRIPTEN_TAGS[repository_ctx.attr.version]
    # TODO support and test other OSes
    # TODO support and test sha256 for other OSes
    #path = EMSCRIPTEN_URL.format("linux", revision.hash, "", "tar.xz")
    #repository_ctx.download_and_extract(path, sha256=revision.sha_linux)
    # TODO hack to speed up local development
    #repository_ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries-hack.tar.xz", sha256="8c3f19c7a154f04bcdc744ba1b4264bd17f106512018ec629220ba5c18cec488")
    repository_ctx.download_and_extract("http://127.0.0.1:8000/wasm-binaries.tar.xz", sha256="4f3bc91cffec9096c3d3ccb11c222e1c2cb7734a0ff9a92d192e171849e68f28")

    # Create the Emscripten config file
    repository_ctx.file(
        "install/emscripten/.emscripten",
        EMSCRIPTEN_CONFIG
    )
    
    # Create the BUILD.bazel file for the repository
    repository_ctx.template("BUILD.bazel", Label("toolchain.tpl"), substitutions = {
        "@@INSTALL_DIR@@": str(repository_ctx.path('install'))
    })

    # How can I pass embuilder_invocations to the toolchain? I think the answer here is to generate
    # a bunch of genrules and a filegroup that pulls them all together, passing them into compiler
    # files


    # Build and cache the requested ports and libraries
    # for invocation in repository_ctx.attr.embuilder_invocations:
    #     repository_ctx.execute(
    #         "",
    #         quiet=True,
    #         #working_directory = 
    #         # the config file above is only valid once the toolchain is set up
    #         # hence we override most variables here
    #         environment = {
    #             "EM_CACHE": repository_ctx.path("install/emscripten/cache"),
    #             "EM_EMSCRIPTEN_ROOT": repository_ctx.path("install/emscripten"),
    #             "EM_LLVM_ROOT": repository_ctx.path("install/bin"),
    #             "EM_BINARYEN_ROOT": repository_ctx.path("install"),
    #             # Disable checking Node.js version etc
    #             "EM_IGNORE_SANITY": "1",
    #             "EM_FROZEN_CACHE": "0",
    #             "EM_NODE_JS": "/bin/false",
    #         }
    #     )

# BINARYEN_ROOT = '{install_dir}'
# LLVM_ROOT = '{install_dir}' + '/bin'
# EMSCRIPTEN_ROOT = '{install_dir}' + '/emscripten'
# CACHE = '{install_dir}' + '/emscripten/cache'

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
            fail("Exactly one toolchain for Emscripten must be specified")
        version = module.tags.toolchain[0].version
        repository_name = "emscripten_" + version.replace(".", "_")

        # [expression for item in list if condition == True]
        embuilder_invocations = []
        for cache in module.tags.cache:
            embuilder_arguments = ["BUILD"]
            if cache.lto:
                embuilder_arguments.append("--lto")
            if cache.pic:
                embuilder_arguments.append("--pic")
            if cache.wasm64:
                embuilder_arguments.append("--wasm64")
            embuilder_arguments.extend(cache.targets)
            embuilder_invocations.append(" ".join(embuilder_arguments))

        emscripten_repository(
            name = repository_name,
            version = version,
            embuilder_invocations = embuilder_invocations,
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
            mandatory = False,
            doc = "Build with link-time optimization",
        ),
        "pic": attr.bool(
            default = False,
            mandatory = False,
            doc = "Build position independent code",
        ),
        "wasm64": attr.bool(
            default = False,
            mandatory = False,
            doc = "Build for wasm64-unknown-emscripten",
        ),
        "targets": attr.string_list(
            default = ["ALL"],
            doc = "The targets to be built (defaults to ALL)",
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